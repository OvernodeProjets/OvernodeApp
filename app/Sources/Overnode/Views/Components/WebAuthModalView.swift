import SwiftUI
import WebKit

public struct WebAuthModalView: NSViewRepresentable {
    let initialURL: URL
    let onAuthSuccess: (User, ResourcesResponse?) -> Void
    let onCancel: () -> Void
    
    public init(
        initialURL: URL,
        onAuthSuccess: @escaping (User, ResourcesResponse?) -> Void,
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
                
                // Fetch full authenticated init payload (user, email, coins) and resources directly
                let fetchRichDataJS = """
                Promise.all([
                    fetch('/api/v5/init', { credentials: 'include' }).then(r => r.ok ? r.json() : null).catch(() => null),
                    fetch('/api/v5/resources', { credentials: 'include' }).then(r => r.ok ? r.json() : null).catch(() => null)
                ]).then(([initData, resData]) => {
                    return JSON.stringify({
                        init: initData,
                        resources: resData
                    });
                }).catch(() => '{}');
                """
                
                webView.evaluateJavaScript(fetchRichDataJS) { result, _ in
                    var parsedUser = User(id: 1, username: "Overnode User", email: "user@overnode.fr", coins: 0)
                    var parsedResources: ResourcesResponse? = nil
                    
                    if let jsonStr = result as? String,
                       let data = jsonStr.data(using: .utf8),
                       let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        
                        // Parse Init / User data
                        if let initObj = obj["init"] as? [String: Any],
                           let userObj = initObj["user"] as? [String: Any] {
                            let id = userObj["id"] as? Int ?? 1
                            let username = userObj["username"] as? String ?? "User"
                            let email = userObj["email"] as? String ?? (userObj["pterodactylEmail"] as? String ?? "")
                            let coins = initObj["coins"] as? Int ?? 0
                            
                            parsedUser = User(
                                id: id,
                                username: username,
                                email: email,
                                globalName: userObj["global_name"] as? String,
                                role: nil,
                                avatarUrl: nil,
                                coins: coins
                            )
                        }
                        
                        // Parse Resources
                        if let resObj = obj["resources"] as? [String: Any],
                           let resData = try? JSONSerialization.data(withJSONObject: resObj),
                           let res = try? JSONDecoder().decode(ResourcesResponse.self, from: resData) {
                            parsedResources = res
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.parent.onAuthSuccess(parsedUser, parsedResources)
                    }
                }
            }
        }
    }
}
