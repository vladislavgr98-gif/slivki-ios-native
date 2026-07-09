import Foundation

public struct Order: Identifiable, Codable, Hashable {
    public let id: String
    public let number: String
    public let status: OrderStatus
    public let createdAt: Date
    public let totals: CartTotals
    public let items: [CartItem]
    public let deliveryAddress: Address?
    public let contactPhone: String?
    public let comment: String?
    public let paymentTitle: String?

    public var total: Decimal {
        totals.payableTotal
    }

    public init(
        id: String,
        number: String,
        status: OrderStatus,
        createdAt: Date,
        totals: CartTotals,
        items: [CartItem],
        deliveryAddress: Address? = nil,
        contactPhone: String? = nil,
        comment: String? = nil,
        paymentTitle: String? = nil
    ) {
        self.id = id
        self.number = number
        self.status = status
        self.createdAt = createdAt
        self.totals = totals
        self.items = items
        self.deliveryAddress = deliveryAddress
        self.contactPhone = contactPhone
        self.comment = comment
        self.paymentTitle = paymentTitle
    }

    enum CodingKeys: String, CodingKey {
        case id
        case number
        case status
        case createdAt
        case totals
        case items
        case deliveryAddress
        case contactPhone
        case comment
        case paymentTitle = "paymentName"
    }
}

public enum OrderStatus: String, Codable, Hashable {
    case new
    case confirmed
    case paid
    case assembling
    case shipped
    case completed
    case cancelled

    public var title: String {
        switch self {
        case .new:
            return "Новый"
        case .confirmed:
            return "Подтвержден"
        case .paid:
            return "Оплачен"
        case .assembling:
            return "Собирается"
        case .shipped:
            return "Доставляется"
        case .completed:
            return "Завершен"
        case .cancelled:
            return "Отменен"
        }
    }

    public var timelineSteps: [OrderStatus] {
        [.new, .confirmed, .assembling, .shipped, .completed]
    }

    public var timelineIndex: Int? {
        if self == .cancelled {
            return nil
        }
        return timelineSteps.firstIndex(of: self)
    }
}

public struct Address: Codable, Equatable, Hashable {
    public let cityID: String
    public let line1: String
    public let line2: String?
    public let entrance: String?
    public let floor: String?
    public let apartment: String?

    enum CodingKeys: String, CodingKey {
        case cityID = "cityId"
        case line1
        case line2
        case entrance
        case floor
        case apartment
    }
}
