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
        
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "overnodeBridge")
        
        // Injected monitor that checks for genuine authentication status
        let sessionObserverScript = """
        (function() {
            let hasReportedAuth = false;
            
            function checkAuthState() {
                if (hasReportedAuth) return;
                
                var path = window.location.pathname || '';
                if (path.indexOf('2fa') !== -1) return;
                
                fetch('/api/v5/state', { credentials: 'include' })
                    .then(function(r) { return r.ok ? r.json() : null; })
                    .then(function(stateData) {
                        if (!stateData) return;
                        if (stateData.authenticated === true && !stateData.twoFactorPending) {
                            hasReportedAuth = true;
                            
                            Promise.all([
                                fetch('/api/v5/init', { credentials: 'include' }).then(r => r.ok ? r.json() : null).catch(() => null),
                                fetch('/api/v5/resources', { credentials: 'include' }).then(r => r.ok ? r.json() : null).catch(() => null)
                            ]).then(([initData, resData]) => {
                                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.overnodeBridge) {
                                    window.webkit.messageHandlers.overnodeBridge.postMessage(JSON.stringify({
                                        state: stateData,
                                        init: initData,
                                        resources: resData
                                    }));
                                }
                            }).catch(() => {
                                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.overnodeBridge) {
                                    window.webkit.messageHandlers.overnodeBridge.postMessage(JSON.stringify({
                                        state: stateData,
                                        init: null,
                                        resources: null
                                    }));
                                }
                            });
                        }
                    })
                    .catch(function() {});
            }
            
            // Hook HTML5 History API for instant detection on React Router navigation
            const originalPushState = history.pushState;
            history.pushState = function() {
                originalPushState.apply(this, arguments);
                setTimeout(checkAuthState, 150);
            };
            
            const originalReplaceState = history.replaceState;
            history.replaceState = function() {
                originalReplaceState.apply(this, arguments);
                setTimeout(checkAuthState, 150);
            };
            
            window.addEventListener('popstate', () => {
                setTimeout(checkAuthState, 150);
            });
            
            setInterval(checkAuthState, 600);
            checkAuthState();
        })();
        """
        
        let userScript = WKUserScript(
            source: sessionObserverScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        userContentController.addUserScript(userScript)
        configuration.userContentController = userContentController
        
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
    public class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebAuthModalView
        private weak var webView: WKWebView?
        private var isCompleted = false
        
        init(_ parent: WebAuthModalView) {
            self.parent = parent
        }
        
        func attach(to webView: WKWebView) {
            self.webView = webView
            scheduleStatePolling()
        }
        
        private func scheduleStatePolling() {
            guard !isCompleted else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self, !self.isCompleted, let webView = self.webView else { return }
                webView.evaluateJavaScript("typeof checkAuthState === 'function' ? checkAuthState() : null", completionHandler: nil)
                self.scheduleStatePolling()
            }
        }
        
        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "overnodeBridge",
                  let jsonString = message.body as? String,
                  let data = jsonString.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let webView = message.webView else {
                return
            }
            
            handleSuccessfulAuth(payload: obj, from: webView)
        }
        
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("typeof checkAuthState === 'function' ? checkAuthState() : null", completionHandler: nil)
        }
        
        private func handleSuccessfulAuth(payload: [String: Any], from webView: WKWebView) {
            guard !isCompleted else { return }
            isCompleted = true
            
            let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
            
            cookieStore.getAllCookies { [weak self] cookies in
                guard let self = self else { return }
                for cookie in cookies {
                    HTTPCookieStorage.shared.setCookie(cookie)
                }
                SessionPersistence.shared.persistCookies()
                
                var parsedUser: User? = nil
                var parsedResources: ResourcesResponse? = nil
                
                // 1. Try resolving from init payload
                if let initObj = payload["init"] as? [String: Any],
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
                } else if let stateObj = payload["state"] as? [String: Any],
                          let userObj = stateObj["user"] as? [String: Any] {
                    // 2. Fallback to state payload
                    let id = userObj["id"] as? Int ?? 1
                    let username = userObj["username"] as? String ?? "User"
                    let email = userObj["email"] as? String ?? ""
                    
                    parsedUser = User(
                        id: id,
                        username: username,
                        email: email,
                        globalName: username,
                        role: nil,
                        avatarUrl: nil,
                        coins: 0
                    )
                }
                
                // Parse Resources
                if let resObj = payload["resources"] as? [String: Any],
                   let resData = try? JSONSerialization.data(withJSONObject: resObj),
                   let res = try? JSONDecoder().decode(ResourcesResponse.self, from: resData) {
                    parsedResources = res
                }
                
                DispatchQueue.main.async {
                    if let user = parsedUser {
                        self.parent.onAuthSuccess(user, parsedResources)
                    } else {
                        Task {
                            if let initData = try? await AuthService.shared.fetchInit(),
                               let u = initData.user {
                                let resolved = User(
                                    id: u.id,
                                    username: u.username,
                                    email: u.email.isEmpty ? (u.pterodactylEmail ?? "") : u.email,
                                    globalName: u.globalName,
                                    role: initData.roles?.first,
                                    avatarUrl: nil,
                                    coins: initData.coins ?? 0
                                )
                                let res = try? await AuthService.shared.fetchResources()
                                self.parent.onAuthSuccess(resolved, res)
                            }
                        }
                    }
                }
            }
        }
    }
}
