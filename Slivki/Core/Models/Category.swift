import Foundation

public struct Category: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let imageURL: URL?
    public let children: [Category]

    public init(id: String, title: String, imageURL: URL?, children: [Category] = []) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
        self.children = children
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case imageURL = "imageUrl"
        case children
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        children = try container.decodeIfPresent([Category].self, forKey: .children) ?? []
    }
}
