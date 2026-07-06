import SwiftUI

public struct CartView: View {
    @EnvironmentObject private var cartStore: CartStore
    @EnvironmentObject private var router: AppRouter

    public init() {}

    public var body: some View {
        List {
            if cartStore.isEmpty {
                EmptyStateView("Корзина пустая", systemImage: "cart", message: "Добавьте товары из каталога.")
            } else {
                ForEach(cartStore.items) { item in
                    CartRow(item: item)
                }

                Section {
                    HStack {
                        Text("Итого")
                            .font(.headline)
                        Spacer()
                        Text(SlivkiMoney.format(cartStore.total))
                            .font(.headline)
                    }

                    Button {
                        router.navigate(to: .checkout, in: .cart)
                    } label: {
                        Label("Оформить заказ", systemImage: "checkmark.circle")
                    }
                }
            }
        }
        .navigationTitle("Корзина")
    }
}

private struct CartRow: View {
    @EnvironmentObject private var cartStore: CartStore
    let item: CartItem

    var body: some View {
        VStack(alignment: .leading, spacing: SlivkiSpacing.sm) {
            Text(item.title)
                .font(.headline)

            HStack {
                Text(SlivkiMoney.format(item.lineTotal))
                    .foregroundStyle(SlivkiColor.textSecondary)

                Spacer()

                QuantityStepper(
                    quantity: Binding(
                        get: { item.quantity },
                        set: { cartStore.setQuantity(itemID: item.id, quantity: $0) }
                    )
                )
            }
        }
    }
}
