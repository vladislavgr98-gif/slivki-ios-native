import SwiftUI

public struct HomeView: View {
    @Environment(\.apiClient) private var apiClient
    @EnvironmentObject private var cartStore: CartStore
    @EnvironmentObject private var router: AppRouter
    @State private var state: LoadState<BootstrapResponse> = .idle

    private let fallbackProducts: [Product]
    private let fallbackCategories: [Category]

    public init(products: [Product] = Fixtures.products, categories: [Category] = Fixtures.categories) {
        self.fallbackProducts = products
        self.fallbackCategories = categories
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SlivkiSpacing.md) {
                header
                searchButton
                statusBanner
                categoryStrip
                productGrid
            }
            .padding(SlivkiSpacing.md)
        }
        .background(SlivkiColor.groupedBackground)
        .navigationTitle(siteName)
        .slivkiInlineNavigationTitle()
        .task {
            await loadBootstrap()
        }
    }

    private var loadedBootstrap: BootstrapResponse? {
        if case .loaded(let response) = state {
            return response
        }
        return nil
    }

    private var siteName: String {
        loadedBootstrap?.site?.name ?? "Сливки"
    }

    private var categories: [Category] {
        let loaded = loadedBootstrap?.categories ?? []
        return loaded.isEmpty ? fallbackCategories : loaded
    }

    private var products: [Product] {
        let loaded = loadedBootstrap?.featuredProducts.items ?? []
        return loaded.isEmpty ? fallbackProducts : loaded
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: SlivkiSpacing.xs) {
                Text(siteName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(SlivkiColor.textPrimary)

                Label(loadedBootstrap?.site?.address ?? Fixtures.city.title, systemImage: "location")
                    .font(.subheadline)
                    .foregroundStyle(SlivkiColor.textSecondary)
                    .lineLimit(1)
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

    @ViewBuilder
    private var statusBanner: some View {
        switch state {
        case .idle, .loading:
            HStack(spacing: SlivkiSpacing.sm) {
                ProgressView()
                Text("Загружаем каталог")
                    .font(.subheadline)
                    .foregroundStyle(SlivkiColor.textSecondary)
            }
            .padding(SlivkiSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SlivkiColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        case .failed(let message):
            VStack(alignment: .leading, spacing: SlivkiSpacing.sm) {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(SlivkiColor.textSecondary)
                Button("Повторить") {
                    Task {
                        await loadBootstrap()
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(SlivkiSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SlivkiColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        case .loaded:
            EmptyView()
        }
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
                                .frame(width: 150)
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

    private func loadBootstrap() async {
        state = .loading

        do {
            let response: BootstrapResponse = try await apiClient.get(.bootstrap)
            guard !Task.isCancelled else {
                return
            }
            state = .loaded(response)
        } catch is CancellationError {
            return
        } catch {
            state = .failed("Не удалось загрузить каталог. Показываем сохраненные товары.")
        }
    }
}
