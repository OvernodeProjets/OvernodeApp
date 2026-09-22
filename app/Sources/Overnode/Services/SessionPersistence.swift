import Foundation
import WebKit

public final class SessionPersistence: @unchecked Sendable {
    public static let shared = SessionPersistence()
    private let key = "overnode_saved_cookies"
    
    private init() {}
    
    public func persistCookies() {
        guard let cookies = HTTPCookieStorage.shared.cookies else { return }
        var serialized: [[String: Any]] = []
        for cookie in cookies {
            if cookie.domain.contains("overnode.fr") || cookie.domain.contains("discord.com") {
                var dict: [String: Any] = [:]
                dict["name"] = cookie.name
                dict["value"] = cookie.value
                dict["domain"] = cookie.domain
                dict["path"] = cookie.path
                dict["isSecure"] = cookie.isSecure
                dict["isHTTPOnly"] = cookie.isHTTPOnly
                if let exp = cookie.expiresDate {
                    dict["expiresDate"] = exp.timeIntervalSince1970
                }
                serialized.append(dict)
            }
        }
        UserDefaults.standard.set(serialized, forKey: key)
    }
    
    public func restoreCookies() {
        guard let list = UserDefaults.standard.array(forKey: key) as? [[String: Any]] else { return }
        for item in list {
            guard let name = item["name"] as? String,
                  let val = item["value"] as? String,
                  let dom = item["domain"] as? String,
                  let path = item["path"] as? String else {
                continue
            }
            
            var props: [HTTPCookiePropertyKey: Any] = [
                .name: name,
                .value: val,
                .domain: dom,
                .path: path
            ]
            
            if let isSec = item["isSecure"] as? Bool, isSec {
                props[.secure] = "TRUE"
            }
            
            if let expTimestamp = item["expiresDate"] as? TimeInterval {
                props[.expires] = Date(timeIntervalSince1970: expTimestamp)
            } else {
                // If session cookie, extend it so user stays logged in across app restarts
                props[.expires] = Date().addingTimeInterval(86400 * 30)
            }
            
            if let cookie = HTTPCookie(properties: props) {
                HTTPCookieStorage.shared.setCookie(cookie)
                Task { @MainActor in
                    await WKWebsiteDataStore.default().httpCookieStore.setCookie(cookie)
                }
            }
        }
    }
    
    public func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
