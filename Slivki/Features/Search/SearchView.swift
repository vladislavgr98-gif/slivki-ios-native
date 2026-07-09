import SwiftUI

public struct SearchView: View {
    @Environment(\.apiClient) private var apiClient
    @EnvironmentObject private var bootstrapStore: BootstrapStore
    @EnvironmentObject private var cartStore: CartStore
    @EnvironmentObject private var favoritesStore: FavoritesStore
    @EnvironmentObject private var router: AppRouter
    @State private var query: String
    @State private var state: LoadState<[Product]> = .idle
    @State private var sort: ProductSort = .new
    @State private var filters = ProductCatalogFilters()

    public init(initialQuery: String = "") {
        self._query = State(initialValue: initialQuery)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SlivkiSpacing.lg) {
                if !trimmedQuery.isEmpty {
                    Text(trimmedQuery)
                        .font(.title2.weight(.black))
                        .foregroundStyle(SlivkiColor.textPrimary)
                }

                ProductSortToolbar(sort: $sort, filters: $filters)
                resultsContent
                StorefrontFooter(
                    site: bootstrapStore.site,
                    onFavorites: { router.navigate(to: .favorites, in: .catalog) },
                    onAbout: { router.navigate(to: .legal(path: "/pages/rules.html"), in: .catalog) },
                    onFeedback: { router.selectedTab = .profile },
                    onRules: { router.navigate(to: .legal(path: "/pages/rules.html"), in: .catalog) },
                    onAgreement: { router.navigate(to: .legal(path: "/pages/agreement.html"), in: .catalog) }
                )
            }
            .padding(SlivkiSpacing.md)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: SlivkiSpacing.sm) {
                StorefrontHeader(
                    variant: .home,
                    siteName: bootstrapStore.site?.name ?? "Сливки"
                )
                SlivkiSearchBar(text: $query) {
                    Task { await search() }
                }
                StorefrontDeliveryStrip()
            }
            .padding(.horizontal, SlivkiSpacing.md)
            .padding(.top, SlivkiSpacing.md)
            .padding(.bottom, SlivkiSpacing.sm)
            .background(SlivkiColor.surface)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(SlivkiColor.border.opacity(0.8))
                    .frame(height: 1)
            }
        }
        .background(SlivkiColor.groupedBackground)
        .navigationTitle("Поиск")
        .slivkiHideNavigationBar()
        .task(id: "\(trimmedQuery)-\(sort.rawValue)-\(filters.inStockOnly)-\(filters.onSaleOnly)") {
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else {
                return
            }

            guard !trimmedQuery.isEmpty else {
                state = .idle
                return
            }

            await search()
        }
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @ViewBuilder
    private var resultsContent: some View {
        if trimmedQuery.isEmpty {
            SlivkiCard {
                Text("Введите запрос в поле поиска выше")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SlivkiColor.textSecondary)
            }
        } else {
            switch state {
            case .idle, .loading:
                SlivkiCard {
                    HStack(spacing: SlivkiSpacing.sm) {
                        ProgressView()
                        Text("Ищем товары")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(SlivkiColor.textSecondary)
                    }
                }
            case .failed(let message):
                SlivkiCard {
                    VStack(alignment: .leading, spacing: SlivkiSpacing.md) {
                        EmptyStateView("Ничего не найдено", systemImage: "magnifyingglass", message: message)
                        Button("Повторить") {
                            Task {
                                await search()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            case .loaded(let results):
                if results.isEmpty {
                    SlivkiCard {
                        EmptyStateView("Ничего не найдено", systemImage: "magnifyingglass", message: "Попробуйте другой запрос.")
                    }
                } else {
                    productGrid(results)
                }
            }
        }
    }

    private func productGrid(_ products: [Product]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: SlivkiSpacing.sm), GridItem(.flexible(), spacing: SlivkiSpacing.sm)], spacing: SlivkiSpacing.sm) {
            ForEach(products) { product in
                ProductCardView(
                    product: product,
                    cartQuantity: cartStore.quantity(forProductID: product.id),
                    isFavorite: favoritesStore.contains(product),
                    onFavoriteToggle: {
                        favoritesStore.toggle(product)
                    },
                    onQuantityChange: { quantity in
                        cartStore.setProductQuantity(product: product, quantity: quantity)
                    }
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    router.navigate(to: .product(id: product.id), in: .catalog)
                }
            }
        }
    }

    private func search() async {
        state = .loading

        guard !trimmedQuery.isEmpty else {
            state = .idle
            return
        }

        do {
            let response: ProductListResponse = try await apiClient.get(.products(
                categoryID: nil,
                query: trimmedQuery,
                sort: sort,
                page: 1,
                perPage: 40,
                filters: filters
            ))
            guard !Task.isCancelled else {
                return
            }
            state = .loaded(response.items)
        } catch is CancellationError {
            return
        } catch {
            let fallback = Fixtures.products.filter { $0.title.localizedCaseInsensitiveContains(trimmedQuery) }
            state = fallback.isEmpty
                ? .failed("Попробуйте изменить запрос или повторить поиск.")
                : .loaded(fallback)
        }
    }
}
