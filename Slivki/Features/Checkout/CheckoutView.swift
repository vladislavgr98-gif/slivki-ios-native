import SwiftUI

public struct CheckoutView: View {
    @EnvironmentObject private var cartStore: CartStore
    @State private var customerName = ""
    @State private var phone = ""
    @State private var city = Fixtures.city.title
    @State private var address = ""

    public init() {}

    public var body: some View {
        Form {
            Section("Контакты") {
                TextField("Имя", text: $customerName)
                TextField("Телефон", text: $phone)
                    .slivkiKeyboardType(.phonePad)
            }

            Section("Доставка") {
                TextField("Город", text: $city)
                TextField("Адрес", text: $address)
            }

            Section("Заказ") {
                HStack {
                    Text("Итого")
                    Spacer()
                    Text(SlivkiMoney.format(cartStore.total))
                }

                Button("Подтвердить заказ") {}
                    .disabled(cartStore.isEmpty)
            }
        }
        .navigationTitle("Оформление")
    }
}
