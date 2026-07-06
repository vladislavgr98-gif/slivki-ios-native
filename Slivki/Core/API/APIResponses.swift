import Foundation

public struct BootstrapResponse: Codable, Equatable {
    public let cities: [City]
    public let selectedCity: City
    public let categories: [Category]
    public let banners: [Banner]
    public let user: User?
    public let cart: Cart
    public let featureFlags: [String: Bool]

    enum CodingKeys: String, CodingKey {
        case cities
        case selectedCity
        case categories
        case banners
        case user
        case cart
        case featureFlags
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cities = try container.decode([City].self, forKey: .cities)
        selectedCity = try container.decode(City.self, forKey: .selectedCity)
        categories = try container.decode([Category].self, forKey: .categories)
        banners = try container.decode([Banner].self, forKey: .banners)
        user = try container.decodeIfPresent(User.self, forKey: .user)
        cart = try container.decode(Cart.self, forKey: .cart)
        featureFlags = try container.decodeIfPresent([String: Bool].self, forKey: .featureFlags) ?? [:]
    }
}

public struct CatalogResponse: Codable, Equatable {
    public let categories: [Category]
}

public struct ProductListResponse: Codable, Equatable {
    public let items: [Product]
    public let pagination: Pagination
}

public struct OrderListResponse: Codable, Equatable {
    public let items: [Order]
    public let pagination: Pagination
}

public struct LoginRequest: Encodable, Equatable {
    public let phone: String
    public let code: String
}

public struct LoginResponse: Decodable, Equatable {
    public let accessToken: String
    public let refreshToken: String?
    public let tokenType: String
    public let expiresIn: Int?
    public let user: User
}

public struct PushTokenRequest: Encodable, Equatable {
    public let token: String
    public let platform: String
    public let environment: PushEnvironment
    public let deviceID: String?

    public init(token: String, environment: PushEnvironment, deviceID: String?) {
        self.token = token
        self.platform = "ios"
        self.environment = environment
        self.deviceID = deviceID
    }

    enum CodingKeys: String, CodingKey {
        case token
        case platform
        case environment
        case deviceID = "deviceId"
    }
}

public enum PushEnvironment: String, Codable, Equatable {
    case sandbox
    case production
}

public struct Pagination: Codable, Equatable, Hashable {
    public let page: Int
    public let perPage: Int
    public let total: Int
}
