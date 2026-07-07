import Foundation

public struct APIEnvelope<Payload: Decodable>: Decodable {
    public let success: Bool
    public let meta: APIMeta?
    public let data: Payload?
    public let error: APIEnvelopeError?

    public var apiError: APIError? {
        error.map { APIError.server($0.code, $0.message) }
    }
}

public struct APIMeta: Decodable, Equatable {
    public let apiVersion: String?
    public let generatedAt: Date?
}

public struct APIEnvelopeError: Decodable, Equatable {
    public let code: String
    public let message: String
}

struct EmptyPayload: Decodable {}

public struct MobileSiteInfo: Codable, Equatable {
    public let name: String
    public let host: URL?
    public let phone: String?
    public let address: String?
    public let hours: String?
}

public struct MobileAppInfo: Codable, Equatable {
    public let iosBundleID: String?
    public let iosAppStoreID: String?
    public let iosMinimumVersion: String?
    public let currency: String?
    public let locale: String?

    enum CodingKeys: String, CodingKey {
        case iosBundleID = "iosBundleId"
        case iosAppStoreID = "iosAppStoreId"
        case iosMinimumVersion
        case currency
        case locale
    }
}

public struct BootstrapResponse: Decodable, Equatable {
    public let site: MobileSiteInfo?
    public let app: MobileAppInfo?
    public let cities: [City]
    public let selectedCity: City?
    public let categories: [Category]
    public let banners: [Banner]
    public let user: User?
    public let cart: Cart?
    public let featureFlags: [String: Bool]
    public let featuredProducts: ProductListResponse

    enum CodingKeys: String, CodingKey {
        case site
        case app
        case cities
        case selectedCity
        case categories
        case navigation
        case banners
        case user
        case cart
        case featureFlags
        case featuredProducts
    }

    enum NavigationKeys: String, CodingKey {
        case categories
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        site = try container.decodeIfPresent(MobileSiteInfo.self, forKey: .site)
        app = try container.decodeIfPresent(MobileAppInfo.self, forKey: .app)
        cities = try container.decodeIfPresent([City].self, forKey: .cities) ?? []
        selectedCity = try container.decodeIfPresent(City.self, forKey: .selectedCity)

        if let navigation = try? container.nestedContainer(keyedBy: NavigationKeys.self, forKey: .navigation) {
            categories = try navigation.decodeIfPresent([Category].self, forKey: .categories) ?? []
        } else {
            categories = try container.decodeIfPresent([Category].self, forKey: .categories) ?? []
        }

        banners = try container.decodeIfPresent([Banner].self, forKey: .banners) ?? []
        user = try container.decodeIfPresent(User.self, forKey: .user)
        cart = try container.decodeIfPresent(Cart.self, forKey: .cart)
        featureFlags = try container.decodeIfPresent([String: Bool].self, forKey: .featureFlags) ?? [:]
        featuredProducts = try container.decodeIfPresent(ProductListResponse.self, forKey: .featuredProducts) ?? ProductListResponse()
    }
}

public struct CatalogResponse: Decodable, Equatable {
    public let categories: [Category]
}

public struct ProductListResponse: Decodable, Equatable {
    public let items: [Product]
    public let pagination: Pagination

    public init(items: [Product] = [], pagination: Pagination = Pagination()) {
        self.items = items
        self.pagination = pagination
    }
}

public struct ProductDetailResponse: Decodable, Equatable {
    public let product: Product
}

public struct OrderListResponse: Decodable, Equatable {
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
    public let offset: Int
    public let limit: Int
    public let count: Int

    public var page: Int {
        limit > 0 ? (offset / limit) + 1 : 1
    }

    public var perPage: Int {
        limit
    }

    public var total: Int {
        count
    }

    enum CodingKeys: String, CodingKey {
        case offset
        case limit
        case count
        case page
        case perPage
        case total
    }

    public init(offset: Int = 0, limit: Int = 0, count: Int = 0) {
        self.offset = offset
        self.limit = limit
        self.count = count
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(offset, forKey: .offset)
        try container.encode(limit, forKey: .limit)
        try container.encode(count, forKey: .count)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let offset = try container.decodeIfPresent(Int.self, forKey: .offset),
           let limit = try container.decodeIfPresent(Int.self, forKey: .limit) {
            self.offset = offset
            self.limit = limit
            self.count = try container.decodeIfPresent(Int.self, forKey: .count) ?? 0
        } else {
            let page = try container.decodeIfPresent(Int.self, forKey: .page) ?? 1
            let perPage = try container.decodeIfPresent(Int.self, forKey: .perPage) ?? 20
            self.offset = max(page - 1, 0) * perPage
            self.limit = perPage
            self.count = try container.decodeIfPresent(Int.self, forKey: .total) ?? 0
        }
    }
}
