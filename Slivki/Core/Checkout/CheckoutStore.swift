import Combine
import Foundation

@MainActor
public final class CheckoutStore: ObservableObject {
    @Published public private(set) var addresses: [CheckoutServerAddress] = []
    @Published public private(set) var recipients: [CheckoutServerRecipient] = []
    @Published public private(set) var quote: CheckoutQuote?
    @Published public private(set) var isLoadingQuote = false
    @Published public private(set) var quoteError: String?

    public var selectedAddress: CheckoutServerAddress? {
        addresses.first(where: \.isDefault) ?? addresses.first
    }

    public var selectedRecipient: CheckoutServerRecipient? {
        recipients.first(where: \.isSelected) ?? recipients.first
    }

    public init() {}

    public func reset() {
        addresses = []
        recipients = []
        quote = nil
        quoteError = nil
    }

    public func loadAddresses(using apiClient: APIClient) async {
        do {
            let response: CheckoutAddressesResponse = try await apiClient.get(.checkoutAddresses)
            addresses = response.items
        } catch {
            // Local checkout fields still work when server addresses are unavailable.
        }
    }

    public func loadRecipients(using apiClient: APIClient) async {
        do {
            let response: CheckoutRecipientsResponse = try await apiClient.get(.checkoutRecipients)
            recipients = response.items
        } catch {
            // Local recipient fields still work when server recipients are unavailable.
        }
    }

    public func saveAddress(_ request: CheckoutAddressSaveRequest, using apiClient: APIClient) async throws -> CheckoutServerAddress {
        let response: CheckoutAddressResponse = try await apiClient.post(.checkoutAddresses, body: request)
        if let index = addresses.firstIndex(where: { $0.id == response.address.id }) {
            addresses[index] = response.address
        } else {
            addresses.append(response.address)
        }
        if response.address.isDefault {
            addresses = addresses.map { item in
                var copy = item
                copy.isDefault = item.id == response.address.id
                return copy
            }
        }
        return response.address
    }

    public func saveRecipient(_ request: CheckoutRecipientSaveRequest, using apiClient: APIClient) async throws -> CheckoutServerRecipient {
        let response: CheckoutRecipientResponse = try await apiClient.post(.checkoutRecipients, body: request)
        if let index = recipients.firstIndex(where: { $0.id == response.recipient.id }) {
            recipients[index] = response.recipient
        } else {
            recipients.append(response.recipient)
        }
        if response.recipient.isSelected {
            recipients = recipients.map { item in
                var copy = item
                copy.isSelected = item.id == response.recipient.id
                return copy
            }
        }
        return response.recipient
    }

    public func clearQuote() {
        quote = nil
        quoteError = nil
    }

    public func refreshQuote(
        items: [CartItem],
        fulfillmentType: String,
        addressId: String?,
        cityId: String?,
        promoCode: String?,
        using apiClient: APIClient
    ) async {
        guard !items.isEmpty else {
            quote = nil
            return
        }

        isLoadingQuote = true
        quoteError = nil
        defer { isLoadingQuote = false }

        let request = CheckoutQuoteRequest(
            items: items.map { CheckoutQuoteItem(productId: $0.productID, quantity: $0.quantity) },
            fulfillmentType: fulfillmentType,
            addressId: addressId,
            cityId: cityId,
            promoCode: promoCode?.nilIfCheckoutEmpty
        )

        do {
            let response: CheckoutQuoteResponse = try await apiClient.post(.checkoutQuote, body: request)
            quote = response.quote
        } catch {
            quote = nil
            quoteError = "Не удалось рассчитать доставку."
        }
    }
}

private extension String {
    var nilIfCheckoutEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
