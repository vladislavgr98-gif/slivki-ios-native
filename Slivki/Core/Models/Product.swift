import Foundation

public struct Product: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let categoryID: String?
    public let imageURL: URL?
    public let price: Decimal
    public let oldPrice: Decimal?
    public let unit: String
    public let isAvailable: Bool
    public let sellerTitle: String?

    public init(
        id: String,
        title: String,
        categoryID: String? = nil,
        imageURL: URL?,
        price: Decimal,
        oldPrice: Decimal? = nil,
        unit: String,
        isAvailable: Bool,
        sellerTitle: String? = nil
    ) {
        self.id = id
        self.title = title
        self.categoryID = categoryID
        self.imageURL = imageURL
        self.price = price
        self.oldPrice = oldPrice
        self.unit = unit
        self.isAvailable = isAvailable
        self.sellerTitle = sellerTitle
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case categoryID = "categoryId"
        case imageURL = "imageUrl"
        case price
        case oldPrice
        case unit
        case isAvailable
        case sellerTitle
    }
}
