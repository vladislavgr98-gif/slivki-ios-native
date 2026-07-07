import Foundation
import XCTest
@testable import Slivki

final class APIClientTests: XCTestCase {
    func testProductDecodesFromLiveMobileAPIShape() throws {
        let json = """
        {
          "id": 5118,
          "title": "Средство для мытья посуды FAIRY",
          "slug": "promtovary/fairy",
          "category": { "id": 13730, "title": "Средство для мытья посуды", "slug": null },
          "primaryImage": "https://slivki-shop.ru/upload/item.webp",
          "price": { "current": 195, "old": null, "currency": "RUB" },
          "stock": { "count": 3, "available": true },
          "badges": ["new"]
        }
        """.data(using: .utf8)!

        let product = try JSONDecoder.slivki.decode(Product.self, from: json)

        XCTAssertEqual(product.id, "5118")
        XCTAssertEqual(product.title, "Средство для мытья посуды FAIRY")
        XCTAssertEqual(product.categoryID, "13730")
        XCTAssertEqual(product.imageURL?.absoluteString, "https://slivki-shop.ru/upload/item.webp")
        XCTAssertEqual(product.price, Decimal(195))
        XCTAssertEqual(product.currency, "RUB")
        XCTAssertTrue(product.isAvailable)
        XCTAssertEqual(product.badges, ["new"])
    }

    func testProductDecodesWhenLivePriceIsNull() throws {
        let json = """
        {
          "id": 5119,
          "title": "Товар без цены",
          "price": { "current": null, "old": null, "currency": "RUB" },
          "stock": { "count": 3, "available": true }
        }
        """.data(using: .utf8)!

        let product = try JSONDecoder.slivki.decode(Product.self, from: json)

        XCTAssertEqual(product.id, "5119")
        XCTAssertFalse(product.hasPrice)
        XCTAssertFalse(product.canBeAddedToCart)
    }

    func testProductListResponseDecodesFromLiveDataShape() throws {
        let json = """
        {
          "items": [
            {
              "id": 5118,
              "title": "Средство для мытья посуды FAIRY",
              "price": { "current": 195, "old": null, "currency": "RUB" },
              "stock": { "count": 0, "available": false }
            }
          ],
          "pagination": {
            "offset": 0,
            "limit": 20,
            "count": 1
          }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.slivki.decode(ProductListResponse.self, from: json)

        XCTAssertEqual(response.items.count, 1)
        XCTAssertEqual(response.pagination.limit, 20)
        XCTAssertEqual(response.pagination.count, 1)
    }

    func testCatalogResponseDecodesFromLiveCategoryShape() throws {
        let json = """
        {
          "categories": [
            {
              "id": 13896,
              "parentId": 1,
              "title": "Готовая еда",
              "primaryImage": "https://slivki-shop.ru/upload/category.webp",
              "children": []
            }
          ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.slivki.decode(CatalogResponse.self, from: json)

        XCTAssertEqual(response.categories[0].id, "13896")
        XCTAssertEqual(response.categories[0].parentID, "1")
        XCTAssertEqual(response.categories[0].imageURL?.absoluteString, "https://slivki-shop.ru/upload/category.webp")
        XCTAssertTrue(response.categories[0].children.isEmpty)
    }

    func testBootstrapResponseDecodesFromLiveShape() throws {
        let json = """
        {
          "site": { "name": "Сливки", "host": "https://slivki-shop.ru" },
          "app": { "iosBundleId": "com.app.slivki", "currency": "RUB", "locale": "ru_RU" },
          "navigation": { "categories": [] },
          "featuredProducts": {
            "items": [],
            "pagination": { "offset": 0, "limit": 3, "count": 0 }
          }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.slivki.decode(BootstrapResponse.self, from: json)

        XCTAssertEqual(response.site?.name, "Сливки")
        XCTAssertEqual(response.app?.iosBundleID, "com.app.slivki")
        XCTAssertEqual(response.categories, [])
        XCTAssertEqual(response.featuredProducts.items, [])
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

    func testClientBuildsProductsQueryAndUnwrapsEnvelope() async throws {
        let session = MockSession(
            data: """
            {
              "success": true,
              "meta": { "apiVersion": "mobile-v1", "generatedAt": "2026-07-07T07:41:19+00:00" },
              "data": {
                "items": [],
                "pagination": { "offset": 20, "limit": 20, "count": 0 }
              }
            }
            """.data(using: .utf8)!,
            response: HTTPURLResponse(url: URL(string: "https://slivki-shop.ru")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        )
        let client = APIClient(session: session, accessToken: { "token" })
        let response: ProductListResponse = try await client.get(.products(categoryID: "13730", query: "fairy", sort: .popular, page: 2, perPage: 20))

        XCTAssertEqual(response.pagination.offset, 20)
        XCTAssertEqual(session.lastRequest?.url?.path, "/api/mobile/v1/products")
        XCTAssertEqual(session.lastRequest?.url?.query?.contains("category_id=13730"), true)
        XCTAssertEqual(session.lastRequest?.url?.query?.contains("q=fairy"), true)
        XCTAssertEqual(session.lastRequest?.url?.query?.contains("sort=popular"), true)
        XCTAssertEqual(session.lastRequest?.url?.query?.contains("offset=20"), true)
        XCTAssertEqual(session.lastRequest?.url?.query?.contains("limit=20"), true)
        XCTAssertEqual(session.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer token")
    }

    func testClientThrowsAPIErrorFromEnvelope() async throws {
        let session = MockSession(
            data: """
            {
              "success": false,
              "error": { "code": "not_found", "message": "Endpoint not found" }
            }
            """.data(using: .utf8)!,
            response: HTTPURLResponse(url: URL(string: "https://slivki-shop.ru")!, statusCode: 404, httpVersion: nil, headerFields: nil)!
        )
        let client = APIClient(session: session)

        do {
            let _: CatalogResponse = try await client.get(.catalog)
            XCTFail("Expected API error")
        } catch let APIError.server(code, message) {
            XCTAssertEqual(code, "not_found")
            XCTAssertEqual(message, "Endpoint not found")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testClientUnwrapsProductDetailEnvelope() async throws {
        let session = MockSession(
            data: """
            {
              "success": true,
              "meta": { "apiVersion": "mobile-v1", "generatedAt": "2026-07-07T07:41:19+00:00" },
              "data": {
                "product": {
                  "id": 5118,
                  "title": "Средство для мытья посуды FAIRY",
                  "price": { "current": 195, "old": null, "currency": "RUB" },
                  "stock": { "count": 3, "available": true }
                }
              }
            }
            """.data(using: .utf8)!,
            response: HTTPURLResponse(url: URL(string: "https://slivki-shop.ru")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        )
        let client = APIClient(session: session)
        let response: ProductDetailResponse = try await client.get(.product(id: "5118"))

        XCTAssertEqual(response.product.id, "5118")
        XCTAssertEqual(response.product.price, Decimal(195))
        XCTAssertEqual(session.lastRequest?.url?.path, "/api/mobile/v1/products/5118")
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
