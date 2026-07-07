import SwiftUI

public struct SearchView: View {
    @Environment(\.apiClient) private var apiClient
    @EnvironmentObject private var cartStore: CartStore
    @EnvironmentObject private var router: AppRouter
    @State private var query: String
    @State private var state: LoadState<[Product]> = .idle

    public init(initialQuery: String = "") {
        self._query = State(initialValue: initialQuery)
    }

    public var body: some View {
        List {
            switch state {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            case .failed(let message):
                VStack(spacing: SlivkiSpacing.sm) {
                    EmptyStateView("Ничего не найдено", systemImage: "magnifyingglass", message: message)
                    Button("Повторить") {
                        Task {
                            await search()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            case .loaded(let results):
                if results.isEmpty {
                    EmptyStateView("Ничего не найдено", systemImage: "magnifyingglass")
                } else {
                    ForEach(results) { product in
                        SearchProductRow(product: product) {
                            cartStore.add(product: product)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            router.navigate(to: .product(id: product.id), in: .catalog)
                        }
                    }
                }
            }
        }
        .navigationTitle("Поиск")
        .searchable(text: $query, prompt: "Товар, категория или бренд")
        .task(id: query) {
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else {
                return
            }

            await search()
        }
    }

    private func search() async {
        state = .loading
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let response: ProductListResponse = try await apiClient.get(.products(
                categoryID: nil,
                query: trimmed.isEmpty ? nil : trimmed,
                sort: .new,
                page: 1,
                perPage: 40
            ))
            guard !Task.isCancelled else {
                return
            }
            state = .loaded(response.items)
        } catch is CancellationError {
            return
        } catch {
            let fallback = trimmed.isEmpty
                ? Fixtures.products
                : Fixtures.products.filter { $0.title.localizedCaseInsensitiveContains(trimmed) }
            state = fallback.isEmpty
                ? .failed("Попробуйте изменить запрос или повторить поиск.")
                : .loaded(fallback)
        }
    }
}

private struct SearchProductRow: View {
    let product: Product
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: SlivkiSpacing.md) {
            productImage

            VStack(alignment: .leading, spacing: SlivkiSpacing.xs) {
                Text(product.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(product.hasPrice ? SlivkiMoney.format(product.price, currencyCode: product.currency) : "Цена уточняется")
                    .foregroundStyle(SlivkiColor.textSecondary)
            }

            Spacer()

            Button(action: onAdd) {
                Image(systemName: "cart.badge.plus")
            }
            .buttonStyle(.bordered)
            .disabled(!product.canBeAddedToCart)
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
                        placeholder
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var placeholder: some View {
        Image(systemName: "photo")
            .foregroundStyle(SlivkiColor.textSecondary)
    }
}
