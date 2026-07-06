import Foundation
import XCTest
@testable import Slivki

final class APIClientTests: XCTestCase {
    func testProductDecodesFromMobileAPIShape() throws {
        let json = """
        {
          "id": "123",
          "title": "Мороженое Азарт",
          "category_id": "frozen",
          "image_url": "https://slivki-shop.ru/upload/item.png",
          "price": 149.90,
          "old_price": 179.90,
          "unit": "шт",
          "is_available": true,
          "seller_title": "Сливки"
        }
        """.data(using: .utf8)!

        let product = try JSONDecoder.slivki.decode(Product.self, from: json)

        XCTAssertEqual(product.id, "123")
        XCTAssertEqual(product.title, "Мороженое Азарт")
        XCTAssertEqual(product.categoryID, "frozen")
        XCTAssertEqual(product.imageURL?.absoluteString, "https://slivki-shop.ru/upload/item.png")
        XCTAssertTrue(product.isAvailable)
        XCTAssertEqual(product.sellerTitle, "Сливки")
    }

    func testProductListResponseDecodesFromContractShape() throws {
        let json = """
        {
          "items": [
            {
              "id": "123",
              "title": "Мороженое Азарт",
              "price": 149.90,
              "unit": "шт",
              "is_available": true
            }
          ],
          "pagination": {
            "page": 1,
            "per_page": 20,
            "total": 1
          }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.slivki.decode(ProductListResponse.self, from: json)

        XCTAssertEqual(response.items.count, 1)
        XCTAssertEqual(response.pagination.perPage, 20)
    }

    func testCatalogResponseDecodesWhenCategoryChildrenAreMissing() throws {
        let json = """
        {
          "categories": [
            {
              "id": "frozen",
              "title": "Заморозка"
            }
          ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.slivki.decode(CatalogResponse.self, from: json)

        XCTAssertEqual(response.categories[0].id, "frozen")
        XCTAssertTrue(response.categories[0].children.isEmpty)
    }

    func testBootstrapResponseDecodesWhenOptionalFeatureFlagsAndBannerTitleAreMissing() throws {
        let json = """
        {
          "cities": [
            { "id": "minsk", "title": "Минск" }
          ],
          "selected_city": { "id": "minsk", "title": "Минск" },
          "categories": [],
          "banners": [
            {
              "id": "hero",
              "image_url": "https://slivki-shop.ru/upload/banner.png",
              "target": { "type": "none" }
            }
          ],
          "user": null,
          "cart": {
            "id": "cart",
            "items": [],
            "totals": {
              "items_total": 0,
              "discount_total": 0,
              "payable_total": 0
            },
            "currency": "BYN"
          }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.slivki.decode(BootstrapResponse.self, from: json)

        XCTAssertEqual(response.featureFlags, [:])
        XCTAssertEqual(response.banners[0].title, "")
        XCTAssertEqual(response.cart.total, 0)
    }

    func testCartItemDecodesWhenSelectedOptionsAreMissing() throws {
        let json = """
        {
          "id": "item",
          "product_id": "product",
          "title": "Товар",
          "price": 10,
          "quantity": 2
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder.slivki.decode(CartItem.self, from: json)

        XCTAssertEqual(item.productID, "product")
        XCTAssertEqual(item.lineTotal, 20)
        XCTAssertTrue(item.selectedOptions.isEmpty)
    }

    func testClientBuildsProductsQuery() async throws {
        let session = MockSession(
            data: """
            {
              "items": [],
              "pagination": { "page": 2, "per_page": 20, "total": 0 }
            }
            """.data(using: .utf8)!,
            response: HTTPURLResponse(url: URL(string: "https://slivki-shop.ru")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        )
        let client = APIClient(session: session, accessToken: { "token" })
        let _: ProductListResponse = try await client.get(.products(categoryID: "frozen", query: "ice", sort: .popular, page: 2, perPage: 20))

        XCTAssertEqual(session.lastRequest?.url?.path, "/api/mobile/v1/products")
        XCTAssertEqual(session.lastRequest?.url?.query?.contains("category_id=frozen"), true)
        XCTAssertEqual(session.lastRequest?.url?.query?.contains("q=ice"), true)
        XCTAssertEqual(session.lastRequest?.url?.query?.contains("sort=popular"), true)
        XCTAssertEqual(session.lastRequest?.url?.query?.contains("page=2"), true)
        XCTAssertEqual(session.lastRequest?.url?.query?.contains("per_page=20"), true)
        XCTAssertEqual(session.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer token")
    }

    func testPostNoResponseAccepts204() async throws {
        let session = MockSession(
            data: Data(),
            response: HTTPURLResponse(url: URL(string: "https://slivki-shop.ru")!, statusCode: 204, httpVersion: nil, headerFields: nil)!
        )
        let client = APIClient(session: session)

        try await client.postNoResponse(.pushToken, body: PushTokenRequest(token: "apns", environment: .sandbox, deviceID: "device"))

        XCTAssertEqual(session.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(session.lastRequest?.url?.path, "/api/mobile/v1/push-token")
        XCTAssertEqual(session.lastRequestBodyString?.contains("\"device_id\":\"device\""), true)
    }
}

private final class MockSession: HTTPDataSession {
    let data: Data
    let response: URLResponse
    private(set) var lastRequest: URLRequest?
    var lastRequestBodyString: String? {
        lastRequest?.httpBody.flatMap { String(data: $0, encoding: .utf8) }
    }

    init(data: Data, response: URLResponse) {
        self.data = data
        self.response = response
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        return (data, response)
    }
}
