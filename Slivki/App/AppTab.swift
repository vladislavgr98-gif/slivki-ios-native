import SwiftUI

public enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case home
    case catalog
    case cart
    case profile

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .home:
            "Главная"
        case .catalog:
            "Каталог"
        case .cart:
            "Корзина"
        case .profile:
            "Профиль"
        }
    }

    public var systemImage: String {
        switch self {
        case .home:
            "house"
        case .catalog:
            "square.grid.2x2"
        case .cart:
            "cart"
        case .profile:
            "person"
        }
    }
}
