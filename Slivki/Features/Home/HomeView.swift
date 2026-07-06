import SwiftUI

public struct HomeView: View {
    @EnvironmentObject private var cartStore: CartStore
    @EnvironmentObject private var router: AppRouter
    private let products: [Product]
    private let categories: [Category]

    public init(products: [Product] = Fixtures.products, categories: [Category] = Fixtures.categories) {
        self.products = products
        self.categories = categories
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SlivkiSpacing.md) {
                header
                searchButton
                banner
                categoryStrip
                productGrid
            }
            .padding(SlivkiSpacing.md)
        }
        .background(SlivkiColor.groupedBackground)
        .navigationTitle("Сливки")
        .slivkiInlineNavigationTitle()
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: SlivkiSpacing.xs) {
                Text("Сливки")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(SlivkiColor.textPrimary)

                Label(Fixtures.city.title, systemImage: "location")
                    .font(.subheadline)
                    .foregroundStyle(SlivkiColor.textSecondary)
            }

            Spacer()

            Image(systemName: "leaf.fill")
                .font(.title2)
                .foregroundStyle(SlivkiColor.brand)
        }
    }

    private var searchButton: some View {
        Button {
            router.navigate(to: .search(query: ""), in: .catalog)
        } label: {
            HStack {
                Image(systemName: "magnifyingglass")
                Text("Поиск товаров")
                Spacer()
            }
            .foregroundStyle(SlivkiColor.textSecondary)
            .padding(SlivkiSpacing.md)
            .background(SlivkiColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var banner: some View {
        VStack(alignment: .leading, spacing: SlivkiSpacing.sm) {
            Text("Выгодные покупки рядом")
                .font(.headline)
            Text("Нативный экран повторяет смысл мобильного сайта, но не встраивает его как WebView.")
                .font(.subheadline)
                .foregroundStyle(SlivkiColor.textSecondary)
        }
        .padding(SlivkiSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SlivkiColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var categoryStrip: some View {
        VStack(alignment: .leading, spacing: SlivkiSpacing.sm) {
            Text("Категории")
                .font(SlivkiTypography.sectionTitle)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: SlivkiSpacing.sm) {
                    ForEach(categories) { category in
                        Button {
                            router.navigate(to: .category(id: category.id, title: category.title), in: .catalog)
                        } label: {
                            CategoryTileView(category: category)
                                .frame(width: 140)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var productGrid: some View {
        VStack(alignment: .leading, spacing: SlivkiSpacing.sm) {
            Text("Популярное")
                .font(SlivkiTypography.sectionTitle)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: SlivkiSpacing.sm)], spacing: SlivkiSpacing.sm) {
                ForEach(products) { product in
                    ProductCardView(product: product) {
                        cartStore.add(product: product)
                    }
                    .onTapGesture {
                        router.navigate(to: .product(id: product.id), in: .home)
                    }
                }
            }
        }
    }
}
