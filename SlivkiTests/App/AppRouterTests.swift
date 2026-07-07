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

    func testCatalogURLRoutesToCategory() throws {
        let router = AppRouter()
        let result = router.handle(url: try XCTUnwrap(URL(string: "https://slivki-shop.ru/catalog/13730")))

        XCTAssertEqual(result, .handled)
        XCTAssertEqual(router.selectedTab, .catalog)
        XCTAssertEqual(router.routes(for: .catalog), [.category(id: "13730", title: "13730")])
    }

    func testCategoryURLRoutesToCategory() throws {
        let router = AppRouter()
        let result = router.handle(url: try XCTUnwrap(URL(string: "https://slivki-shop.ru/category/gotovaya-eda")))

        XCTAssertEqual(result, .handled)
        XCTAssertEqual(router.selectedTab, .catalog)
        XCTAssertEqual(router.routes(for: .catalog), [.category(id: "gotovaya-eda", title: "gotovaya-eda")])
    }

    func testExternalURLFallsBackToSystem() throws {
        let router = AppRouter()
        let result = router.handle(url: try XCTUnwrap(URL(string: "https://apple.com")))

        XCTAssertEqual(result, .systemAction)
        XCTAssertTrue(router.routes(for: .home).isEmpty)
    }
}
