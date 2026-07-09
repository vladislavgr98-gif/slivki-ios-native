import XCTest
@testable import Slivki

final class CallFirstAuthServiceTests: XCTestCase {
    func testNormalizePhoneAddsCountryCode() {
        XCTAssertEqual(CallFirstAuthService.normalizePhone("9991234567"), "79991234567")
    }

    func testNormalizePhoneReplacesLeadingEight() {
        XCTAssertEqual(CallFirstAuthService.normalizePhone("89991234567"), "79991234567")
    }

    func testFormatPhone() {
        XCTAssertEqual(CallFirstAuthService.formatPhone("79991234567"), "+7 (999) 123-45-67")
    }

    func testIsValidPhone() {
        XCTAssertTrue(CallFirstAuthService.isValidPhone("+7 (999) 123-45-67"))
        XCTAssertFalse(CallFirstAuthService.isValidPhone("12345"))
    }
}
