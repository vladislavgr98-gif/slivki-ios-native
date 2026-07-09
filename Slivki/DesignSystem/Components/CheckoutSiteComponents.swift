import SwiftUI

struct CheckoutMobileCard<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder var content: () -> Content

    init(_ title: String, subtitle: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    var body: some View {
        SlivkiCard {
            VStack(alignment: .leading, spacing: SlivkiSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(SlivkiColor.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(SlivkiColor.textSecondary)
                    }
                }
                content()
            }
        }
    }
}

struct CheckoutSettingRow: View {
    let label: String
    let value: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: SlivkiSpacing.md) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(SlivkiColor.brandDark)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SlivkiColor.textSecondary)
                    Text(value)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(SlivkiColor.textPrimary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SlivkiColor.textSecondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct CheckoutFulfillmentOption: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(SlivkiColor.brandDark)
                    }
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(SlivkiColor.textPrimary)
                }
                Text(subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SlivkiColor.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(SlivkiSpacing.md)
            .background(isSelected ? SlivkiColor.brandBright.opacity(0.14) : SlivkiColor.groupedBackground)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? SlivkiColor.brandDark : SlivkiColor.border.opacity(0.7), lineWidth: isSelected ? 2 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct CheckoutPaymentOption: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: SlivkiSpacing.sm) {
                HStack {
                    Image(systemName: systemImage)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(SlivkiColor.brandDark)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(SlivkiColor.brandDark)
                    }
                }
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(SlivkiColor.textPrimary)
                Text(subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SlivkiColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(SlivkiSpacing.md)
            .background(isSelected ? SlivkiColor.brandBright.opacity(0.14) : SlivkiColor.groupedBackground)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? SlivkiColor.brandDark : SlivkiColor.border.opacity(0.7), lineWidth: isSelected ? 2 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct CheckoutSummaryRow: View {
    let title: String
    let value: String
    var isTotal = false

    var body: some View {
        HStack {
            Text(title)
                .font(isTotal ? .headline.weight(.bold) : .subheadline.weight(.medium))
                .foregroundStyle(SlivkiColor.textPrimary)
            Spacer()
            Text(value)
                .font(isTotal ? .headline.weight(.bold) : .subheadline.weight(.semibold))
                .foregroundStyle(SlivkiColor.textPrimary)
        }
    }
}
