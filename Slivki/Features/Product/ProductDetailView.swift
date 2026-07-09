import SwiftUI

public struct ProductDetailView: View {
    @Environment(\.apiClient) private var apiClient
    @EnvironmentObject private var cartStore: CartStore
    @EnvironmentObject private var favoritesStore: FavoritesStore
    @EnvironmentObject private var router: AppRouter
    let productID: String
    @State private var state: LoadState<Product> = .idle

    private var fallbackProduct: Product? {
        Fixtures.products.first { $0.id == productID }
    }

    public init(productID: String) {
        self.productID = productID
    }

    public var body: some View {
        LoadStateView(state: displayState, retry: {
            Task {
                await loadProduct()
            }
        }) { product in
            productContent(product)
        }
        .navigationTitle("Товар")
        .slivkiHideNavigationBar()
        .task(id: productID) {
            await loadProduct()
        }
    }

    private var displayState: LoadState<Product> {
        switch state {
        case .failed(let message):
            if let fallbackProduct {
                return .loaded(fallbackProduct)
            }
            return .failed(message)
        case .idle, .loading:
            if let fallbackProduct {
                return .loaded(fallbackProduct)
            }
            return state
        case .loaded:
            return state
        }
    }

    private func productContent(_ product: Product) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SlivkiSpacing.md) {
                ZStack(alignment: .topTrailing) {
                    productImage(product)

                    Button {
                        favoritesStore.toggle(product)
                    } label: {
                        Image(systemName: favoritesStore.contains(product) ? "heart.fill" : "heart")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(favoritesStore.contains(product) ? SlivkiColor.warning : SlivkiColor.textPrimary)
                            .frame(width: 42, height: 42)
                            .background(SlivkiColor.surface)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(favoritesStore.contains(product) ? "Убрать из избранного" : "Добавить в избранное")
                    .padding(SlivkiSpacing.sm)
                }

                VStack(alignment: .leading, spacing: SlivkiSpacing.md) {
                    badges(product)

                    Text(product.title)
                        .font(.title2.weight(.black))
                        .foregroundStyle(SlivkiColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    priceBlock(product)

                    HStack(spacing: SlivkiSpacing.sm) {
                        availabilityPill(product)
                        if let sellerTitle = product.sellerTitle {
                            Label(sellerTitle, systemImage: "storefront")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(SlivkiColor.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(SlivkiSpacing.md)
                .background(SlivkiColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(SlivkiColor.border.opacity(0.75), lineWidth: 1))

                productInfoRows(product)

                if !product.description.isEmpty {
                    VStack(alignment: .leading, spacing: SlivkiSpacing.sm) {
                        Text("Описание")
                            .font(.headline.weight(.black))
                            .foregroundStyle(SlivkiColor.textPrimary)
                        Text(product.description)
                            .font(.body)
                            .foregroundStyle(SlivkiColor.textSecondary)
                    }
                    .padding(SlivkiSpacing.md)
                    .background(SlivkiColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(SlivkiColor.border.opacity(0.75), lineWidth: 1))
                }
            }
            .padding(SlivkiSpacing.md)
            .padding(.bottom, 96)
        }
        .background(SlivkiColor.groupedBackground)
        .safeAreaInset(edge: .bottom) {
            stickyAddBar(product)
        }
    }

    private func productInfoRows(_ product: Product) -> some View {
        VStack(spacing: SlivkiSpacing.xs) {
            infoRow("Доставка", value: "от 30 минут", systemImage: "scooter")
            infoRow("Бесплатно", value: "при заказе от 500 ₽", systemImage: "gift")
            infoRow("Оплата", value: "наличными или картой", systemImage: "creditcard")
            infoRow("Возврат", value: "по правилам магазина", systemImage: "arrow.uturn.backward")
        }
    }

    private func infoRow(_ title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: SlivkiSpacing.md) {
            Image(systemName: systemImage)
                .font(.headline.weight(.bold))
                .foregroundStyle(SlivkiColor.brandDark)
                .frame(width: 36, height: 36)
                .background(SlivkiColor.brandBright.opacity(0.14))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(SlivkiColor.textPrimary)
                Text(value)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SlivkiColor.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, SlivkiSpacing.md)
        .frame(minHeight: 58)
        .background(SlivkiColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(SlivkiColor.border.opacity(0.75), lineWidth: 1))
    }

    private func stickyAddBar(_ product: Product) -> some View {
        let cartQuantity = cartStore.quantity(forProductID: product.id)

        return HStack(spacing: SlivkiSpacing.md) {
            if cartQuantity > 0 {
                QuantityStepper(quantity: Binding(
                    get: { cartStore.quantity(forProductID: product.id) },
                    set: { cartStore.setProductQuantity(product: product, quantity: $0) }
                ))

                VStack(alignment: .leading, spacing: 2) {
                    Text("В корзине")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SlivkiColor.textSecondary)
                    Text(SlivkiMoney.format(product.price * Decimal(cartQuantity), currencyCode: product.currency))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(SlivkiColor.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Button {
                    cartStore.add(product: product)
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text(product.canBeAddedToCart ? "Добавить в корзину" : "Недоступно")
                    }
                    .font(.headline.weight(.black))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(SlivkiColor.brandBright)
                .disabled(!product.canBeAddedToCart)
                .accessibilityHint("Добавляет товар в корзину")
            }
        }
        .padding(SlivkiSpacing.md)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(SlivkiColor.border.opacity(0.7)).frame(height: 1)
        }
    }

    @ViewBuilder
    private func badges(_ product: Product) -> some View {
        if !product.badges.isEmpty || product.oldPrice != nil {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: SlivkiSpacing.xs) {
                    if product.oldPrice != nil {
                        SlivkiChip("Акция", systemImage: "percent", isSelected: true)
                    }
                    ForEach(product.badges, id: \.self) { badge in
                        SlivkiChip(badge)
                    }
                }
            }
        }
    }

    private func priceBlock(_ product: Product) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SlivkiSpacing.sm) {
            if product.hasPrice {
                Text(SlivkiMoney.format(product.price, currencyCode: product.currency))
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(SlivkiColor.textPrimary)

                Text("/ \(product.unit)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(SlivkiColor.textSecondary)
            } else {
                Text("Цена уточняется")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(SlivkiColor.textSecondary)
            }

            if product.hasPrice, let oldPrice = product.oldPrice {
                Text(SlivkiMoney.format(oldPrice, currencyCode: product.currency))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SlivkiColor.textSecondary)
                    .strikethrough()
            }
        }
    }

    private func availabilityPill(_ product: Product) -> some View {
        Label(product.canBeAddedToCart ? "В наличии" : "Нет в продаже", systemImage: product.canBeAddedToCart ? "checkmark.circle.fill" : "xmark.circle.fill")
            .font(.caption.weight(.bold))
            .foregroundStyle(product.canBeAddedToCart ? SlivkiColor.brandDark : SlivkiColor.warning)
            .padding(.horizontal, SlivkiSpacing.sm)
            .frame(height: 30)
            .background((product.canBeAddedToCart ? SlivkiColor.brandBright : SlivkiColor.warning).opacity(0.14))
            .clipShape(Capsule())
    }

    private func productImage(_ product: Product) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(SlivkiColor.surface)

            if let imageURL = product.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(SlivkiSpacing.md)
                    case .failure:
                        placeholderImage
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
        .aspectRatio(1.2, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var placeholderImage: some View {
        Image(systemName: "photo")
            .font(.largeTitle)
            .foregroundStyle(SlivkiColor.textSecondary)
    }

    private func loadProduct() async {
        state = .loading

        do {
            let response: ProductDetailResponse = try await apiClient.get(.product(id: productID))
            guard !Task.isCancelled else {
                return
            }
            state = .loaded(response.product)
        } catch is CancellationError {
            return
        } catch {
            state = .failed("Не удалось загрузить товар.")
        }
    }
}
