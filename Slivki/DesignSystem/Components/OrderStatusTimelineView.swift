import SwiftUI

struct OrderStatusTimelineView: View {
    let status: OrderStatus

    var body: some View {
        SlivkiCard {
            VStack(alignment: .leading, spacing: SlivkiSpacing.md) {
                Text("Статус заказа")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(SlivkiColor.textPrimary)

                if status == .cancelled {
                    Label("Заказ отменен", systemImage: "xmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SlivkiColor.warning)
                } else {
                    VStack(alignment: .leading, spacing: SlivkiSpacing.sm) {
                        ForEach(Array(status.timelineSteps.enumerated()), id: \.offset) { index, step in
                            timelineRow(step: step, index: index)
                        }
                    }
                }
            }
        }
    }

    private func timelineRow(step: OrderStatus, index: Int) -> some View {
        let currentIndex = status.timelineIndex ?? -1
        let isCompleted = index < currentIndex
        let isCurrent = index == currentIndex || (status == .paid && step == .confirmed)

        return HStack(spacing: SlivkiSpacing.sm) {
            ZStack {
                Circle()
                    .fill(isCompleted || isCurrent ? SlivkiColor.brandBright : SlivkiColor.border.opacity(0.5))
                    .frame(width: 12, height: 12)
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(SlivkiColor.brandDark)
                }
            }

            Text(step.title)
                .font(.subheadline.weight(isCurrent ? .bold : .medium))
                .foregroundStyle(isCurrent ? SlivkiColor.textPrimary : SlivkiColor.textSecondary)

            Spacer()

            if isCurrent {
                Text("Сейчас")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SlivkiColor.brandDark)
            }
        }
    }
}
