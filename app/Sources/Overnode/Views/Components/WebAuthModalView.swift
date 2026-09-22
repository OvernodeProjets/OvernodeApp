import SwiftUI
import WebKit

public struct WebAuthModalView: NSViewRepresentable {
    let initialURL: URL
    let onAuthSuccess: () -> Void
    let onCancel: () -> Void
    
    public init(
        initialURL: URL,
        onAuthSuccess: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.initialURL = initialURL
        self.onAuthSuccess = onAuthSuccess
        self.onCancel = onCancel
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "authBridge")
        
        // Inject script to detect client-side SPA navigation (React Router) to /dashboard
        let spaMonitorScript = """
        (function() {
            function notifyDashboardIfReached() {
                if (window.location.pathname.includes('/dashboard') || 
                    (window.location.pathname === '/' && window.location.host.includes('overnode.fr') && !document.querySelector('form'))) {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.authBridge) {
                        window.webkit.messageHandlers.authBridge.postMessage('auth_success');
                    }
                }
            }

            // Hook HTML5 History API used by React Router
            const originalPushState = history.pushState;
            history.pushState = function() {
                originalPushState.apply(this, arguments);
                notifyDashboardIfReached();
            };

            const originalReplaceState = history.replaceState;
            history.replaceState = function() {
                originalReplaceState.apply(this, arguments);
                notifyDashboardIfReached();
            };

            window.addEventListener('popstate', notifyDashboardIfReached);

            // Periodic fallback check in case of internal transitions
            setInterval(notifyDashboardIfReached, 300);
            
            // Check immediately on load
            notifyDashboardIfReached();
        })();
        """
        
        let userScript = WKUserScript(
            source: spaMonitorScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        userContentController.addUserScript(userScript)
        configuration.userContentController = userContentController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15 OvernodeNativeApp"
        
        let request = URLRequest(url: initialURL)
        webView.load(request)
        return webView
    }
    
    public func updateNSView(_ nsView: WKWebView, context: Context) {}
    
    public class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebAuthModalView
        private var hasTriggered = false
        
        init(_ parent: WebAuthModalView) {
            self.parent = parent
        }
        
        // Handle SPA postMessage from injected script
        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "authBridge", let body = message.body as? String, body == "auth_success" {
                handleAuthSuccess(from: message.webView)
            }
        }
        
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let url = webView.url else { return }
            if url.path.contains("/dashboard") || (url.path == "/" && url.host?.contains("overnode.fr") == true) {
                handleAuthSuccess(from: webView)
            }
        }
        
        @MainActor
        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                if url.path.contains("/dashboard") {
                    handleAuthSuccess(from: webView)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
        
        private func handleAuthSuccess(from webView: WKWebView?) {
            guard !hasTriggered else { return }
            hasTriggered = true
            
            let store = webView?.configuration.websiteDataStore.httpCookieStore ?? WKWebsiteDataStore.default().httpCookieStore
            
            store.getAllCookies { cookies in
                for cookie in cookies {
                    HTTPCookieStorage.shared.setCookie(cookie)
                }
                DispatchQueue.main.async {
                    self.parent.onAuthSuccess()
                }
            }
        }
    }
}
