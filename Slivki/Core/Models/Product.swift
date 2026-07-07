import Foundation

public struct Product: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let slug: String?
    public let categoryID: String?
    public let imageURL: URL?
    public let price: Decimal
    public let hasPrice: Bool
    public let oldPrice: Decimal?
    public let currency: String
    public let unit: String
    public let isAvailable: Bool
    public let stockCount: Int?
    public let sellerTitle: String?
    public let badges: [String]
    public let description: String

    public var canBeAddedToCart: Bool {
        isAvailable && hasPrice
    }

    public init(
        id: String,
        title: String,
        slug: String? = nil,
        categoryID: String? = nil,
        imageURL: URL?,
        price: Decimal,
        hasPrice: Bool = true,
        oldPrice: Decimal? = nil,
        currency: String = "RUB",
        unit: String = "шт",
        isAvailable: Bool,
        stockCount: Int? = nil,
        sellerTitle: String? = nil,
        badges: [String] = [],
        description: String = ""
    ) {
        self.id = id
        self.title = title
        self.slug = slug
        self.categoryID = categoryID
        self.imageURL = imageURL
        self.price = price
        self.hasPrice = hasPrice
        self.oldPrice = oldPrice
        self.currency = currency
        self.unit = unit
        self.isAvailable = isAvailable
        self.stockCount = stockCount
        self.sellerTitle = sellerTitle
        self.badges = badges
        self.description = description
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case slug
        case categoryID = "categoryId"
        case category
        case imageURL = "imageUrl"
        case primaryImage
        case price
        case oldPrice
        case currency
        case unit
        case isAvailable
        case stock
        case stockCount
        case sellerTitle
        case badges
        case description
    }

    enum CategoryKeys: String, CodingKey {
        case id
    }

    enum PriceKeys: String, CodingKey {
        case current
        case old
        case currency
    }

    enum StockKeys: String, CodingKey {
        case count
        case available
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(FlexibleString.self, forKey: .id).value
        title = try container.decode(String.self, forKey: .title)
        slug = try container.decodeIfPresent(String.self, forKey: .slug)

        if let category = try? container.nestedContainer(keyedBy: CategoryKeys.self, forKey: .category) {
            categoryID = try category.decodeIfPresent(FlexibleString.self, forKey: .id)?.value
        } else {
            categoryID = try container.decodeIfPresent(FlexibleString.self, forKey: .categoryID)?.value
        }

        let liveImageURL = try container.decodeIfPresent(URL.self, forKey: .primaryImage)
        imageURL = liveImageURL ?? (try container.decodeIfPresent(URL.self, forKey: .imageURL))

        let decodedPrice: Decimal?
        if let priceContainer = try? container.nestedContainer(keyedBy: PriceKeys.self, forKey: .price) {
            decodedPrice = try priceContainer.decodeIfPresent(Decimal.self, forKey: .current)
            oldPrice = try priceContainer.decodeIfPresent(Decimal.self, forKey: .old)
            currency = try priceContainer.decodeIfPresent(String.self, forKey: .currency) ?? "RUB"
        } else {
            decodedPrice = try container.decodeIfPresent(Decimal.self, forKey: .price)
            oldPrice = try container.decodeIfPresent(Decimal.self, forKey: .oldPrice)
            currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? "RUB"
        }
        price = decodedPrice ?? .zero
        hasPrice = decodedPrice != nil

        unit = try container.decodeIfPresent(String.self, forKey: .unit) ?? "шт"

        if let stock = try? container.nestedContainer(keyedBy: StockKeys.self, forKey: .stock) {
            stockCount = try stock.decodeIfPresent(Int.self, forKey: .count)
            isAvailable = try stock.decodeIfPresent(Bool.self, forKey: .available) ?? false
        } else {
            stockCount = try container.decodeIfPresent(Int.self, forKey: .stockCount)
            isAvailable = try container.decodeIfPresent(Bool.self, forKey: .isAvailable) ?? false
        }

        sellerTitle = try container.decodeIfPresent(String.self, forKey: .sellerTitle)
        badges = try container.decodeIfPresent([String].self, forKey: .badges) ?? []
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(slug, forKey: .slug)
        try container.encodeIfPresent(categoryID, forKey: .categoryID)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        if hasPrice {
            try container.encode(price, forKey: .price)
        }
        try container.encodeIfPresent(oldPrice, forKey: .oldPrice)
        try container.encode(currency, forKey: .currency)
        try container.encode(unit, forKey: .unit)
        try container.encode(isAvailable, forKey: .isAvailable)
        try container.encodeIfPresent(stockCount, forKey: .stockCount)
        try container.encodeIfPresent(sellerTitle, forKey: .sellerTitle)
        try container.encode(badges, forKey: .badges)
        try container.encode(description, forKey: .description)
    }
}
