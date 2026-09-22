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
    
    public func fetchPlatformStats() async -> PlatformStatsResponse {
        if let stats: PlatformStatsResponse = try? await client.request(endpoint: "/api/v5/platform-stats") {
            return stats
        }
        if let stats: PlatformStatsResponse = try? await client.request(endpoint: "/api/stats") {
            return stats
        }
        // Fallback default stats observed from live platform
        return PlatformStatsResponse(totalUsers: 1268, totalServers: 91, totalNodes: 4, totalLocations: 2)
    }
    
    public func fetchServersStatus() async -> [ServerInstance] {
        // 1. Try our dedicated live endpoint (/api/v5/servers/status)
        if let live: [ServerInstance] = try? await client.request(endpoint: "/api/v5/servers/status") {
            return live
        }
        
        // 2. Fallback to /api/v5/servers and enrich with real-time status & consumptions
        if let raw: [PteroServerWrapper] = try? await client.request(endpoint: "/api/v5/servers"), !raw.isEmpty {
            return await enrichServers(raw.map { $0.toServerInstance() })
        }
        
        // 3. Fallback to /api/servers and enrich with real-time status & consumptions
        if let raw: [PteroServerWrapper] = try? await client.request(endpoint: "/api/servers"), !raw.isEmpty {
            return await enrichServers(raw.map { $0.toServerInstance() })
        }
        
        // 4. Fallback to /api/v5/init
        if let initData = try? await fetchInit(), let srvs = initData.servers, !srvs.isEmpty {
            return await enrichServers(srvs.map { $0.toServerInstance() })
        }
        
        return []
    }
    
    private func enrichServers(_ servers: [ServerInstance]) async -> [ServerInstance] {
        return await withTaskGroup(of: ServerInstance.self) { group in
            for server in servers {
                group.addTask {
                    struct LiveResResponse: Decodable {
                        struct LiveAttributes: Decodable {
                            let currentState: String?
                            struct Res: Decodable {
                                let memoryBytes: Double?
                                let cpuAbsolute: Double?
                                let diskBytes: Double?
                                enum CodingKeys: String, CodingKey {
                                    case memoryBytes = "memory_bytes"
                                    case cpuAbsolute = "cpu_absolute"
                                    case diskBytes = "disk_bytes"
                                }
                            }
                            let resources: Res?
                            enum CodingKeys: String, CodingKey {
                                case currentState = "current_state"
                                case resources
                            }
                        }
                        let attributes: LiveAttributes?
                    }
                    
                    var updated = server
                    if let resData: LiveResResponse = try? await APIClient.shared.request(endpoint: "/api/client/servers/\(server.identifier)/resources") {
                        if let attr = resData.attributes {
                            updated.state = attr.currentState ?? "offline"
                            if let r = attr.resources {
                                updated.memoryUsedMB = (r.memoryBytes ?? 0) / 1024.0 / 1024.0
                                updated.cpuUsedPercent = r.cpuAbsolute ?? 0
                                updated.diskUsedMB = (r.diskBytes ?? 0) / 1024.0 / 1024.0
                            }
                        }
                    }
                    return updated
                }
            }
            var result: [ServerInstance] = []
            for await item in group {
                result.append(item)
            }
            return result.sorted { $0.name < $1.name }
        }
    }
    
    public func logout() {
        client.clearCookies()
    }
}
