import SwiftUI

public struct QuantityStepper: View {
    @Binding var quantity: Int

    public init(quantity: Binding<Int>) {
        self._quantity = quantity
    }

    public var body: some View {
        HStack(spacing: SlivkiSpacing.sm) {
            Button {
                quantity = max(0, quantity - 1)
            } label: {
                Image(systemName: "minus")
            }
            .buttonStyle(.bordered)

            Text("\(quantity)")
                .font(.headline.monospacedDigit())
                .frame(minWidth: 36)

            Button {
                quantity += 1
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
