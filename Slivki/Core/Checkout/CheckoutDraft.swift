import Foundation

public struct CheckoutDraft: Equatable {
    public var customerName: String
    public var phone: String
    public var city: String
    public var address: String

    public var trimmedCustomerName: String {
        customerName.trimmedForCheckout
    }

    public var normalizedPhone: String {
        phone.filter { $0.isNumber || $0 == "+" }
    }

    public var trimmedCity: String {
        city.trimmedForCheckout
    }

    public var trimmedAddress: String {
        address.trimmedForCheckout
    }

    public var validationErrors: [CheckoutValidationError] {
        var errors: [CheckoutValidationError] = []

        if trimmedCustomerName.isEmpty {
            errors.append(.customerNameRequired)
        }

        if normalizedPhone.isEmpty {
            errors.append(.phoneRequired)
        } else if normalizedPhone.filter(\.isNumber).count < 7 {
            errors.append(.phoneTooShort)
        }

        if trimmedCity.isEmpty {
            errors.append(.cityRequired)
        }

        if trimmedAddress.isEmpty {
            errors.append(.addressRequired)
        }

        return errors
    }

    public var isValid: Bool {
        validationErrors.isEmpty
    }

    public init(
        customerName: String = "",
        phone: String = "",
        city: String = "",
        address: String = ""
    ) {
        self.customerName = customerName
        self.phone = phone
        self.city = city
        self.address = address
    }
}

public enum CheckoutValidationError: Equatable {
    case customerNameRequired
    case phoneRequired
    case phoneTooShort
    case cityRequired
    case addressRequired

    public var message: String {
        switch self {
        case .customerNameRequired:
            "Укажите имя"
        case .phoneRequired:
            "Укажите телефон"
        case .phoneTooShort:
            "Проверьте номер телефона"
        case .cityRequired:
            "Укажите город"
        case .addressRequired:
            "Укажите адрес доставки"
        }
    }
}

private extension String {
    var trimmedForCheckout: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
