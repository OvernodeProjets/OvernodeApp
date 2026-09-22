import SwiftUI
import WebKit

public struct WebAuthModalView: NSViewRepresentable {
    let initialURL: URL
    let onAuthSuccess: () -> Void
    let onAuthTwoFactor: () -> Void
    let onCancel: () -> Void
    
    public init(
        initialURL: URL,
        onAuthSuccess: @escaping () -> Void,
        onAuthTwoFactor: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.initialURL = initialURL
        self.onAuthSuccess = onAuthSuccess
        self.onAuthTwoFactor = onAuthTwoFactor
        self.onCancel = onCancel
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15 OvernodeNativeApp"
        
        let request = URLRequest(url: initialURL)
        webView.load(request)
        return webView
    }
    
    public func updateNSView(_ nsView: WKWebView, context: Context) {}
    
    public class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebAuthModalView
        private var hasTriggered = false
        
        init(_ parent: WebAuthModalView) {
            self.parent = parent
        }
        
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let url = webView.url else { return }
            checkAuthURL(url, in: webView)
        }
        
        @MainActor
        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                if checkAuthURL(url, in: webView) {
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
        
        @discardableResult
        private func checkAuthURL(_ url: URL, in webView: WKWebView) -> Bool {
            let path = url.path
            
            // Check if 2FA verification page reached
            if path.contains("/auth/2fa") {
                if !hasTriggered {
                    hasTriggered = true
                    syncCookies(from: webView) {
                        DispatchQueue.main.async {
                            self.parent.onAuthTwoFactor()
                        }
                    }
                    return true
                }
            }
            
            // Check if user reached dashboard (login successful)
            if path.contains("/dashboard") || path == "/" && url.host == "console.overnode.fr" {
                if !hasTriggered {
                    hasTriggered = true
                    syncCookies(from: webView) {
                        DispatchQueue.main.async {
                            self.parent.onAuthSuccess()
                        }
                    }
                    return true
                }
            }
            
            return false
        }
        
        private func syncCookies(from webView: WKWebView, completion: @escaping () -> Void) {
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                for cookie in cookies {
                    HTTPCookieStorage.shared.setCookie(cookie)
                }
                completion()
            }
        }
    }
}
