import Foundation

public final class AuthService: @unchecked Sendable {
    public static let shared = AuthService()
    private let client = APIClient.shared
    
    private init() {}
    
    public func checkAuthState() async throws -> AuthStateResponse {
        return try await client.request(endpoint: "/api/v5/state")
    }
    
    public func fetchInit() async throws -> InitResponse {
        return try await client.request(endpoint: "/api/v5/init")
    }
    
    public func fetchResources() async throws -> ResourcesResponse {
        return try await client.request(endpoint: "/api/v5/resources")
    }
    
    public func fetchCoins() async throws -> Int {
        struct CoinsResponse: Decodable {
            let coins: Int
        }
        let res: CoinsResponse = try await client.request(endpoint: "/api/coins")
        return res.coins
    }
    
    public func getPasskeyOptions() async throws -> PasskeyOptionsResponse {
        return try await client.request(endpoint: "/auth/passkey/options")
    }
    
    public func verifyPasskey(payload: PasskeyVerifyPayload) async throws -> AuthStateResponse {
        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)
        return try await client.request(
            endpoint: "/auth/passkey/verify",
            method: "POST",
            body: data
        )
    }
    
    public func logout() {
        client.clearCookies()
    }
}
