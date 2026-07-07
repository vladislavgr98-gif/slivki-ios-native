import Foundation

public enum APIEndpoint {
    case bootstrap
    case catalog
    case products(categoryID: String?, query: String?, sort: ProductSort, page: Int, perPage: Int)
    case product(id: String)
    case cart
    case login
    case orders
    case pushToken

    public var path: String {
        switch self {
        case .bootstrap:
            "/bootstrap"
        case .catalog:
            "/catalog"
        case .products:
            "/products"
        case .product(let id):
            "/products/\(id)"
        case .cart:
            "/cart"
        case .login:
            "/auth/login"
        case .orders:
            "/orders"
        case .pushToken:
            "/push-token"
        }
    }

    public var queryItems: [URLQueryItem] {
        switch self {
        case .products(let categoryID, let query, let sort, let page, let perPage):
            let safePage = max(page, 1)
            let safePerPage = min(max(perPage, 1), 100)
            let offset = (safePage - 1) * safePerPage

            [
                categoryID.map { URLQueryItem(name: "category_id", value: $0) },
                query.map { URLQueryItem(name: "q", value: $0) },
                URLQueryItem(name: "sort", value: sort.rawValue),
                URLQueryItem(name: "offset", value: String(offset)),
                URLQueryItem(name: "limit", value: String(safePerPage))
            ].compactMap { $0 }
        default:
            []
        }
    }
}

public enum ProductSort: String, Codable, CaseIterable {
    case popular
    case new
    case priceAsc = "price_asc"
    case priceDesc = "price_desc"
}
