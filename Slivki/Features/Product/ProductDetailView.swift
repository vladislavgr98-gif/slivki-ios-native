import SwiftUI

public struct ProductDetailView: View {
    @Environment(\.apiClient) private var apiClient
    @EnvironmentObject private var cartStore: CartStore
    let productID: String
    @State private var quantity = 1
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
        .slivkiInlineNavigationTitle()
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
                productImage(product)

                Text(product.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(SlivkiColor.textPrimary)

                HStack(alignment: .firstTextBaseline) {
                    Text(SlivkiMoney.format(product.price, currencyCode: product.currency))
                        .font(.title2.weight(.bold))

                    if let oldPrice = product.oldPrice {
                        Text(SlivkiMoney.format(oldPrice, currencyCode: product.currency))
                            .font(.subheadline)
                            .foregroundStyle(SlivkiColor.textSecondary)
                            .strikethrough()
                    }
                }

                if !product.description.isEmpty {
                    Text(product.description)
                        .font(.body)
                        .foregroundStyle(SlivkiColor.textSecondary)
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
        .background(SlivkiColor.groupedBackground)
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
