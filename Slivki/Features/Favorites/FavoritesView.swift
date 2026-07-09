import SwiftUI

public struct FavoritesView: View {
    @EnvironmentObject private var favoritesStore: FavoritesStore
    @EnvironmentObject private var cartStore: CartStore
    @EnvironmentObject private var router: AppRouter

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SlivkiSpacing.lg) {
                SlivkiSectionTitle("Избранное", subtitle: subtitle)

                if favoritesStore.products.isEmpty {
                    emptyState
                } else {
                    productGrid
                }
            }
            .padding(SlivkiSpacing.md)
        }
        .background(SlivkiColor.groupedBackground)
        .navigationTitle("Избранное")
        .slivkiHideNavigationBar()
    }

    private var subtitle: String {
        favoritesStore.products.isEmpty ? "Сохраняйте товары сердцем" : "\(favoritesStore.products.count) товаров сохранено"
    }

    private var emptyState: some View {
        SlivkiCard {
            VStack(alignment: .leading, spacing: SlivkiSpacing.md) {
                EmptyStateView("Пока пусто", systemImage: "heart", message: "Нажимайте сердце на товарах, чтобы быстро возвращаться к ним.")

                Button {
                    router.selectedTab = .catalog
                } label: {
                    Label("Перейти в каталог", systemImage: "square.grid.2x2")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(SlivkiColor.brandDark)
            }
        }
    }

    private var productGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: SlivkiSpacing.sm), GridItem(.flexible(), spacing: SlivkiSpacing.sm)], spacing: SlivkiSpacing.sm) {
            ForEach(favoritesStore.products) { product in
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
                    router.navigate(to: .product(id: product.id), in: .profile)
                }
            }
        }
    }
}
