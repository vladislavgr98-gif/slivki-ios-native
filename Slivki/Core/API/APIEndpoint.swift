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
            return "/bootstrap"
        case .catalog:
            return "/catalog"
        case .products:
            return "/products"
        case .product(let id):
            return "/products/\(id)"
        case .cart:
            return "/cart"
        case .login:
            return "/auth/login"
        case .orders:
            return "/orders"
        case .pushToken:
            return "/push-token"
        }
    }

    public var queryItems: [URLQueryItem] {
        switch self {
        case .products(let categoryID, let query, let sort, let page, let perPage):
            let safePage = max(page, 1)
            let safePerPage = min(max(perPage, 1), 100)
            let offset = (safePage - 1) * safePerPage

            return [
                categoryID.map { URLQueryItem(name: "category_id", value: $0) },
                query.map { URLQueryItem(name: "q", value: $0) },
                URLQueryItem(name: "sort", value: sort.rawValue),
                URLQueryItem(name: "offset", value: String(offset)),
                URLQueryItem(name: "limit", value: String(safePerPage))
            ].compactMap { $0 }
        default:
            return []
        }
    }
}

public enum ProductSort: String, Codable, CaseIterable {
    case popular
    case new
    case priceAsc = "price_asc"
    case priceDesc = "price_desc"
}
