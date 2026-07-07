import Foundation

public struct Category: Identifiable, Codable, Hashable {
    public let id: String
    public let parentID: String?
    public let title: String
    public let slug: String?
    public let url: URL?
    public let imageURL: URL?
    public let children: [Category]

    public init(id: String, parentID: String? = nil, title: String, slug: String? = nil, url: URL? = nil, imageURL: URL?, children: [Category] = []) {
        self.id = id
        self.parentID = parentID
        self.title = title
        self.slug = slug
        self.url = url
        self.imageURL = imageURL
        self.children = children
    }

    enum CodingKeys: String, CodingKey {
        case id
        case parentID = "parentId"
        case title
        case slug
        case url
        case imageURL = "imageUrl"
        case primaryImage
        case children
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(FlexibleString.self, forKey: .id).value
        parentID = try container.decodeIfPresent(FlexibleString.self, forKey: .parentID)?.value
        title = try container.decode(String.self, forKey: .title)
        slug = try container.decodeIfPresent(String.self, forKey: .slug)
        url = try container.decodeIfPresent(URL.self, forKey: .url)
        let liveImageURL = try container.decodeIfPresent(URL.self, forKey: .primaryImage)
        imageURL = liveImageURL ?? (try container.decodeIfPresent(URL.self, forKey: .imageURL))
        children = try container.decodeIfPresent([Category].self, forKey: .children) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(parentID, forKey: .parentID)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(slug, forKey: .slug)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encode(children, forKey: .children)
    }
}
