import XCTest
@testable import Slivki

@MainActor
final class FavoritesStoreTests: XCTestCase {
    func testTogglePersistsFavoriteProduct() {
        let defaults = isolatedDefaults()
        let product = Fixtures.products[0]
        let store = FavoritesStore(storage: defaults)

        store.toggle(product)

        XCTAssertTrue(store.contains(product))
        XCTAssertEqual(store.products.first?.id, product.id)

        let restored = FavoritesStore(storage: defaults)
        XCTAssertTrue(restored.contains(product))
        XCTAssertEqual(restored.products.first?.title, product.title)
    }

    func testSecondToggleRemovesFavoriteProduct() {
        let store = FavoritesStore(storage: nil)
        let product = Fixtures.products[0]

        store.toggle(product)
        store.toggle(product)

        XCTAssertFalse(store.contains(product))
        XCTAssertTrue(store.products.isEmpty)
    }

    private func isolatedDefaults() -> UserDefaults {
        let suiteName = "FavoritesStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
