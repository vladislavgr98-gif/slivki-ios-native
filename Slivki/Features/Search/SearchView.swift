import SwiftUI

public struct SearchView: View {
    @EnvironmentObject private var cartStore: CartStore
    @State private var query: String
    @State private var results: [Product]

    public init(initialQuery: String = "") {
        self._query = State(initialValue: initialQuery)
        self._results = State(initialValue: Fixtures.products)
    }

    public var body: some View {
        List {
            if results.isEmpty {
                EmptyStateView("Ничего не найдено", systemImage: "magnifyingglass")
            } else {
                ForEach(results) { product in
                    HStack(spacing: SlivkiSpacing.md) {
                        VStack(alignment: .leading) {
                            Text(product.title)
                                .font(.headline)
                            Text(SlivkiMoney.format(product.price))
                                .foregroundStyle(SlivkiColor.textSecondary)
                        }

                        Spacer()

                        Button {
                            cartStore.add(product: product)
                        } label: {
                            Image(systemName: "cart.badge.plus")
                        }
                        .disabled(!product.isAvailable)
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

            results = query.isEmpty
                ? Fixtures.products
                : Fixtures.products.filter { $0.title.localizedCaseInsensitiveContains(query) }
        }
    }
}
