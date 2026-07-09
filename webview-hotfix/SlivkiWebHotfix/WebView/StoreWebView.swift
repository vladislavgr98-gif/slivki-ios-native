import SwiftUI
import UIKit
import WebKit

struct StoreWebView: UIViewRepresentable {
    @ObservedObject var session: WebViewSession

    func makeCoordinator() -> Coordinator {
        Coordinator(session: session)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        if #available(iOS 14.0, *) {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            configuration.preferences.javaScriptEnabled = true
        }
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic

        session.bind(webView: webView)
        context.coordinator.webView = webView

        webView.load(URLRequest(url: WebViewSession.startURL))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.webView = webView
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let session: WebViewSession
        weak var webView: WKWebView?

        init(session: WebViewSession) {
            self.session = session
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            Task { @MainActor in
                session.updateLoading(true)
                session.presentError(nil)
            }
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            Task { @MainActor in
                session.presentError(nil)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                session.updateLoading(false)
                session.updateCanGoBack(webView.canGoBack)
                session.presentError(nil)
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in
                session.updateLoading(false)
                session.updateCanGoBack(webView.canGoBack)
                handleNavigationFailure(error, webView: webView)
            }
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            Task { @MainActor in
                session.updateLoading(false)
                session.updateCanGoBack(webView.canGoBack)
                handleNavigationFailure(error, webView: webView)
            }
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            webView.reload()
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            if navigationAction.targetFrame == nil {
                webView.load(URLRequest(url: url))
                decisionHandler(.cancel)
                return
            }

            if shouldOpenExternally(url) {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        @MainActor
        private func handleNavigationFailure(_ error: Error, webView: WKWebView) {
            guard !Self.shouldIgnore(error) else {
                return
            }

            if webView.url != nil, webView.canGoBack {
                return
            }

            session.presentError(WebViewUserError())
        }

        private func shouldOpenExternally(_ url: URL) -> Bool {
            guard let host = url.host?.lowercased() else {
                return false
            }

            if host == "slivki-shop.ru" || host.hasSuffix(".slivki-shop.ru") {
                return false
            }

            let scheme = url.scheme?.lowercased() ?? ""
            return scheme == "http" || scheme == "https" || scheme == "tel" || scheme == "mailto"
        }

        static func shouldIgnore(_ error: Error) -> Bool {
            let nsError = error as NSError

            if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
                return true
            }

            if nsError.domain == "WebKitErrorDomain", nsError.code == 102 {
                return true
            }

            if nsError.domain == "WebKitErrorDomain", nsError.code == 204 {
                return true
            }

            return false
        }
    }
}
