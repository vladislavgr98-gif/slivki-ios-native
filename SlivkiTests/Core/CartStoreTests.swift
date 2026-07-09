import XCTest
@testable import Slivki

@MainActor
final class CartStoreTests: XCTestCase {
    func testAddingSameProductIncrementsQuantity() {
        let store = CartStore()
        let product = Fixtures.products[0]

        store.add(product: product)
        store.add(product: product, quantity: 2)

        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items[0].quantity, 3)
    }

    func testSettingQuantityToZeroRemovesItem() {
        let store = CartStore()
        let product = Fixtures.products[0]

        store.add(product: product)
        let itemID = store.items[0].id
        store.setQuantity(itemID: itemID, quantity: 0)

        XCTAssertTrue(store.items.isEmpty)
    }

    func testUnavailableProductCannotBeAdded() {
        let store = CartStore()
        let unavailable = Fixtures.products[2]

        store.add(product: unavailable)

        XCTAssertTrue(store.items.isEmpty)
    }

    func testProductWithoutPriceCannotBeAdded() {
        let store = CartStore()
        let product = Product(
            id: "no-price",
            title: "No price",
            imageURL: nil,
            price: .zero,
            hasPrice: false,
            isAvailable: true
        )

        store.add(product: product)

        XCTAssertTrue(store.items.isEmpty)
    }

    func testCartTotalUpdatesAfterQuantityChanges() {
        let store = CartStore()
        let product = Fixtures.products[0]

        store.add(product: product)
        let itemID = store.items[0].id
        store.setQuantity(itemID: itemID, quantity: 2)

        XCTAssertEqual(store.total, product.price * Decimal(2))
    }

    func testCheckoutUsesSelectedItemsOnly() {
        let store = CartStore()
        let first = Fixtures.products[0]
        let second = Fixtures.products[1]

        store.add(product: first)
        store.add(product: second)

        let selectedID = store.items[0].id
        store.prepareCheckout(with: [selectedID])

        XCTAssertEqual(store.checkoutItems.count, 1)
        XCTAssertEqual(store.checkoutItems.first?.productID, first.id)
        XCTAssertEqual(store.checkoutTotal, first.price)
    }

    func testClearCheckoutItemsRemovesOnlyCheckoutSelection() {
        let store = CartStore()
        let first = Fixtures.products[0]
        let second = Fixtures.products[1]

        store.add(product: first)
        store.add(product: second)
        store.prepareCheckout(with: [store.items[0].id])

        store.clearCheckoutItems()

        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items.first?.productID, second.id)
        XCTAssertTrue(store.checkoutItemIDs.isEmpty)
    }

    func testAddOrderItemsMergesByProductID() {
        let store = CartStore()
        let product = Fixtures.products[0]
        store.add(product: product, quantity: 1)

        let orderItem = CartItem(
            id: "order-1",
            productID: product.id,
            title: product.title,
            imageURL: product.imageURL,
            price: product.price,
            quantity: 2,
            selectedOptions: []
        )

        store.add(orderItems: [orderItem])

        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items.first?.quantity, 3)
    }

    func testMergeFromServerKeepsLargerLocalQuantity() {
        let store = CartStore()
        let product = Fixtures.products[0]

        store.add(product: product, quantity: 2)

        let serverItem = CartItem(
            id: "server-1",
            productID: product.id,
            title: product.title,
            imageURL: product.imageURL,
            price: product.price,
            quantity: 1,
            selectedOptions: []
        )
        let serverCart = Cart(items: [serverItem], total: product.price)

        store.mergeFromServer(with: serverCart)

        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items.first?.quantity, 2)
    }

    func testCartItemsPersistWhenStorageIsProvided() {
        let defaults = isolatedDefaults()
        let store = CartStore(storage: defaults)
        let product = Fixtures.products[0]

        store.add(product: product, quantity: 2)

        let restored = CartStore(storage: defaults)
        XCTAssertEqual(restored.items.count, 1)
        XCTAssertEqual(restored.items.first?.productID, product.id)
        XCTAssertEqual(restored.items.first?.quantity, 2)
    }

    private func isolatedDefaults() -> UserDefaults {
        let suiteName = "CartStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
