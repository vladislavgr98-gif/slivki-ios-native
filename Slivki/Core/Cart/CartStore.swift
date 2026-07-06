import Combine
import Foundation

@MainActor
public final class CartStore: ObservableObject {
    @Published public private(set) var items: [CartItem]

    public var isEmpty: Bool {
        items.isEmpty
    }

    public var total: Decimal {
        items.reduce(Decimal.zero) { $0 + $1.lineTotal }
    }

    public init(items: [CartItem] = []) {
        self.items = items
    }

    public func add(product: Product, quantity: Int = 1) {
        guard product.isAvailable, quantity > 0 else {
            return
        }

        if let index = items.firstIndex(where: { $0.productID == product.id && $0.selectedOptions.isEmpty }) {
            items[index].quantity += quantity
        } else {
            items.append(
                CartItem(
                    id: UUID().uuidString,
                    productID: product.id,
                    title: product.title,
                    price: product.price,
                    quantity: quantity,
                    selectedOptions: []
                )
            )
        }
    }

    public func setQuantity(itemID: String, quantity: Int) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else {
            return
        }

        if quantity <= 0 {
            items.remove(at: index)
        } else {
            items[index].quantity = quantity
        }
    }

    public func remove(itemID: String) {
        items.removeAll { $0.id == itemID }
    }

    public func clear() {
        items.removeAll()
    }
}
