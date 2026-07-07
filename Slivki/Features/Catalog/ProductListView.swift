import SwiftUI

public struct ProductListView: View {
    @Environment(\.apiClient) private var apiClient
    @EnvironmentObject private var cartStore: CartStore
    @EnvironmentObject private var router: AppRouter

    let categoryID: String
    let title: String
    @State private var state: LoadState<[Product]> = .idle

    public init(categoryID: String, title: String) {
        self.categoryID = categoryID
        self.title = title
    }

    public var body: some View {
        ScrollView {
            LoadStateView(state: state, retry: {
                Task {
                    await loadProducts()
                }
            }) { products in
                if products.isEmpty {
                    EmptyStateView("В категории пока нет товаров", systemImage: "shippingbox")
                        .padding(SlivkiSpacing.md)
                } else {
                    productGrid(products)
                        .padding(SlivkiSpacing.md)
                }
            }
        }
        .background(SlivkiColor.groupedBackground)
        .navigationTitle(title)
        .slivkiInlineNavigationTitle()
        .task(id: categoryID) {
            await loadProducts()
        }
    }

    private func productGrid(_ products: [Product]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: SlivkiSpacing.sm)], spacing: SlivkiSpacing.sm) {
            ForEach(products) { product in
                ProductCardView(product: product) {
                    cartStore.add(product: product)
                }
                .onTapGesture {
                    router.navigate(to: .product(id: product.id), in: .catalog)
                }
            }
        }
    }

    private func loadProducts() async {
        state = .loading

        do {
            let response: ProductListResponse = try await apiClient.get(.products(
                categoryID: categoryID,
                query: nil,
                sort: .new,
                page: 1,
                perPage: 60
            ))
            guard !Task.isCancelled else {
                return
            }
            state = .loaded(response.items)
        } catch is CancellationError {
            return
        } catch {
            state = .failed("Не удалось загрузить товары категории.")
        }
    }
}
