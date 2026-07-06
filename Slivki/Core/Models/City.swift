import Foundation

public struct City: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let region: String?

    public init(id: String, title: String, region: String? = nil) {
        self.id = id
        self.title = title
        self.region = region
    }
}
