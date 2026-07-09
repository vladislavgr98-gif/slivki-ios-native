import XCTest
@testable import Slivki

final class PaymentMethodTests: XCTestCase {
    func testCheckoutOrderDraftEncodesPaymentMethod() throws {
        let draft = CheckoutDraft(
            customerName: "Иван",
            phone: "+79990001122",
            city: "Львовское",
            address: "ул. Советская, 46"
        )
        let item = CartItem(
            id: "cart-1",
            productID: "1",
            title: "Молоко",
            imageURL: nil,
            price: 100,
            quantity: 1,
            selectedOptions: []
        )
        let orderDraft = CheckoutOrderDraft(
            draft: draft,
            items: [item],
            total: 100,
            paymentMethodID: "card_on_delivery"
        )

        let data = try JSONEncoder.slivki.encode(orderDraft)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["payment_method"] as? String, "card_on_delivery")
    }

    func testBootstrapCheckoutOptionsDecode() throws {
        let json = """
        {
          "checkout": {
            "paymentMethods": [
              { "id": "cash", "title": "Наличными", "supportsNativeCheckout": true },
              { "id": "card_on_delivery", "title": "Картой/QR", "supportsNativeCheckout": true }
            ]
          }
        }
        """.data(using: .utf8)!

        struct Wrapper: Decodable {
            let checkout: CheckoutOptions
        }

        let wrapper = try JSONDecoder.slivki.decode(Wrapper.self, from: json)

        XCTAssertEqual(wrapper.checkout.paymentMethods.count, 2)
        XCTAssertEqual(wrapper.checkout.paymentMethods[1].id, "card_on_delivery")
        XCTAssertTrue(wrapper.checkout.paymentMethods[1].supportsNativeCheckout)
    }
}
