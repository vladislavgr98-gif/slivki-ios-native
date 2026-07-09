import Foundation

public struct CheckoutServerAddress: Identifiable, Codable, Equatable {
    public let id: String
    public var cityId: String?
    public var city: String
    public var street: String
    public var house: String
    public var apartment: String?
    public var entrance: String?
    public var floor: String?
    public var intercom: String?
    public var comment: String?
    public var isDefault: Bool

    public var formattedLine: String {
        SavedDeliveryAddress(
            city: city,
            street: street,
            house: house,
            line1: "",
            entrance: entrance,
            floor: floor,
            apartment: apartment,
            intercom: intercom,
            comment: comment
        ).formattedLine
    }
}

public struct CheckoutServerRecipient: Identifiable, Codable, Equatable {
    public let id: String
    public var name: String
    public var phone: String
    public var email: String?
    public var isSelected: Bool
}

public struct CheckoutIntervalOption: Codable, Equatable, Identifiable {
    public let label: String
    public let value: String

    public var id: String { value }
}

public struct CheckoutQuoteGroup: Codable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let itemsTotal: Decimal
    public let discountTotal: Decimal
    public let deliveryTotal: Decimal
    public let payableTotal: Decimal
    public let intervals: CheckoutQuoteIntervals
}

public struct CheckoutQuoteIntervals: Codable, Equatable {
    public let today: [CheckoutIntervalOption]
    public let tomorrow: [CheckoutIntervalOption]
}

public struct CheckoutQuote: Codable, Equatable {
    public let fulfillmentType: String
    public let itemsTotal: Decimal
    public let discountTotal: Decimal
    public let deliveryTotal: Decimal
    public let promoCode: String?
    public let payableTotal: Decimal
    public let groups: [CheckoutQuoteGroup]
    public let address: CheckoutServerAddress?
    public let paymentMethods: [PaymentMethodOption]
}

public struct CheckoutDeliverySelection: Codable, Equatable {
    public let groupId: String
    public let date: String
    public let interval: String

    public init(groupId: String, date: String, interval: String) {
        self.groupId = groupId
        self.date = date
        self.interval = interval
    }
}

public struct CheckoutQuoteRequest: Encodable, Equatable {
    public let items: [CheckoutQuoteItem]
    public let fulfillmentType: String
    public let addressId: String?
    public let cityId: String?
    public let promoCode: String?

    public init(
        items: [CheckoutQuoteItem],
        fulfillmentType: String,
        addressId: String? = nil,
        cityId: String? = nil,
        promoCode: String? = nil
    ) {
        self.items = items
        self.fulfillmentType = fulfillmentType
        self.addressId = addressId
        self.cityId = cityId
        self.promoCode = promoCode
    }
}

public struct CheckoutQuoteItem: Encodable, Equatable {
    public let productId: String
    public let quantity: Int

    public init(productId: String, quantity: Int) {
        self.productId = productId
        self.quantity = quantity
    }
}

public struct CheckoutQuoteResponse: Decodable, Equatable {
    public let quote: CheckoutQuote
}

public struct CheckoutAddressesResponse: Decodable, Equatable {
    public let items: [CheckoutServerAddress]
}

public struct CheckoutAddressResponse: Decodable, Equatable {
    public let address: CheckoutServerAddress
}

public struct CheckoutRecipientsResponse: Decodable, Equatable {
    public let items: [CheckoutServerRecipient]
}

public struct CheckoutRecipientResponse: Decodable, Equatable {
    public let recipient: CheckoutServerRecipient
}

public struct CheckoutAddressSaveRequest: Encodable, Equatable {
    public let id: String?
    public let cityId: String?
    public let city: String
    public let street: String
    public let house: String
    public let apartment: String?
    public let entrance: String?
    public let floor: String?
    public let intercom: String?
    public let comment: String?
    public let isDefault: Bool

    public init(
        id: String? = nil,
        cityId: String? = nil,
        city: String,
        street: String,
        house: String,
        apartment: String? = nil,
        entrance: String? = nil,
        floor: String? = nil,
        intercom: String? = nil,
        comment: String? = nil,
        isDefault: Bool = true
    ) {
        self.id = id
        self.cityId = cityId
        self.city = city
        self.street = street
        self.house = house
        self.apartment = apartment
        self.entrance = entrance
        self.floor = floor
        self.intercom = intercom
        self.comment = comment
        self.isDefault = isDefault
    }
}

public struct CheckoutRecipientSaveRequest: Encodable, Equatable {
    public let id: String?
    public let name: String
    public let phone: String
    public let email: String?
    public let isSelected: Bool

    public init(id: String? = nil, name: String, phone: String, email: String? = nil, isSelected: Bool = true) {
        self.id = id
        self.name = name
        self.phone = phone
        self.email = email
        self.isSelected = isSelected
    }
}

public struct CheckoutDeleteResponse: Decodable, Equatable {
    public let ok: Bool
}
