import SwiftUI

public struct AppView: View {
    @StateObject private var router = AppRouter()
    @StateObject private var cartStore = CartStore(storage: .standard)
    @StateObject private var sessionStore = SessionStore()
    @StateObject private var bootstrapStore = BootstrapStore()
    @StateObject private var favoritesStore = FavoritesStore()
    @StateObject private var addressStore = DeliveryAddressStore(storage: .standard)
    @StateObject private var checkoutStore = CheckoutStore()
    @ObservedObject private var pushService = PushNotificationService.shared
    @State private var cartSyncTask: Task<Void, Never>?
    @State private var bootstrapLoadTask: Task<Void, Never>?

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
        .tint(SlivkiColor.brandBright)
        #if os(iOS)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SlivkiFloatingTabBar(
                selectedTab: $router.selectedTab,
                cartCount: cartStore.totalItemCount,
                profileTitle: sessionStore.isAuthenticated ? "Профиль" : "Войти"
            )
        }
        #endif
        .environmentObject(router)
        .environmentObject(cartStore)
        .environmentObject(sessionStore)
        .environmentObject(bootstrapStore)
        .environmentObject(favoritesStore)
        .environmentObject(addressStore)
        .environmentObject(checkoutStore)
        .environment(\.apiClient, apiClient)
        .environment(\.reloadBootstrap, reloadBootstrap)
        .onAppear {
            startBootstrapLoadIfNeeded()
        }
        .onChange(of: cartStore.items) { _ in
            scheduleCartSync()
        }
        .onChange(of: sessionStore.hasStoredToken) { hasToken in
            guard hasToken else {
                return
            }
            Task {
                await refreshAuthenticatedState()
            }
        }
        .onChange(of: pushService.deviceToken) { _ in
            Task {
                await pushService.syncTokenIfNeeded(using: apiClient, isAuthenticated: sessionStore.isAuthenticated)
            }
        }
        .onChange(of: pushService.pendingRoute) { route in
            guard let route else {
                return
            }
            router.open(route: route)
        }
        .onOpenURL { url in
            _ = router.handle(url: url)
        }
    }

    private var apiClient: APIClient {
        APIClient(accessToken: { sessionStore.sessionToken })
    }

    private func tabStack<Content: View>(_ tab: AppTab, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack(path: router.pathBinding(for: tab)) {
            content()
                .navigationDestination(for: AppRoute.self) { route in
                    AppRouteView(route: route)
                }
        }
        .tag(tab)
    }

    private var reloadBootstrap: @Sendable () async -> Void {
        { await self.loadBootstrap() }
    }

    private func startBootstrapLoadIfNeeded() {
        guard bootstrapLoadTask == nil else {
            return
        }

        bootstrapLoadTask = Task {
            await loadBootstrap()
            await pushService.refreshAuthorizationStatus()
            bootstrapLoadTask = nil
        }
    }

    private func loadBootstrap() async {
        sessionStore.restore()
        if let response = await bootstrapStore.load(using: apiClient) {
            await applyBootstrapResponse(response)
            return
        }

        guard sessionStore.hasStoredToken, bootstrapStore.shouldRetryWithoutAuth else {
            return
        }

        let guestClient = APIClient(accessToken: { nil })
        guard let response = await bootstrapStore.load(using: guestClient) else {
            return
        }

        sessionStore.logout()
        await applyBootstrapResponse(response)
    }

    private func applyBootstrapResponse(_ response: BootstrapResponse) async {
        sessionStore.applyBootstrap(user: response.user)
        cartStore.mergeFromServer(with: response.cart)
        if !cartStore.isEmpty {
            scheduleCartSync()
        }
        await syncPushRegistration()
    }

    private func syncPushRegistration() async {
        if sessionStore.isAuthenticated {
            await pushService.requestPermissionAndRegister()
        }
        await pushService.syncTokenIfNeeded(using: apiClient, isAuthenticated: sessionStore.isAuthenticated)
    }

    private func refreshAuthenticatedState() async {
        await sessionStore.syncMobileToken()
        if let response = await bootstrapStore.load(using: apiClient) {
            await applyBootstrapResponse(response)
            return
        }
        await cartStore.loadFromServer(using: apiClient)
        await syncPushRegistration()
    }

    private func scheduleCartSync() {
        cartSyncTask?.cancel()
        cartSyncTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await cartStore.syncToServer(using: apiClient)
        }
    }
}

private struct AppRouteView: View {
    let route: AppRoute

    var body: some View {
        switch route {
        case .category(let id, let title):
            ProductListView(categoryID: id, title: title)
        case .product(let id):
            ProductDetailView(productID: id)
        case .search(let query):
            SearchView(initialQuery: query)
        case .checkout:
            CheckoutView()
        case .favorites:
            FavoritesView()
        case .orders:
            OrdersView()
        case .order(let id):
            OrderDetailView(orderID: id)
        case .legal(let path):
            LegalWebView(path: path)
        }
    }
}
