import Combine
import Foundation

@MainActor
public final class CartStore: ObservableObject {
    @Published public private(set) var items: [CartItem] {
        didSet {
            persist()
        }
    }
    @Published public private(set) var checkoutItemIDs: Set<String> = []
    private let storage: UserDefaults?
    private let storageKey: String

    public var isEmpty: Bool {
        items.isEmpty
    }

    public var checkoutItems: [CartItem] {
        guard !checkoutItemIDs.isEmpty else {
            return items
        }
        return items.filter { checkoutItemIDs.contains($0.id) }
    }

    public var checkoutTotal: Decimal {
        checkoutItems.reduce(Decimal.zero) { $0 + $1.lineTotal }
    }

    public var total: Decimal {
        items.reduce(Decimal.zero) { $0 + $1.lineTotal }
    }

    public var totalItemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    public init(items: [CartItem] = [], storage: UserDefaults? = nil, storageKey: String = "slivki.cartItems") {
        self.storage = storage
        self.storageKey = storageKey

        if items.isEmpty,
           let data = storage?.data(forKey: storageKey),
           let decoded = try? JSONDecoder.slivki.decode([CartItem].self, from: data) {
            self.items = decoded
        } else {
            self.items = items
        }
    }

    public func add(product: Product, quantity: Int = 1) {
        guard product.canBeAddedToCart, quantity > 0 else {
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
                    imageURL: product.imageURL,
                    price: product.price,
                    quantity: quantity,
                    selectedOptions: []
                )
            )
        }
    }

    public func add(orderItems: [CartItem]) {
        for item in orderItems {
            add(cartItem: item)
        }
    }

    public func add(cartItem: CartItem) {
        guard cartItem.quantity > 0 else {
            return
        }

        if let index = items.firstIndex(where: { $0.productID == cartItem.productID && $0.selectedOptions.isEmpty }) {
            items[index].quantity += cartItem.quantity
        } else {
            items.append(
                CartItem(
                    id: UUID().uuidString,
                    productID: cartItem.productID,
                    title: cartItem.title,
                    imageURL: cartItem.imageURL,
                    price: cartItem.price,
                    quantity: cartItem.quantity,
                    selectedOptions: cartItem.selectedOptions
                )
            )
        }
    }

    public func replace(with cart: Cart) {
        items = cart.items
    }

    public func replaceIfEmpty(with cart: Cart) {
        guard items.isEmpty else {
            return
        }
        replace(with: cart)
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
        checkoutItemIDs.removeAll()
    }

    public func prepareCheckout(with selectedIDs: Set<String>) {
        checkoutItemIDs = selectedIDs
    }

    public func quantity(forProductID productID: String) -> Int {
        items.first(where: { $0.productID == productID })?.quantity ?? 0
    }

    public func setProductQuantity(product: Product, quantity: Int) {
        guard product.canBeAddedToCart else {
            return
        }

        if quantity <= 0 {
            if let item = items.first(where: { $0.productID == product.id }) {
                remove(itemID: item.id)
            }
            return
        }

        if let index = items.firstIndex(where: { $0.productID == product.id && $0.selectedOptions.isEmpty }) {
            items[index].quantity = quantity
        } else {
            add(product: product, quantity: quantity)
        }
    }

    public func mergeFromServer(with serverCart: Cart?) {
        guard let serverCart, !serverCart.items.isEmpty else {
            return
        }
        merge(serverItems: serverCart.items)
    }

    public func loadFromServer(using apiClient: APIClient) async {
        do {
            let response: CartResponse = try await apiClient.get(.cart)
            merge(serverItems: response.cart.items)
        } catch {
            // Local cart remains source of truth when server cart is unavailable.
        }
    }

    public func clearCheckoutItems() {
        let idsToRemove = Set(checkoutItems.map(\.id))
        guard !idsToRemove.isEmpty else {
            checkoutItemIDs.removeAll()
            return
        }
        items.removeAll { idsToRemove.contains($0.id) }
        checkoutItemIDs.removeAll()
    }

    /// Best-effort PUT of local cart to the mobile API. Local items remain source of truth —
    /// response body is ignored so an echo/empty stub cannot wipe the cart.
    public func syncToServer(using apiClient: APIClient) async {
        let body = CartUpdateRequest(cartItems: items)
        do {
            // Envelope data shape is `{ "cart": Cart }`, not a bare Cart.
            let _: CartResponse = try await apiClient.put(.cart, body: body)
        } catch {
            // Silent: local persistence already succeeded; server cart is still a stub.
        }
    }

    private func merge(serverItems: [CartItem]) {
        var merged = items
        for serverItem in serverItems {
            if let index = merged.firstIndex(where: { $0.productID == serverItem.productID }) {
                merged[index].quantity = max(merged[index].quantity, serverItem.quantity)
            } else {
                merged.append(serverItem)
            }
        }
        items = merged
    }

    private func persist() {
        if let data = try? JSONEncoder.slivki.encode(items) {
            storage?.set(data, forKey: storageKey)
        }
    }
}
