import SwiftUI

public struct ProductListView: View {
    @Environment(\.apiClient) private var apiClient
    @EnvironmentObject private var bootstrapStore: BootstrapStore
    @EnvironmentObject private var cartStore: CartStore
    @EnvironmentObject private var favoritesStore: FavoritesStore
    @EnvironmentObject private var router: AppRouter

    let categoryID: String
    let title: String
    @State private var state: LoadState<ProductListResponse> = .idle
    @State private var query = ""
    @State private var sort: ProductSort = .new
    @State private var filters = ProductCatalogFilters()
    @State private var page = 1
    @State private var isLoadingMore = false

    public init(categoryID: String, title: String) {
        self.categoryID = categoryID
        self.title = title
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SlivkiSpacing.lg) {
                Text(title)
                    .font(.title2.weight(.black))
                    .foregroundStyle(SlivkiColor.textPrimary)

                ProductSortToolbar(sort: $sort, filters: $filters)
                subcategoryChips

                LoadStateView(state: state, retry: {
                    Task {
                        await loadProducts()
                    }
                }) { response in
                    if response.items.isEmpty {
                        EmptyStateView("В категории пока нет товаров", systemImage: "shippingbox")
                            .padding(SlivkiSpacing.md)
                            .frame(maxWidth: .infinity)
                            .background(SlivkiColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        productGrid(response.items)
                        loadMoreButton(response)
                    }
                }
            }
            .padding(SlivkiSpacing.md)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: SlivkiSpacing.sm) {
                StorefrontHeader(
                    variant: .home,
                    siteName: bootstrapStore.site?.name ?? "Сливки"
                )
                SlivkiSearchBar(text: $query, placeholder: "Искать в разделе") {
                    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else {
                        return
                    }
                    router.navigate(to: .search(query: trimmed), in: .catalog)
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
        .navigationTitle(title)
        .slivkiHideNavigationBar()
        .task(id: "\(categoryID)-\(sort.rawValue)-\(filters.inStockOnly)-\(filters.onSaleOnly)") {
            await loadProducts()
        }
    }

    private var subcategories: [Category] {
        bootstrapStore.category(id: categoryID)?.children ?? []
    }

    @ViewBuilder
    private var subcategoryChips: some View {
        if !subcategories.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: SlivkiSpacing.xs) {
                    ForEach(subcategories) { category in
                        Button {
                            router.navigate(to: .category(id: category.id, title: category.title), in: .catalog)
                        } label: {
                            SlivkiChip(category.title)
                        }
                        .buttonStyle(.plain)
                    }
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
                .onTapGesture {
                    router.navigate(to: .product(id: product.id), in: .catalog)
                }
            }
        }
    }

    @ViewBuilder
    private func loadMoreButton(_ response: ProductListResponse) -> some View {
        if response.pagination.count > response.items.count || response.pagination.total > response.items.count {
            Button {
                Task {
                    await loadNextPage()
                }
            } label: {
                HStack {
                    if isLoadingMore {
                        ProgressView()
                    }
                    Text(isLoadingMore ? "Загружаем" : "Показать еще")
                }
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .buttonStyle(.bordered)
            .disabled(isLoadingMore)
        }
    }

    private func loadProducts() async {
        state = .loading
        page = 1

        do {
            let response: ProductListResponse = try await apiClient.get(.products(
                categoryID: categoryID,
                query: nil,
                sort: sort,
                page: page,
                perPage: 60,
                filters: filters
            ))
            guard !Task.isCancelled else {
                return
            }
            state = .loaded(response)
        } catch is CancellationError {
            return
        } catch {
            state = .failed("Не удалось загрузить товары категории.")
        }
    }

    private func loadNextPage() async {
        guard !isLoadingMore else {
            return
        }
        guard case .loaded(let current) = state else {
            return
        }

        isLoadingMore = true
        defer {
            isLoadingMore = false
        }

        let nextPage = page + 1
        do {
            let response: ProductListResponse = try await apiClient.get(.products(
                categoryID: categoryID,
                query: nil,
                sort: sort,
                page: nextPage,
                perPage: 60,
                filters: filters
            ))
            guard !Task.isCancelled else {
                return
            }
            page = nextPage
            let merged = ProductListResponse(
                items: current.items + response.items,
                pagination: response.pagination
            )
            state = .loaded(merged)
        } catch {
            state = .loaded(current)
        }
    }
}
