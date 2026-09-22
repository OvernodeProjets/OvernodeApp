import SwiftUI
import WebKit

public struct WebAuthModalView: NSViewRepresentable {
    let initialURL: URL
    let autoTriggerPasskey: Bool
    let onAuthSuccess: () -> Void
    let onCancel: () -> Void
    
    public init(
        initialURL: URL,
        autoTriggerPasskey: Bool = false,
        onAuthSuccess: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.initialURL = initialURL
        self.autoTriggerPasskey = autoTriggerPasskey
        self.onAuthSuccess = onAuthSuccess
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
        
        // Custom user agent that supports standard modern web standards
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15 OvernodeNativeApp"
        
        let request = URLRequest(url: initialURL)
        webView.load(request)
        return webView
    }
    
    public func updateNSView(_ nsView: WKWebView, context: Context) {}
    
    public class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebAuthModalView
        private var hasTriggered = false
        private var passkeyAttempted = false
        
        init(_ parent: WebAuthModalView) {
            self.parent = parent
        }
        
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let url = webView.url else { return }
            
            // Check if login is already complete
            if checkAuthCompletion(url, in: webView) {
                return
            }
            
            // If requested, auto-trigger the passkey login button on the /auth page
            if parent.autoTriggerPasskey && !passkeyAttempted && (url.path == "/auth" || url.path.hasPrefix("/auth")) {
                passkeyAttempted = true
                
                let triggerJS = """
                (function() {
                    const checkAndClick = () => {
                        const buttons = Array.from(document.querySelectorAll('button'));
                        const passkeyBtn = buttons.find(b => {
                            const text = (b.innerText || '').toLowerCase();
                            return text.includes('passkey') || text.includes('clé');
                        });
                        if (passkeyBtn && !passkeyBtn.disabled) {
                            passkeyBtn.click();
                            return true;
                        }
                        return false;
                    };
                    
                    if (!checkAndClick()) {
                        setTimeout(checkAndClick, 500);
                        setTimeout(checkAndClick, 1500);
                    }
                })();
                """
                webView.evaluateJavaScript(triggerJS, completionHandler: nil)
            }
        }
        
        @MainActor
        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                if checkAuthCompletion(url, in: webView) {
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
        
        @discardableResult
        private func checkAuthCompletion(_ url: URL, in webView: WKWebView) -> Bool {
            let path = url.path
            
            // Check if user reached dashboard (login successful via Discord, 2FA, or Passkey)
            if path.contains("/dashboard") || (path == "/" && url.host?.contains("overnode.fr") == true) {
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
