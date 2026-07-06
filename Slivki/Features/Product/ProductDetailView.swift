import SwiftUI

public struct ProductDetailView: View {
    @EnvironmentObject private var cartStore: CartStore
    let productID: String
    @State private var quantity = 1

    private var product: Product {
        Fixtures.products.first { $0.id == productID } ?? Fixtures.products[0]
    }

    public init(productID: String) {
        self.productID = productID
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SlivkiSpacing.md) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(SlivkiColor.groupedBackground)
                    .aspectRatio(1.2, contentMode: .fit)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(SlivkiColor.textSecondary)
                    }

                Text(product.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(SlivkiColor.textPrimary)

                HStack(alignment: .firstTextBaseline) {
                    Text(SlivkiMoney.format(product.price))
                        .font(.title2.weight(.bold))

                    if let oldPrice = product.oldPrice {
                        Text(SlivkiMoney.format(oldPrice))
                            .font(.subheadline)
                            .foregroundStyle(SlivkiColor.textSecondary)
                            .strikethrough()
                    }
                }

                if let sellerTitle = product.sellerTitle {
                    Label(sellerTitle, systemImage: "storefront")
                        .foregroundStyle(SlivkiColor.textSecondary)
                }

                Label(product.isAvailable ? "Есть в наличии" : "Нет в наличии", systemImage: product.isAvailable ? "checkmark.circle" : "xmark.circle")
                    .foregroundStyle(product.isAvailable ? SlivkiColor.brand : SlivkiColor.warning)

                QuantityStepper(quantity: $quantity)

                Button {
                    cartStore.add(product: product, quantity: quantity)
                } label: {
                    Label("Добавить в корзину", systemImage: "cart.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!product.isAvailable)
            }
            .padding(SlivkiSpacing.md)
        }
        .navigationTitle("Товар")
        .slivkiInlineNavigationTitle()
    }
}
