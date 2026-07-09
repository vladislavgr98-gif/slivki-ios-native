import SwiftUI

public struct QuantityStepper: View {
    @Binding var quantity: Int

    public init(quantity: Binding<Int>) {
        self._quantity = quantity
    }

    public var body: some View {
        HStack(spacing: 0) {
            Button {
                quantity = max(0, quantity - 1)
            } label: {
                Image(systemName: "minus")
                    .font(.caption.weight(.bold))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .foregroundStyle(SlivkiColor.brandDark)

            Text("\(quantity)")
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(SlivkiColor.textPrimary)
                .frame(width: 38, height: 34)

            Button {
                quantity += 1
            } label: {
                Image(systemName: "plus")
                    .font(.caption.weight(.bold))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(SlivkiColor.brandDark)
        }
        .background(SlivkiColor.brandBright.opacity(0.14))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(SlivkiColor.brandDark.opacity(0.18), lineWidth: 1)
        )
    }
}

public struct CompactQuantityStepper: View {
    @Binding var quantity: Int

    public init(quantity: Binding<Int>) {
        self._quantity = quantity
    }

    public var body: some View {
        HStack(spacing: 0) {
            Button {
                quantity = max(0, quantity - 1)
            } label: {
                Image(systemName: "minus")
                    .font(.caption2.weight(.bold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundStyle(SlivkiColor.brandDark)

            Text("\(quantity)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(SlivkiColor.textPrimary)
                .frame(width: 30, height: 28)

            Button {
                quantity += 1
            } label: {
                Image(systemName: "plus")
                    .font(.caption2.weight(.bold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(SlivkiColor.brandDark)
            .clipShape(Circle())
        }
        .padding(.horizontal, 2)
        .frame(height: 36)
        .background(SlivkiColor.brandBright.opacity(0.14))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(SlivkiColor.brandDark.opacity(0.18), lineWidth: 1)
        )
    }
}
