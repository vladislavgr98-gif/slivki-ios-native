import SwiftUI

public struct HomeView: View {
    @Environment(\.reloadBootstrap) private var reloadBootstrap
    @EnvironmentObject private var bootstrapStore: BootstrapStore
    @EnvironmentObject private var cartStore: CartStore
    @EnvironmentObject private var favoritesStore: FavoritesStore
    @EnvironmentObject private var router: AppRouter

    private let fallbackProducts: [Product]
    private let fallbackCategories: [Category]
    private let fallbackBannerURL = URL(string: "https://slivki-shop.ru/upload/23.webp")

    public init(products: [Product] = Fixtures.products, categories: [Category] = Fixtures.categories) {
        self.fallbackProducts = products
        self.fallbackCategories = categories
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                topSection
                contentSection
            }
        }
        .background(SlivkiColor.groupedBackground)
        .navigationTitle("")
        .slivkiHideNavigationBar()
    }

    private var topSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            StorefrontHeader(variant: .home, siteName: siteName)
                .padding(.bottom, SlivkiSpacing.md)
            searchButton
            deliveryPill
            categoryChips
        }
        .padding(.horizontal, SlivkiSpacing.md)
        .padding(.top, SlivkiSpacing.md)
        .padding(.bottom, SlivkiSpacing.lg)
        .background(SlivkiColor.surface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(SlivkiColor.border.opacity(0.8))
                .frame(height: 1)
        }
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: SlivkiSpacing.lg) {
            statusBanner
            heroBanner
            productGrid
            footerLinks
        }
        .padding(SlivkiSpacing.md)
        .padding(.bottom, SlivkiSpacing.xl)
    }

    private var footerLinks: some View {
        StorefrontFooter(
            site: footerSite,
            onFavorites: { router.navigate(to: .favorites, in: .home) },
            onAbout: { router.navigate(to: .legal(path: "/pages/rules.html"), in: .home) },
            onFeedback: { router.selectedTab = .profile },
            onRules: { router.navigate(to: .legal(path: "/pages/rules.html"), in: .home) },
            onAgreement: { router.navigate(to: .legal(path: "/pages/agreement.html"), in: .home) }
        )
    }

    private var loadedBootstrap: BootstrapResponse? {
        bootstrapStore.response
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

    private var banners: [Banner] {
        loadedBootstrap?.banners ?? []
    }

    private var deliveryPill: some View {
        StorefrontDeliveryStrip()
            .padding(.bottom, SlivkiSpacing.md)
            .frame(maxWidth: .infinity)
    }

    private var searchButton: some View {
        Button {
            router.navigate(to: .search(query: ""), in: .catalog)
        } label: {
            HStack(spacing: SlivkiSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                Text("Что вы хотите найти?")
                    .font(.title3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer()
            }
            .foregroundStyle(SlivkiColor.textSecondary)
            .padding(.horizontal, SlivkiSpacing.md)
            .frame(height: 58)
            .background(SlivkiColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(SlivkiColor.border, lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .padding(.bottom, SlivkiSpacing.sm)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var statusBanner: some View {
        switch state {
        case .idle, .loading:
            HStack(spacing: SlivkiSpacing.sm) {
                ProgressView()
                Text("Загружаем витрину")
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
                        await reloadBootstrap()
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

    private var state: LoadState<BootstrapResponse> {
        bootstrapStore.state
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SlivkiSpacing.sm) {
                Button {
                    router.selectedTab = .catalog
                } label: {
                    Label("Каталог", systemImage: "line.3.horizontal")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, SlivkiSpacing.lg)
                        .frame(height: 48)
                        .background(SlivkiColor.brandBright)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    router.navigate(to: .search(query: "акции"), in: .catalog)
                } label: {
                    Text("Акции")
                        .font(.headline)
                        .foregroundStyle(SlivkiColor.textPrimary)
                        .lineLimit(1)
                        .padding(.horizontal, SlivkiSpacing.lg)
                        .frame(height: 48)
                        .background(SlivkiColor.surface)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(SlivkiColor.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                if let readyFood = bootstrapStore.category(matchingTitle: "готов") {
                    Button {
                        router.navigate(to: .category(id: readyFood.id, title: readyFood.title), in: .home)
                    } label: {
                        Text("Готовая еда")
                            .font(.headline)
                            .foregroundStyle(SlivkiColor.textPrimary)
                            .lineLimit(1)
                            .padding(.horizontal, SlivkiSpacing.lg)
                            .frame(height: 48)
                            .background(SlivkiColor.surface)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(SlivkiColor.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                ForEach(categories.prefix(6)) { category in
                    Button {
                        router.navigate(to: .category(id: category.id, title: category.title), in: .catalog)
                    } label: {
                        Text(category.title)
                            .font(.headline)
                            .foregroundStyle(SlivkiColor.textPrimary)
                            .lineLimit(1)
                            .padding(.horizontal, SlivkiSpacing.lg)
                            .frame(height: 48)
                            .background(SlivkiColor.surface)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(SlivkiColor.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, SlivkiSpacing.xs)
        }
    }

    private var heroBanner: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: banners.first?.imageURL ?? fallbackBannerURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure, .empty:
                    LinearGradient(
                        colors: [SlivkiColor.brandBright, SlivkiColor.warning],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                @unknown default:
                    SlivkiColor.groupedBackground
                }
            }

            Text("Реклама")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SlivkiColor.textPrimary)
                .padding(.horizontal, SlivkiSpacing.sm)
                .padding(.vertical, SlivkiSpacing.xs)
                .background(Color.white.opacity(0.78))
                .clipShape(Capsule())
                .padding(SlivkiSpacing.sm)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private var productGrid: some View {
        VStack(alignment: .leading, spacing: SlivkiSpacing.md) {
            Text("Рекомендуем")
                .font(.largeTitle.weight(.black))
                .foregroundStyle(SlivkiColor.textPrimary)

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
                        router.navigate(to: .product(id: product.id), in: .home)
                    }
                }
            }
            .padding(.bottom, SlivkiSpacing.lg)
        }
    }

    private var footerSite: MobileSiteInfo? {
        loadedBootstrap?.site
    }
}
