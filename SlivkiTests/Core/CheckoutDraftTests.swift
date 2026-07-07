import XCTest
@testable import Slivki

final class CheckoutDraftTests: XCTestCase {
    func testBlankDraftIsInvalid() {
        let draft = CheckoutDraft()

        XCTAssertFalse(draft.isValid)
        XCTAssertEqual(
            draft.validationErrors,
            [.customerNameRequired, .phoneRequired, .cityRequired, .addressRequired]
        )
    }

    func testShortPhoneIsInvalid() {
        let draft = CheckoutDraft(
            customerName: "Test Customer",
            phone: "123",
            city: "Minsk",
            address: "Main street 1"
        )

        XCTAssertFalse(draft.isValid)
        XCTAssertEqual(draft.validationErrors, [.phoneTooShort])
    }

    func testValidDraftTrimsTextAndNormalizesPhone() {
        let draft = CheckoutDraft(
            customerName: "  Test Customer  ",
            phone: " +375 (29) 123-45-67 ",
            city: " Minsk ",
            address: " Main street 1 "
        )

        XCTAssertTrue(draft.isValid)
        XCTAssertEqual(draft.trimmedCustomerName, "Test Customer")
        XCTAssertEqual(draft.normalizedPhone, "+375291234567")
        XCTAssertEqual(draft.trimmedCity, "Minsk")
        XCTAssertEqual(draft.trimmedAddress, "Main street 1")
    }
}
