import Foundation

public enum APIEndpoint {
    case bootstrap
    case catalog
    case products(categoryID: String?, query: String?, sort: ProductSort, page: Int, perPage: Int, filters: ProductCatalogFilters = ProductCatalogFilters())
    case product(id: String)
    case cart
    case login
    case orders
    case order(id: String)
    case pushToken
    case checkoutQuote
    case checkoutAddresses
    case checkoutAddress(id: String)
    case checkoutAddressSelect(id: String)
    case checkoutRecipients
    case checkoutRecipient(id: String)
    case checkoutRecipientSelect(id: String)

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
        case .order(let id):
            return "/orders/\(id)"
        case .pushToken:
            return "/push-token"
        case .checkoutQuote:
            return "/checkout/quote"
        case .checkoutAddresses:
            return "/checkout/addresses"
        case .checkoutAddress(let id):
            return "/checkout/addresses/\(id)"
        case .checkoutAddressSelect(let id):
            return "/checkout/addresses/\(id)/select"
        case .checkoutRecipients:
            return "/checkout/recipients"
        case .checkoutRecipient(let id):
            return "/checkout/recipients/\(id)"
        case .checkoutRecipientSelect(let id):
            return "/checkout/recipients/\(id)/select"
        }
    }

    public var queryItems: [URLQueryItem] {
        switch self {
        case .products(let categoryID, let query, let sort, let page, let perPage, let filters):
            let safePage = max(page, 1)
            let safePerPage = min(max(perPage, 1), 100)
            let offset = (safePage - 1) * safePerPage

            return [
                categoryID.map { URLQueryItem(name: "category_id", value: $0) },
                query.map { URLQueryItem(name: "q", value: $0) },
                URLQueryItem(name: "sort", value: sort.rawValue),
                URLQueryItem(name: "offset", value: String(offset)),
                URLQueryItem(name: "limit", value: String(safePerPage)),
                filters.inStockOnly ? URLQueryItem(name: "in_stock", value: "1") : nil,
                filters.onSaleOnly ? URLQueryItem(name: "on_sale", value: "1") : nil
            ].compactMap { $0 }
        default:
            return []
        }
    }
}

import Foundation

public enum ProductSort: String, Codable, CaseIterable {
    case popular
    case new
    case priceAsc = "price_asc"
    case priceDesc = "price_desc"
    case sale
}
