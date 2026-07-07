import Foundation

public struct Cart: Codable, Equatable {
    public let id: String
    public let items: [CartItem]
    public let totals: CartTotals
    public let currency: String
    public let updatedAt: Date?

    public var total: Decimal {
        totals.payableTotal
    }

    public init(
        id: String = "local",
        items: [CartItem],
        totals: CartTotals,
        currency: String = "RUB",
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.items = items
        self.totals = totals
        self.currency = currency
        self.updatedAt = updatedAt
    }

    public init(items: [CartItem], total: Decimal) {
        self.init(items: items, totals: CartTotals(itemsTotal: total, discountTotal: 0, deliveryTotal: nil, payableTotal: total))
    }
}

public struct CartItem: Identifiable, Codable, Equatable, Hashable {
    public let id: String
    public let productID: String
    public let title: String
    public let price: Decimal
    public var quantity: Int
    public let selectedOptions: [CartItemOption]

    public var lineTotal: Decimal {
        price * Decimal(quantity)
    }

    public init(
        id: String,
        productID: String,
        title: String,
        price: Decimal,
        quantity: Int,
        selectedOptions: [CartItemOption]
    ) {
        self.id = id
        self.productID = productID
        self.title = title
        self.price = price
        self.quantity = quantity
        self.selectedOptions = selectedOptions
    }

    enum CodingKeys: String, CodingKey {
        case id
        case productID = "productId"
        case productIDSnake = "product_id"
        case title
        case price
        case quantity
        case selectedOptions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        productID = try container.decodeIfPresent(String.self, forKey: .productID)
            ?? container.decode(String.self, forKey: .productIDSnake)
        title = try container.decode(String.self, forKey: .title)
        price = try container.decode(Decimal.self, forKey: .price)
        quantity = try container.decode(Int.self, forKey: .quantity)
        selectedOptions = try container.decodeIfPresent([CartItemOption].self, forKey: .selectedOptions) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(productID, forKey: .productID)
        try container.encode(title, forKey: .title)
        try container.encode(price, forKey: .price)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(selectedOptions, forKey: .selectedOptions)
    }
}

public struct CartTotals: Codable, Equatable, Hashable {
    public let itemsTotal: Decimal
    public let discountTotal: Decimal
    public let deliveryTotal: Decimal?
    public let payableTotal: Decimal

    public init(itemsTotal: Decimal, discountTotal: Decimal, deliveryTotal: Decimal?, payableTotal: Decimal) {
        self.itemsTotal = itemsTotal
        self.discountTotal = discountTotal
        self.deliveryTotal = deliveryTotal
        self.payableTotal = payableTotal
    }
}

public struct CartItemOption: Identifiable, Codable, Equatable, Hashable {
    public let id: String
    public let title: String
    public let priceDelta: Decimal

    public init(id: String, title: String, priceDelta: Decimal) {
        self.id = id
        self.title = title
        self.priceDelta = priceDelta
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case priceDelta
    }
}
