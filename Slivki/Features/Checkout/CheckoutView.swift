import SwiftUI

public struct CheckoutView: View {
    @EnvironmentObject private var cartStore: CartStore
    @State private var customerName = ""
    @State private var phone = ""
    @State private var city = Fixtures.city.title
    @State private var address = ""
    @State private var isDraftPrepared = false

    public init() {}

    public var body: some View {
        let draft = CheckoutDraft(customerName: customerName, phone: phone, city: city, address: address)

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

                Button {
                    isDraftPrepared = true
                } label: {
                    Label("Подтвердить заказ", systemImage: "checkmark.circle")
                }
                .disabled(cartStore.isEmpty || !draft.isValid)
            } footer: {
                if let message = draft.validationErrors.first?.message {
                    Text(message)
                }
            }
        }
        .navigationTitle("Оформление")
        .alert("Заказ подготовлен", isPresented: $isDraftPrepared) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Отправка заказа будет подключена после API orders.")
        }
    }
}
