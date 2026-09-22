import SwiftUI
import WebKit

public struct WebAuthModalView: NSViewRepresentable {
    let initialURL: URL
    let onAuthSuccess: (User) -> Void
    let onCancel: () -> Void
    
    public init(
        initialURL: URL,
        onAuthSuccess: @escaping (User) -> Void,
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
        
        // Ensure JavaScript and standard web capabilities are fully enabled
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "authBridge")
        
        // Injected monitor that checks for genuine authentication status
        let sessionObserverScript = """
        (function() {
            let hasReportedAuth = false;

            function checkAuthenticationState() {
                if (hasReportedAuth) return;

                fetch('/api/v5/state', { credentials: 'include' })
                    .then(response => {
                        if (!response.ok) return null;
                        return response.json();
                    })
                    .then(data => {
                        if (data && data.authenticated === true && data.user) {
                            hasReportedAuth = true;
                            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.authBridge) {
                                window.webkit.messageHandlers.authBridge.postMessage(JSON.stringify({
                                    type: 'authenticated',
                                    user: data.user
                                }));
                            }
                        }
                    })
                    .catch(() => {});
            }

            // Hook HTML5 History API for instant detection on React Router navigation
            const originalPushState = history.pushState;
            history.pushState = function() {
                originalPushState.apply(this, arguments);
                setTimeout(checkAuthenticationState, 200);
            };

            const originalReplaceState = history.replaceState;
            history.replaceState = function() {
                originalReplaceState.apply(this, arguments);
                setTimeout(checkAuthenticationState, 200);
            };

            window.addEventListener('popstate', () => {
                setTimeout(checkAuthenticationState, 200);
            });

            // Poll every 800ms while user completes Discord / 2FA / Passkey login
            setInterval(checkAuthenticationState, 800);

            // Check immediately on load
            checkAuthenticationState();
        })();
        """
        
        let userScript = WKUserScript(
            source: sessionObserverScript,
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
        private var isCompleted = false
        
        init(_ parent: WebAuthModalView) {
            self.parent = parent
        }
        
        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "authBridge",
                  let jsonString = message.body as? String,
                  let data = jsonString.data(using: .utf8) else {
                return
            }
            
            struct AuthBridgeMessage: Decodable {
                let type: String
                let user: User
            }
            
            if let parsed = try? JSONDecoder().decode(AuthBridgeMessage.self, from: data),
               parsed.type == "authenticated" {
                finalizeAuthentication(with: parsed.user, from: message.webView)
            }
        }
        
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Trigger check on page navigation completion as well
            webView.evaluateJavaScript("typeof checkAuthenticationState === 'function' ? checkAuthenticationState() : null", completionHandler: nil)
        }
        
        private func finalizeAuthentication(with user: User, from webView: WKWebView?) {
            guard !isCompleted else { return }
            isCompleted = true
            
            let cookieStore = webView?.configuration.websiteDataStore.httpCookieStore ?? WKWebsiteDataStore.default().httpCookieStore
            
            cookieStore.getAllCookies { cookies in
                for cookie in cookies {
                    HTTPCookieStorage.shared.setCookie(cookie)
                }
                DispatchQueue.main.async {
                    self.parent.onAuthSuccess(user)
                }
            }
        }
    }
}
