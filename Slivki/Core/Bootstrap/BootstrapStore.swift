import Combine
import Foundation

@MainActor
public final class BootstrapStore: ObservableObject {
    @Published public private(set) var state: LoadState<BootstrapResponse> = .idle
    @Published public private(set) var cityOverride: City?

    private var cachedResponse: BootstrapResponse?
    public private(set) var lastLoadError: Error?

    public var shouldRetryWithoutAuth: Bool {
        guard let error = lastLoadError as? APIError else {
            return false
        }

        switch error {
        case .httpStatus(let code):
            return code == 401 || code == 403
        case .server(let code, _):
            return code == "unauthorized" || code == "forbidden"
        case .decodingFailed:
            return true
        default:
            return false
        }
    }

    public var response: BootstrapResponse? {
        if case .loaded(let response) = state {
            return response
        }
        return cachedResponse
    }

    public var categories: [Category] {
        response?.categories ?? []
    }

    public var featuredProducts: [Product] {
        response?.featuredProducts.items ?? []
    }

    public var banners: [Banner] {
        response?.banners ?? []
    }

    public var selectedCity: City? {
        cityOverride ?? response?.selectedCity
    }

    public var cities: [City] {
        let loaded = response?.cities ?? []
        if loaded.isEmpty, let city = selectedCity {
            return [city]
        }
        return loaded
    }

    public var site: MobileSiteInfo? {
        response?.site
    }

    public var checkoutPaymentMethods: [PaymentMethodOption] {
        let methods = response?.checkout?.paymentMethods ?? PaymentMethodOption.defaults
        return methods.filter(\.isDeliveryPayment)
    }

    public var nativeCheckoutPaymentMethods: [PaymentMethodOption] {
        checkoutPaymentMethods
    }

    public init() {}

    @discardableResult
    public func load(using apiClient: APIClient, retries: Int = 2) async -> BootstrapResponse? {
        if cachedResponse == nil {
            state = .loading
        }

        var lastError: Error?

        for attempt in 0...max(retries, 0) {
            do {
                let response: BootstrapResponse = try await apiClient.get(.bootstrap)
                guard !Task.isCancelled else {
                    return cachedResponse
                }
                cachedResponse = response
                lastLoadError = nil
                state = .loaded(response)
                return response
            } catch is CancellationError {
                return cachedResponse
            } catch {
                lastError = error
                lastLoadError = error
                if attempt < retries {
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    continue
                }
            }
        }

        if let cachedResponse {
            state = .loaded(cachedResponse)
            return cachedResponse
        }

        _ = lastError
        state = .failed("Не удалось загрузить витрину. Проверьте связь и повторите.")
        return nil
    }

    public func category(id: String) -> Category? {
        categories.firstNested { $0.id == id }
    }

    public func selectCity(_ city: City) {
        cityOverride = city
    }

    public func category(matchingTitle keyword: String) -> Category? {
        let normalized = keyword.lowercased()
        return categories.first { category in
            category.title.lowercased().contains(normalized)
        }
    }
}

private extension Array where Element == Category {
    func firstNested(where matches: (Category) -> Bool) -> Category? {
        for category in self {
            if matches(category) {
                return category
            }
            if let child = category.children.firstNested(where: matches) {
                return child
            }
        }
        return nil
    }
}
