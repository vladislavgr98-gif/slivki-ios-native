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
}
