import SwiftUI

public struct OrdersView: View {
    public init() {}

    public var body: some View {
        EmptyStateView("Заказов пока нет", systemImage: "list.clipboard")
            .navigationTitle("Заказы")
    }
}

public struct OrderDetailView: View {
    let orderID: String

    public init(orderID: String) {
        self.orderID = orderID
    }

    public var body: some View {
        EmptyStateView("Заказ \(orderID)", systemImage: "shippingbox", message: "Детали появятся после подключения мобильного API.")
            .navigationTitle("Заказ")
    }
}
