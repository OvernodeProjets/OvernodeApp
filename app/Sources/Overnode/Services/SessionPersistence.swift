import Foundation
import WebKit
import Security

public final class SessionPersistence: @unchecked Sendable {
    public static let shared = SessionPersistence()
    private let keychainService = "fr.overnode.OvernodeApp.cookies"
    private let keychainAccount = "session_cookies"
    
    private init() {}
    
    // MARK: - Keychain Helpers
    
    private func saveToKeychain(_ data: Data) -> Bool {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func loadFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return data
        }
        return nil
    }
    
    private func deleteFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Cookie Persistence
    
    public func persistCookies() {
        guard let cookies = HTTPCookieStorage.shared.cookies else { return }
        var serialized: [[String: String]] = []
        for cookie in cookies {
            if cookie.domain.contains("overnode.fr") || cookie.domain.contains("discord.com") {
                var dict: [String: String] = [:]
                dict["name"] = cookie.name
                dict["value"] = cookie.value
                dict["domain"] = cookie.domain
                dict["path"] = cookie.path
                dict["isSecure"] = cookie.isSecure ? "1" : "0"
                dict["isHTTPOnly"] = cookie.isHTTPOnly ? "1" : "0"
                if let exp = cookie.expiresDate {
                    dict["expiresDate"] = String(exp.timeIntervalSince1970)
                }
                serialized.append(dict)
            }
        }
        
        if let data = try? JSONSerialization.data(withJSONObject: serialized, options: []) {
            _ = saveToKeychain(data)
        }
    }
    
    public func restoreCookies() {
        migrateFromUserDefaults()
        
        guard let data = loadFromKeychain(),
              let list = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
            return
        }
        
        for item in list {
            guard let name = item["name"],
                  let val = item["value"],
                  let dom = item["domain"],
                  let path = item["path"] else {
                continue
            }
            
            var props: [HTTPCookiePropertyKey: Any] = [
                .name: name,
                .value: val,
                .domain: dom,
                .path: path
            ]
            
            if item["isSecure"] == "1" {
                props[.secure] = "TRUE"
            }
            
            if let expStr = item["expiresDate"], let expTimestamp = TimeInterval(expStr) {
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
        deleteFromKeychain()
        UserDefaults.standard.removeObject(forKey: "overnode_saved_cookies")
    }
    
    // MARK: - Migration from UserDefaults (one-time)
    
    private func migrateFromUserDefaults() {
        let legacyKey = "overnode_saved_cookies"
        guard let legacyList = UserDefaults.standard.array(forKey: legacyKey) as? [[String: Any]] else {
            return
        }
        
        var converted: [[String: String]] = []
        for item in legacyList {
            var dict: [String: String] = [:]
            dict["name"] = item["name"] as? String ?? ""
            dict["value"] = item["value"] as? String ?? ""
            dict["domain"] = item["domain"] as? String ?? ""
            dict["path"] = item["path"] as? String ?? ""
            if let sec = item["isSecure"] as? Bool { dict["isSecure"] = sec ? "1" : "0" }
            if let http = item["isHTTPOnly"] as? Bool { dict["isHTTPOnly"] = http ? "1" : "0" }
            if let exp = item["expiresDate"] as? TimeInterval { dict["expiresDate"] = String(exp) }
            converted.append(dict)
        }
        
        if let data = try? JSONSerialization.data(withJSONObject: converted, options: []) {
            if saveToKeychain(data) {
                UserDefaults.standard.removeObject(forKey: legacyKey)
            }
        }
    }
}
