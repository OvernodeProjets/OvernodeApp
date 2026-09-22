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
        
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15 OvernodeNativeApp"
        
        context.coordinator.attach(to: webView)
        
        let request = URLRequest(url: initialURL)
        webView.load(request)
        return webView
    }
    
    public func updateNSView(_ nsView: WKWebView, context: Context) {}
    
    @MainActor
    public class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebAuthModalView
        private weak var webView: WKWebView?
        private var isCompleted = false
        
        init(_ parent: WebAuthModalView) {
            self.parent = parent
        }
        
        func attach(to webView: WKWebView) {
            self.webView = webView
            scheduleStateCheck()
        }
        
        private func scheduleStateCheck() {
            guard !isCompleted else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.evaluateCurrentState()
                self?.scheduleStateCheck()
            }
        }
        
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            evaluateCurrentState()
        }
        
        private func evaluateCurrentState() {
            guard !isCompleted, let webView = self.webView else { return }
            
            // Check native webView URL
            if let url = webView.url, isDashboardURL(url) {
                triggerSuccess(from: webView)
                return
            }
            
            // Query window.location.pathname via JS
            webView.evaluateJavaScript("window.location.pathname") { [weak self] result, _ in
                Task { @MainActor in
                    guard let self = self, !self.isCompleted else { return }
                    if let path = result as? String, path.contains("dashboard") {
                        self.triggerSuccess(from: webView)
                    }
                }
            }
        }
        
        private func isDashboardURL(_ url: URL) -> Bool {
            let path = url.path.lowercased()
            return path.contains("dashboard")
        }
        
        private func triggerSuccess(from webView: WKWebView) {
            guard !isCompleted else { return }
            isCompleted = true
            
            let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
            
            // Sync all cookies to URLSession HTTPCookieStorage
            cookieStore.getAllCookies { [weak self] cookies in
                guard let self = self else { return }
                
                for cookie in cookies {
                    HTTPCookieStorage.shared.setCookie(cookie)
                }
                
                // Fetch authenticated user profile directly from session
                let fetchUserJS = """
                fetch('/api/v5/state', { credentials: 'include' })
                    .then(r => r.json())
                    .then(d => JSON.stringify(d.user || {}))
                    .catch(() => '{}')
                """
                
                webView.evaluateJavaScript(fetchUserJS) { userJsonResult, _ in
                    var parsedUser = User(id: 1, username: "Overnode User", email: "user@overnode.fr")
                    
                    if let jsonStr = userJsonResult as? String,
                       let data = jsonStr.data(using: .utf8),
                       let user = try? JSONDecoder().decode(User.self, from: data) {
                        parsedUser = user
                    }
                    
                    DispatchQueue.main.async {
                        self.parent.onAuthSuccess(parsedUser)
                    }
                }
            }
        }
    }
}
