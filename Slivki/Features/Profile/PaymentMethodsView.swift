import SwiftUI

public struct PaymentMethodsView: View {
    @EnvironmentObject private var bootstrapStore: BootstrapStore
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SlivkiSpacing.md) {
                    SlivkiSectionTitle(
                        "Оплата при получении",
                        subtitle: "Оплатить можно только при доставке или самовывозе"
                    )

                    ForEach(bootstrapStore.checkoutPaymentMethods) { method in
                        SlivkiCard {
                            HStack(alignment: .top, spacing: SlivkiSpacing.md) {
                                Image(systemName: icon(for: method.id))
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(SlivkiColor.brandDark)
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(method.title)
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(SlivkiColor.textPrimary)
                                    Text(subtitle(for: method))
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(SlivkiColor.textSecondary)
                                }
                            }
                        }
                    }

                    Text("Онлайн-оплата в приложении не подключена. Заказ можно оплатить курьеру наличными или картой/QR при получении.")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(SlivkiColor.textSecondary)
                }
                .padding(SlivkiSpacing.md)
            }
            .background(SlivkiColor.groupedBackground)
            .navigationTitle("Оплата")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func icon(for methodID: String) -> String {
        switch methodID {
        case "cash":
            "banknote"
        case "card_on_delivery":
            "creditcard"
        default:
            "wallet.pass"
        }
    }

    private func subtitle(for method: PaymentMethodOption) -> String {
        switch method.id {
        case "cash":
            "Наличными курьеру"
        case "card_on_delivery":
            "Картой или QR при получении"
        default:
            "При получении заказа"
        }
    }
}
