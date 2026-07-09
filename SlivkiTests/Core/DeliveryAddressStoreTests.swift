import XCTest
@testable import Slivki

@MainActor
final class DeliveryAddressStoreTests: XCTestCase {
    func testUpsertSetsDefaultWhenFirstAddress() {
        let store = DeliveryAddressStore()
        let address = SavedDeliveryAddress(city: "Львовское", street: "ул. Советская", house: "46")

        store.upsert(address)

        XCTAssertEqual(store.addresses.count, 1)
        XCTAssertTrue(store.defaultAddress?.isDefault == true)
    }

    func testFormattedLineIncludesApartmentDetails() {
        let address = SavedDeliveryAddress(
            city: "Львовское",
            street: "ул. Советская",
            house: "46",
            entrance: "2",
            floor: "3",
            apartment: "12"
        )

        XCTAssertEqual(address.formattedLine, "ул. Советская, д. 46, кв. 12, подъезд 2, этаж 3")
    }
}
