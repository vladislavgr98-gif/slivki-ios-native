import SwiftUI

struct WebViewErrorOverlay: View {
    let error: WebViewUserError
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 42))
                .foregroundColor(.secondary)

            Text(error.title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)

            Text(error.message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: onRetry) {
                Text("Повторить")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
