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

    func testAPIMetaDecodesProductionTimestamp() throws {
        let json = """
        {"apiVersion":"mobile-v1","generatedAt":"2026-07-09T10:17:53+00:00"}
        """.data(using: .utf8)!

        let meta = try JSONDecoder.slivki.decode(APIMeta.self, from: json)

        XCTAssertEqual(meta.apiVersion, "mobile-v1")
        XCTAssertNotNil(meta.generatedAt)
    }

    func testLiveBootstrapNetworkDecodes() async throws {
        let client = APIClient()
        let response: BootstrapResponse = try await client.get(.bootstrap)

        XCTAssertFalse(response.categories.isEmpty)
        XCTAssertFalse(response.featuredProducts.items.isEmpty)
    }

    func testLiveBootstrapFixtureDecodes() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/bootstrap-live.json")
        let data = try Data(contentsOf: url)

        let envelope = try JSONDecoder.slivki.decode(APIEnvelope<BootstrapResponse>.self, from: data)

        XCTAssertTrue(envelope.success)
        let bootstrap = try XCTUnwrap(envelope.data)
        XCTAssertFalse(bootstrap.categories.isEmpty)
        XCTAssertFalse(bootstrap.featuredProducts.items.isEmpty)
    }

    func testBootstrapResponseDecodesProductionEnvelope() throws {
        let json = """
        {
          "success": true,
          "meta": { "apiVersion": "mobile-v1", "generatedAt": "2026-07-09T10:17:53+00:00" },
          "data": {
            "site": { "name": "Сливки", "host": "https://slivki-shop.ru", "phone": "+7", "address": "addr", "hours": "8-20" },
            "app": { "iosBundleId": "com.app.slivki", "currency": "RUB", "locale": "ru_RU" },
            "navigation": {
              "categories": [
                {
                  "id": 13896,
                  "parentId": 1,
                  "title": "Готовая еда",
                  "slug": "gotovaja-eda",
                  "url": "https://slivki-shop.ru/shop/gotovaja-eda/",
                  "primaryImage": "https://slivki-shop.ru/upload/x.webp",
                  "children": []
                }
              ]
            },
            "checkout": {
              "paymentMethods": [
                { "id": "cash", "title": "Наличными", "supportsNativeCheckout": true }
              ]
            },
            "cart": {
              "id": "mobile-local",
              "items": [],
              "totals": { "itemsTotal": 0, "discountTotal": 0, "deliveryTotal": null, "payableTotal": 0 },
              "currency": "RUB",
              "updatedAt": "2026-07-09T10:17:10+00:00"
            },
            "featuredProducts": {
              "items": [
                {
                  "id": 5118,
                  "title": "Товар",
                  "slug": "promtovary/fairy",
                  "category": { "id": 13730, "title": "Кат", "slug": null },
                  "price": { "current": 195, "old": null, "currency": "RUB" },
                  "stock": { "count": 3, "available": true },
                  "type": "product",
                  "unit": "шт",
                  "primaryImage": "https://slivki-shop.ru/upload/item.webp",
                  "description": "desc"
                }
              ],
              "pagination": { "offset": 0, "limit": 20, "count": 1 }
            }
          }
        }
        """.data(using: .utf8)!

        let envelope = try JSONDecoder.slivki.decode(APIEnvelope<BootstrapResponse>.self, from: json)

        XCTAssertTrue(envelope.success)
        let bootstrap = try XCTUnwrap(envelope.data)
        XCTAssertEqual(bootstrap.site?.name, "Сливки")
        XCTAssertEqual(bootstrap.categories.count, 1)
        XCTAssertEqual(bootstrap.featuredProducts.items.count, 1)
        XCTAssertEqual(bootstrap.checkout?.paymentMethods.first?.id, "cash")
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

    func testClientPostsOrderDraftAndUnwrapsCreateEnvelope() async throws {
        let session = MockSession(
            data: """
            {
              "success": true,
              "meta": { "apiVersion": "mobile-v1", "generatedAt": "2026-07-08T13:17:08+00:00" },
              "data": {
                "order": {
                  "id": "mobile-draft-20260708",
                  "number": "MOBILE-DRAFT-20260708",
                  "status": "new",
                  "createdAt": "2026-07-08T13:17:08+00:00",
                  "totals": { "itemsTotal": 195, "discountTotal": 0, "deliveryTotal": null, "payableTotal": 195 },
                  "items": [
                    {
                      "id": "5118",
                      "product_id": "5118",
                      "title": "Средство для мытья посуды FAIRY",
                      "price": 195,
                      "quantity": 1
                    }
                  ],
                  "deliveryAddress": { "cityId": "lvov", "line1": "Тестовая 1" },
                  "contactPhone": "+79991234567",
                  "comment": "draft only",
                  "mobileApiMode": "draft_only"
                }
              }
            }
            """.data(using: .utf8)!,
            response: HTTPURLResponse(url: URL(string: "https://slivki-shop.ru")!, statusCode: 202, httpVersion: nil, headerFields: nil)!
        )
        let client = APIClient(session: session)
        let draft = CheckoutDraft(customerName: "Test", phone: "+79991234567", city: "Львовский", address: "Тестовая 1", comment: "draft only")
        let item = CartItem(
            id: "5118",
            productID: "5118",
            title: "Средство для мытья посуды FAIRY",
            price: Decimal(195),
            quantity: 1,
            selectedOptions: []
        )

        let response: OrderCreateResponse = try await client.post(.orders, body: CheckoutOrderDraft(draft: draft, items: [item], total: Decimal(195), paymentMethodID: "cash"))

        XCTAssertEqual(response.order.number, "MOBILE-DRAFT-20260708")
        XCTAssertEqual(response.order.total, Decimal(195))
        XCTAssertEqual(response.order.items.first?.productID, "5118")
        XCTAssertEqual(session.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(session.lastRequest?.url?.path, "/api/mobile/v1/orders")
        XCTAssertEqual(session.lastRequestBodyString?.contains("\"customer_name\":\"Test\""), true)
        XCTAssertEqual(session.lastRequestBodyString?.contains("\"product_id\":\"5118\""), true)
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
