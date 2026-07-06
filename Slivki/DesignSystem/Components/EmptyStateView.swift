import SwiftUI

public struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let message: String?

    public init(_ title: String, systemImage: String, message: String? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.message = message
    }

    public var body: some View {
        VStack(spacing: SlivkiSpacing.sm) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(SlivkiColor.textSecondary)

            Text(title)
                .font(.headline)
                .foregroundStyle(SlivkiColor.textPrimary)
                .multilineTextAlignment(.center)

            if let message {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(SlivkiColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(SlivkiSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
