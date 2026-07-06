import SwiftUI

public enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(String)
}

public struct LoadStateView<Value, Content: View>: View {
    let state: LoadState<Value>
    let retry: () -> Void
    @ViewBuilder let content: (Value) -> Content

    public init(
        state: LoadState<Value>,
        retry: @escaping () -> Void,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.state = state
        self.retry = retry
        self.content = content
    }

    public var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let value):
            content(value)
        case .failed(let message):
            VStack(spacing: SlivkiSpacing.sm) {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(SlivkiColor.textSecondary)
                    .multilineTextAlignment(.center)

                Button("Повторить", action: retry)
                    .buttonStyle(.borderedProminent)
            }
            .padding(SlivkiSpacing.md)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
