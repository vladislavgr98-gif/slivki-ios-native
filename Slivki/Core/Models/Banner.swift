import Foundation

public struct Banner: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let imageURL: URL?
    public let target: BannerTarget?

    public var targetURL: URL? {
        guard target?.type == .url, let value = target?.value else {
            return nil
        }

        return URL(string: value)
    }

    public init(id: String, title: String, imageURL: URL?, targetURL: URL?) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
        self.target = targetURL.map { BannerTarget(type: .url, value: $0.absoluteString) }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case imageURL = "imageUrl"
        case target
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        target = try container.decodeIfPresent(BannerTarget.self, forKey: .target)
    }
}

public struct BannerTarget: Codable, Equatable, Hashable {
    public let type: BannerTargetType
    public let value: String?
}

public enum BannerTargetType: String, Codable, Equatable, Hashable {
    case product
    case category
    case url
    case none
}
