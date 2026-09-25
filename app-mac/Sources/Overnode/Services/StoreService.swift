import Foundation
import AppKit

public final class StoreService: @unchecked Sendable {
    public static let shared = StoreService()
    private let client = APIClient.shared
    
    private init() {}
    
    public func fetchStoreConfig() async throws -> StoreConfigResponse {
        return try await client.request(endpoint: "/api/store/config")
    }
    
    public func buyResource(resourceType: String, amount: Int) async throws -> StoreBuyResponse {
        let payload = StoreBuyPayload(resourceType: resourceType, amount: amount)
        let body = try JSONEncoder().encode(payload)
        return try await client.request(
            endpoint: "/api/store/buy",
            method: "POST",
            body: body
        )
    }
    
    public func openSubscribeWeb() {
        if let url = URL(string: "https://console.overnode.fr/coin/store") {
            NSWorkspace.shared.open(url)
        }
    }
}

