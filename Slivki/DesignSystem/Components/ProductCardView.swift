import SwiftUI

public struct ProductCardView: View {
    let product: Product
    let cartQuantity: Int
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    let onQuantityChange: (Int) -> Void

    public init(
        product: Product,
        cartQuantity: Int = 0,
        isFavorite: Bool = false,
        onFavoriteToggle: @escaping () -> Void = {},
        onQuantityChange: @escaping (Int) -> Void = { _ in }
    ) {
        self.product = product
        self.cartQuantity = cartQuantity
        self.isFavorite = isFavorite
        self.onFavoriteToggle = onFavoriteToggle
        self.onQuantityChange = onQuantityChange
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SlivkiSpacing.xs) {
            ZStack(alignment: .topTrailing) {
                productImage

                Button(action: onFavoriteToggle) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(isFavorite ? SlivkiColor.warning : SlivkiColor.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.92))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                .padding(6)
                .accessibilityLabel(isFavorite ? "Убрать из избранного" : "Добавить в избранное")
            }

            Text(product.title)
                .font(.subheadline)
                .foregroundStyle(SlivkiColor.textPrimary)
                .lineLimit(2)
                .frame(minHeight: 38, alignment: .topLeading)

            Text(product.displayUnit)
                .font(.caption)
                .foregroundStyle(SlivkiColor.textSecondary)

            HStack(alignment: .center, spacing: SlivkiSpacing.xs) {
                priceBlock
                Spacer(minLength: 0)
                cartControl
            }
            .padding(.top, 2)
        }
        .padding(SlivkiSpacing.sm)
        .background(SlivkiColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(SlivkiColor.border, lineWidth: 1)
        )
        .frame(maxWidth: .infinity)
    }

    private var priceBlock: some View {
        HStack(alignment: .firstTextBaseline, spacing: SlivkiSpacing.xs) {
            if product.hasPrice {
                Text(SlivkiMoney.format(product.price, currencyCode: product.currency))
                    .font(.title3.weight(.black))
                    .foregroundStyle(SlivkiColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            } else {
                Text("Цена уточняется")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SlivkiColor.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            if product.hasPrice, let oldPrice = product.oldPrice {
                Text(SlivkiMoney.format(oldPrice, currencyCode: product.currency))
                    .font(.caption)
                    .foregroundStyle(SlivkiColor.textSecondary)
                    .strikethrough()
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var cartControl: some View {
        if cartQuantity > 0 {
            CompactQuantityStepper(
                quantity: Binding(
                    get: { cartQuantity },
                    set: onQuantityChange
                )
            )
        } else {
            Button {
                onQuantityChange(1)
            } label: {
                Image(systemName: "plus")
                    .font(.body.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(product.canBeAddedToCart ? SlivkiColor.brandBright : Color.gray.opacity(0.35))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(!product.canBeAddedToCart)
            .accessibilityLabel(product.canBeAddedToCart ? "В корзину" : "Недоступно")
        }
    }

    private var productImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(SlivkiColor.groupedBackground)

            if let imageURL = product.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(SlivkiSpacing.xs)
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
        .aspectRatio(1.08, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var placeholderImage: some View {
        Image(systemName: "photo")
            .font(.title2)
            .foregroundStyle(SlivkiColor.textSecondary)
    }
}
