import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var session: WebViewSession

    var body: some View {
        ZStack(alignment: .top) {
            StoreWebView(session: session)
                .edgesIgnoringSafeArea(.bottom)

            if session.isLoading {
                Text("Загрузка…")
                    .font(.footnote)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.top, 8)
            }

            if let error = session.error {
                WebViewErrorOverlay(error: error) {
                    session.retry()
                }
            }
        }
    }
}
