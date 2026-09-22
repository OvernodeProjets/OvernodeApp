import Foundation

public final class ServerService: @unchecked Sendable {
    public static let shared = ServerService()
    private let client = APIClient.shared
    
    private init() {}
    
    // MARK: - Power Actions
    public func sendPowerSignal(serverId: String, signal: ServerPowerSignal) async throws {
        struct PowerPayload: Encodable {
            let signal: String
        }
        let data = try JSONEncoder().encode(PowerPayload(signal: signal.rawValue))
        try await client.requestEmpty(
            endpoint: "/api/server/\(serverId)/power",
            method: "POST",
            body: data
        )
    }
    
    // MARK: - Console Commands
    public func sendCommand(serverId: String, command: String) async throws {
        struct CommandPayload: Encodable {
            let command: String
        }
        let data = try JSONEncoder().encode(CommandPayload(command: command))
        struct CommandResponse: Decodable {
            let success: Bool?
            let message: String?
        }
        let _: CommandResponse = try await client.request(
            endpoint: "/api/server/\(serverId)/command",
            method: "POST",
            body: data
        )
    }
    
    // MARK: - Renewal
    public func fetchRenewalStatus(serverId: String) async -> ServerRenewalStatus? {
        do {
            let status: ServerRenewalStatus = try await client.request(
                endpoint: "/api/server/\(serverId)/renewal/status"
            )
            return status
        } catch {
            return nil
        }
    }
    
    public func renewServer(serverId: String) async throws -> ServerRenewalActionResponse {
        do {
            return try await client.request(
                endpoint: "/api/server/\(serverId)/renewal/renew",
                method: "POST"
            )
        } catch let nsError as NSError {
            if let rawJson = nsError.userInfo[NSLocalizedDescriptionKey] as? String,
               let data = rawJson.data(using: .utf8),
               let actionResponse = try? JSONDecoder().decode(ServerRenewalActionResponse.self, from: data) {
                return actionResponse
            }
            throw nsError
        }
    }
    
    // MARK: - Live Resources & Status
    public func fetchLiveResources(identifier: String) async throws -> (state: String, memoryMB: Double, cpuPercent: Double, diskMB: Double) {
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
        
        let resData: LiveResResponse = try await client.request(
            endpoint: "/api/client/servers/\(identifier)/resources"
        )
        
        let state = resData.attributes?.currentState ?? "offline"
        let r = resData.attributes?.resources
        let mem = (r?.memoryBytes ?? 0) / 1024.0 / 1024.0
        let cpu = r?.cpuAbsolute ?? 0
        let disk = (r?.diskBytes ?? 0) / 1024.0 / 1024.0
        return (state, mem, cpu, disk)
    }
}

