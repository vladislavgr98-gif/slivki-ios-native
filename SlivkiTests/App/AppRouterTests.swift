import XCTest
@testable import Slivki

@MainActor
final class AppRouterTests: XCTestCase {
    func testProductURLRoutesToProduct() throws {
        let router = AppRouter()
        let result = router.handle(url: try XCTUnwrap(URL(string: "https://slivki-shop.ru/shop/test/product-123.html")))

        XCTAssertEqual(result, .handled)
        XCTAssertEqual(router.selectedTab, .home)
        XCTAssertEqual(router.routes(for: .home), [.product(id: "product-123")])
    }

    func testRulesURLRoutesToProfileLegalPage() throws {
        let router = AppRouter()
        let result = router.handle(url: try XCTUnwrap(URL(string: "https://slivki-shop.ru/pages/rules.html")))

        XCTAssertEqual(result, .handled)
        XCTAssertEqual(router.selectedTab, .profile)
        XCTAssertEqual(router.routes(for: .profile), [.legal(path: "/pages/rules.html")])
    }

    func testExternalURLFallsBackToSystem() throws {
        let router = AppRouter()
        let result = router.handle(url: try XCTUnwrap(URL(string: "https://apple.com")))

        XCTAssertEqual(result, .systemAction)
        XCTAssertTrue(router.routes(for: .home).isEmpty)
    }
}
