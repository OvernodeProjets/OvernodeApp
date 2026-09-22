import Foundation
import WebKit

public final class APIClient: @unchecked Sendable {
    public static let shared = APIClient()
    
    public var baseURL: URL = URL(string: "https://console.overnode.fr")!
    private let session: URLSession
    
    private init() {
        // Restore persistent cookies at launch
        SessionPersistence.shared.restoreCookies()
        
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.timeoutIntervalForRequest = 12
        config.timeoutIntervalForResource = 25
        self.session = URLSession(configuration: config)
    }
    
    public func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Overnode-macOS-Native/1.0", forHTTPHeaderField: "User-Agent")
        
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        var cookiesToSend: [HTTPCookie] = []
        if let forUrl = HTTPCookieStorage.shared.cookies(for: url) {
            cookiesToSend.append(contentsOf: forUrl)
        }
        if let all = HTTPCookieStorage.shared.cookies {
            for c in all {
                if !cookiesToSend.contains(where: { $0.name == c.name }) {
                    cookiesToSend.append(c)
                }
            }
        }
        if !cookiesToSend.isEmpty {
            let cookieHeaders = HTTPCookie.requestHeaderFields(with: cookiesToSend)
            for (headerKey, headerVal) in cookieHeaders {
                request.setValue(headerVal, forHTTPHeaderField: headerKey)
            }
        }
        
        for (key, val) in headers {
            request.setValue(val, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Save any set-cookies from the response
        if let headerFields = httpResponse.allHeaderFields as? [String: String],
           let respURL = httpResponse.url {
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: respURL)
            for cookie in cookies {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
            SessionPersistence.shared.persistCookies()
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP (httpResponse.statusCode)"
            throw NSError(domain: "APIClient", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    public func requestEmpty(
        endpoint: String,
        method: String = "POST",
        body: Data? = nil,
        headers: [String: String] = [:]
    ) async throws {
        _ = try await requestData(endpoint: endpoint, method: method, body: body, headers: headers)
    }
    
    public func requestString(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        headers: [String: String] = [:]
    ) async throws -> String {
        let (data, _) = try await requestData(endpoint: endpoint, method: method, body: body, headers: headers)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    public func requestData(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        headers: [String: String] = [:],
        contentType: String? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("Overnode-macOS-Native/1.0", forHTTPHeaderField: "User-Agent")
        
        if let ct = contentType {
            request.setValue(ct, forHTTPHeaderField: "Content-Type")
        } else if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        var cookiesToSend: [HTTPCookie] = []
        if let forUrl = HTTPCookieStorage.shared.cookies(for: url) {
            cookiesToSend.append(contentsOf: forUrl)
        }
        if let all = HTTPCookieStorage.shared.cookies {
            for c in all {
                if !cookiesToSend.contains(where: { $0.name == c.name }) {
                    cookiesToSend.append(c)
                }
            }
        }
        if !cookiesToSend.isEmpty {
            let cookieHeaders = HTTPCookie.requestHeaderFields(with: cookiesToSend)
            for (headerKey, headerVal) in cookieHeaders {
                request.setValue(headerVal, forHTTPHeaderField: headerKey)
            }
        }
        
        for (key, val) in headers {
            request.setValue(val, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if let headerFields = httpResponse.allHeaderFields as? [String: String],
           let respURL = httpResponse.url {
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: respURL)
            for cookie in cookies {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
            SessionPersistence.shared.persistCookies()
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw NSError(domain: "APIClient", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        return (data, httpResponse)
    }
    
    public func clearCookies() {
        SessionPersistence.shared.clear()
        
        if let cookies = HTTPCookieStorage.shared.cookies(for: baseURL) {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        
        Task { @MainActor in
            let cookieStore = WKWebsiteDataStore.default().httpCookieStore
            let cookies = await cookieStore.allCookies()
            for cookie in cookies {
                if cookie.domain.contains("overnode.fr") {
                    await cookieStore.deleteCookie(cookie)
                }
            }
        }
    }
}
