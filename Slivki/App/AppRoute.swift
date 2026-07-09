import Foundation

public enum AppRoute: Hashable {
    case category(id: String, title: String)
    case product(id: String)
    case search(query: String)
    case checkout
    case favorites
    case orders
    case order(id: String)
    case legal(path: String)
}
