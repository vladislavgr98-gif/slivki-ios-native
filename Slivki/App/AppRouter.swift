import SwiftUI

public enum URLRoutingResult: Equatable {
    case handled
    case systemAction
}

@MainActor
public final class AppRouter: ObservableObject {
    @Published public var selectedTab: AppTab = .home
    @Published private var paths: [AppTab: [AppRoute]]

    public init(paths: [AppTab: [AppRoute]] = [:]) {
        var initialPaths = Dictionary(uniqueKeysWithValues: AppTab.allCases.map { ($0, [AppRoute]()) })
        paths.forEach { initialPaths[$0.key] = $0.value }
        self.paths = initialPaths
    }

    public func pathBinding(for tab: AppTab) -> Binding<[AppRoute]> {
        Binding(
            get: { self.paths[tab, default: []] },
            set: { self.paths[tab] = $0 }
        )
    }

    public func routes(for tab: AppTab) -> [AppRoute] {
        paths[tab, default: []]
    }

    public func navigate(to route: AppRoute, in tab: AppTab? = nil) {
        let targetTab = tab ?? selectedTab
        selectedTab = targetTab
        paths[targetTab, default: []].append(route)
    }

    public func reset(tab: AppTab? = nil) {
        if let tab {
            paths[tab] = []
        } else {
            AppTab.allCases.forEach { paths[$0] = [] }
        }
    }

    public func handle(url: URL) -> URLRoutingResult {
        guard url.host == "slivki-shop.ru" else {
            return .systemAction
        }

        if let route = route(for: url) {
            navigate(to: route, in: tab(for: route))
            return .handled
        }

        return .systemAction
    }

    private func route(for url: URL) -> AppRoute? {
        let path = url.path

        if path.hasPrefix("/shop/"), path.hasSuffix(".html") {
            let slug = path
                .split(separator: "/")
                .last
                .map(String.init)?
                .replacingOccurrences(of: ".html", with: "")

            return slug.map { .product(id: $0) }
        }

        if path == "/pages/rules.html" || path == "/pages/agreement.html" {
            return .legal(path: path)
        }

        if path.hasPrefix("/search"), let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "q" })?
            .value {
            return .search(query: query)
        }

        return nil
    }

    private func tab(for route: AppRoute) -> AppTab {
        switch route {
        case .category, .search:
            .catalog
        case .product:
            .home
        case .checkout:
            .cart
        case .order, .legal:
            .profile
        }
    }
}
