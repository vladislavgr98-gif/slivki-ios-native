import Foundation

public struct PaymentMethodOption: Codable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let supportsNativeCheckout: Bool

    public init(id: String, title: String, supportsNativeCheckout: Bool) {
        self.id = id
        self.title = title
        self.supportsNativeCheckout = supportsNativeCheckout
    }

    public static let deliveryOnlyIDs: Set<String> = ["cash", "card_on_delivery"]

    public var isDeliveryPayment: Bool {
        Self.deliveryOnlyIDs.contains(id)
    }

    public static let defaults: [PaymentMethodOption] = [
        PaymentMethodOption(id: "cash", title: "Наличными", supportsNativeCheckout: true),
        PaymentMethodOption(id: "card_on_delivery", title: "Картой/QR", supportsNativeCheckout: true)
    ]
}

public struct CheckoutOptions: Codable, Equatable {
    public let paymentMethods: [PaymentMethodOption]

    public init(paymentMethods: [PaymentMethodOption] = PaymentMethodOption.defaults) {
        self.paymentMethods = paymentMethods
    }
}
