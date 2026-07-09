import SwiftUI
#if canImport(WebKit)
import WebKit
#endif

public struct LegalWebView: View {
    let path: String

    public init(path: String) {
        self.path = path
    }

    public var body: some View {
        Group {
            #if os(iOS)
            if let url = documentURL {
                SlivkiWebView(url: url)
            } else {
                placeholder
            }
            #else
            placeholder
            #endif
        }
        .navigationTitle(title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var placeholder: some View {
        VStack(spacing: SlivkiSpacing.md) {
            Image(systemName: "doc.text")
                .font(.largeTitle)
                .foregroundStyle(SlivkiColor.brand)

            Text(title)
                .font(.title3.weight(.semibold))

            Text("Не удалось открыть страницу.")
                .font(.callout)
                .foregroundStyle(SlivkiColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(SlivkiSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SlivkiColor.groupedBackground)
    }

    private var title: String {
        switch path {
        case "/pages/rules.html":
            "Правила"
        case "/pages/agreement.html":
            "Соглашение"
        default:
            "Документ"
        }
    }

    private var documentURL: URL? {
        URL(string: "https://slivki-shop.ru\(path)")
    }
}

#if os(iOS)
private struct SlivkiWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.lastLoadedURL != url else {
            return
        }
        context.coordinator.lastLoadedURL = url
        webView.load(URLRequest(url: url))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var lastLoadedURL: URL?
    }
}
#endif
