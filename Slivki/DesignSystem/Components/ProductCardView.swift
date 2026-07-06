import SwiftUI

public struct ProductCardView: View {
    let product: Product
    let onAdd: () -> Void

    public init(product: Product, onAdd: @escaping () -> Void) {
        self.product = product
        self.onAdd = onAdd
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SlivkiSpacing.sm) {
            RoundedRectangle(cornerRadius: 8)
                .fill(SlivkiColor.groupedBackground)
                .aspectRatio(1.15, contentMode: .fit)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(SlivkiColor.textSecondary)
                }

            Text(product.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SlivkiColor.textPrimary)
                .lineLimit(2)
                .frame(minHeight: 38, alignment: .topLeading)

            HStack(alignment: .firstTextBaseline) {
                Text(SlivkiMoney.format(product.price))
                    .font(.headline)
                    .foregroundStyle(SlivkiColor.textPrimary)

                if let oldPrice = product.oldPrice {
                    Text(SlivkiMoney.format(oldPrice))
                        .font(.caption)
                        .foregroundStyle(SlivkiColor.textSecondary)
                        .strikethrough()
                }
            }

            Button(action: onAdd) {
                Label(product.isAvailable ? "В корзину" : "Нет в наличии", systemImage: "cart.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!product.isAvailable)
        }
        .padding(SlivkiSpacing.sm)
        .background(SlivkiColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(SlivkiColor.border, lineWidth: 1)
        )
    }
}
