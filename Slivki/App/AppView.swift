import SwiftUI

public struct AppView: View {
    @StateObject private var router = AppRouter()
    @StateObject private var cartStore = CartStore()
    @StateObject private var sessionStore = SessionStore()

    public init() {}

    public var body: some View {
        TabView(selection: $router.selectedTab) {
            tabStack(.home) {
                HomeView()
            }

            tabStack(.catalog) {
                CatalogView()
            }

            tabStack(.cart) {
                CartView()
            }

            tabStack(.profile) {
                ProfileView()
            }
        }
        .environmentObject(router)
        .environmentObject(cartStore)
        .environmentObject(sessionStore)
        .environment(\.apiClient, APIClient(accessToken: { sessionStore.sessionToken }))
        .onOpenURL { url in
            _ = router.handle(url: url)
        }
    }

    private func tabStack<Content: View>(_ tab: AppTab, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack(path: router.pathBinding(for: tab)) {
            content()
                .navigationDestination(for: AppRoute.self) { route in
                    AppRouteView(route: route)
                }
        }
        .tabItem {
            Label(tab.title, systemImage: tab.systemImage)
        }
        .tag(tab)
    }
}

private struct AppRouteView: View {
    let route: AppRoute

    var body: some View {
        switch route {
        case .category(let id, let title):
            ProductListPlaceholderView(title: title, subtitle: "Категория \(id)")
        case .product(let id):
            ProductDetailView(productID: id)
        case .search(let query):
            SearchView(initialQuery: query)
        case .checkout:
            CheckoutView()
        case .order(let id):
            OrderDetailView(orderID: id)
        case .legal(let path):
            LegalWebView(path: path)
        }
    }
}

private struct ProductListPlaceholderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        EmptyStateView(title, systemImage: "shippingbox", message: subtitle)
    }
}
