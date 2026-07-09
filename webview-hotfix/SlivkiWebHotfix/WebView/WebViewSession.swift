import Combine
import Foundation
import WebKit

@MainActor
final class WebViewSession: ObservableObject {
    static let startURL = URL(string: "https://slivki-shop.ru/")!

    @Published private(set) var isLoading = false
    @Published private(set) var error: WebViewUserError?
    @Published private(set) var canGoBack = false

    weak var webView: WKWebView?

    init() {
        Task {
            await Self.clearCacheIfNeededForCurrentVersion()
        }
    }

    func bind(webView: WKWebView) {
        self.webView = webView
        canGoBack = webView.canGoBack
    }

    func updateLoading(_ loading: Bool) {
        isLoading = loading
        if loading {
            error = nil
        }
    }

    func updateCanGoBack(_ value: Bool) {
        canGoBack = value
    }

    func presentError(_ error: WebViewUserError?) {
        self.error = error
    }

    func retry() {
        error = nil
        if let webView, webView.url != nil {
            webView.reload()
        } else {
            webView?.load(URLRequest(url: Self.startURL))
        }
    }

    func goBack() {
        error = nil
        webView?.goBack()
    }

    private static func clearCacheIfNeededForCurrentVersion() async {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let key = "slivki.webhotfix.cacheClearedForVersion"
        guard UserDefaults.standard.string(forKey: key) != version else {
            return
        }

        await withCheckedContinuation { continuation in
            let store = WKWebsiteDataStore.default()
            let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
            store.fetchDataRecords(ofTypes: dataTypes) { records in
                store.removeData(ofTypes: dataTypes, for: records) {
                    continuation.resume()
                }
            }
        }
        UserDefaults.standard.set(version, forKey: key)
    }
}

struct WebViewUserError: Equatable {
    let title: String
    let message: String

    init(title: String = "Что-то пошло не так", message: String = "Не удалось загрузить страницу. Проверьте интернет и повторите.") {
        self.title = title
        self.message = message
    }
}
