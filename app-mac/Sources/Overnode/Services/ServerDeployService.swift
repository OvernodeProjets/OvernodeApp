import Foundation

public final class ServerDeployService: @unchecked Sendable {
    public static let shared = ServerDeployService()
    private let client = APIClient.shared
    
    private init() {}
    
    public func fetchDeployOptions() async throws -> DeployOptionsResponse {
        if ProcessInfo.processInfo.environment["OVERNODE_DEMO"] == "1" {
            return demoDeployOptions()
        }
        
        async let eggsReq: [ServerEgg] = (try? client.request(endpoint: "/api/v5/eggs")) ?? []
        async let locsReq: [ServerLocation] = (try? client.request(endpoint: "/api/v5/locations")) ?? []
        async let nodesReq: [ServerNode] = fetchRealNodes()
        async let resReq: ResourcesResponse = (try? client.request(endpoint: "/api/v5/resources")) ?? ResourcesResponse.empty
        
        let (rawEggs, rawLocs, rawNodes, rawRes) = await (eggsReq, locsReq, nodesReq, resReq)
        
        let categories = [
            EggCategory(id: "all", name: "All", icon: "square.grid.2x2"),
            EggCategory(id: "minecraft", name: "Minecraft", icon: "cube"),
            EggCategory(id: "discord", name: "Discord Bots", icon: "message"),
            EggCategory(id: "web", name: "Web & DB", icon: "globe"),
            EggCategory(id: "game", name: "Games", icon: "gamecontroller"),
            EggCategory(id: "other", name: "Other", icon: "shippingbox")
        ]
        
        let deployRes = DeployResourcesInfo(
            current: rawRes.current,
            allowed: rawRes.limits,
            remaining: rawRes.remaining
        )
        
        return DeployOptionsResponse(
            categories: categories,
            eggs: rawEggs.isEmpty ? demoDeployOptions().eggs : rawEggs,
            locations: rawLocs.isEmpty ? demoDeployOptions().locations : rawLocs,
            nodes: rawNodes.isEmpty ? demoDeployOptions().nodes : rawNodes,
            resources: deployRes
        )
    }
    
    private func fetchRealNodes() async -> [ServerNode] {
        if let nodes: [ServerNode] = try? await client.request(endpoint: "/api/v5/nodes"), !nodes.isEmpty {
            return nodes
        }
        if let nodes: [ServerNode] = try? await client.request(endpoint: "/api/nodes"), !nodes.isEmpty {
            return nodes
        }
        return []
    }
    
    public func createServer(payload: CreateServerPayload) async throws -> CreateServerResult {
        if ProcessInfo.processInfo.environment["OVERNODE_DEMO"] == "1" {
            try await Task.sleep(nanoseconds: 600_000_000)
            return CreateServerResult(object: "server", error: nil, message: "Server created successfully", attributes: nil)
        }
        
        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(payload)
        
        let (data, response) = try await client.requestData(
            endpoint: "/api/v5/servers",
            method: "POST",
            body: bodyData
        )
        
        if response.statusCode == 200 || response.statusCode == 201 {
            return (try? JSONDecoder().decode(CreateServerResult.self, from: data))
                ?? CreateServerResult(object: "server", error: nil, message: "Server created successfully", attributes: nil)
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let errorStr = json["error"] as? String ?? json["message"] as? String {
            throw NSError(domain: "ServerDeployService", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: errorStr])
        }
        
        throw NSError(domain: "ServerDeployService", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to deploy server ((response.statusCode))"])
    }
    
    private func demoDeployOptions() -> DeployOptionsResponse {
        let categories = [
            EggCategory(id: "all", name: "All", icon: "square.grid.2x2"),
            EggCategory(id: "minecraft", name: "Minecraft", icon: "cube"),
            EggCategory(id: "discord", name: "Discord Bots", icon: "message"),
            EggCategory(id: "web", name: "Web & DB", icon: "globe"),
            EggCategory(id: "game", name: "Games", icon: "gamecontroller")
        ]
        let eggs = [
            ServerEgg(id: "minecraft_paper", name: "Paper Minecraft", description: "High-performance Spigot fork for Minecraft servers", category: "minecraft", minimum: ResourceRequirement(ram: 1024, disk: 2048, cpu: 100)),
            ServerEgg(id: "minecraft_purpur", name: "Purpur Minecraft", description: "Configurable and optimized gameplay fork of Paper", category: "minecraft", minimum: ResourceRequirement(ram: 1024, disk: 2048, cpu: 100)),
            ServerEgg(id: "minecraft_forge", name: "Forge Modded", description: "Minecraft modded server support with Forge", category: "minecraft", minimum: ResourceRequirement(ram: 2048, disk: 4096, cpu: 150)),
            ServerEgg(id: "nodejs", name: "Node.js", description: "Node.js runtime for JavaScript & TypeScript bots", category: "discord", minimum: ResourceRequirement(ram: 256, disk: 512, cpu: 20)),
            ServerEgg(id: "python", name: "Python", description: "Python 3 runtime for Discord bots and automation", category: "discord", minimum: ResourceRequirement(ram: 256, disk: 512, cpu: 20))
        ]
        let locations = [
            ServerLocation(id: "1", name: "France (Paris)", description: "Low-latency EU West datacenter with anti-DDoS protection", flags: ["FR"], full: false),
            ServerLocation(id: "2", name: "Germany (Frankfurt)", description: "Central Europe high-speed network hub", flags: ["DE"], full: false)
        ]
        let nodes = [
            ServerNode(id: 1, name: "Node FR-01", locationId: "1"),
            ServerNode(id: 2, name: "Node FR-02", locationId: "1"),
            ServerNode(id: 3, name: "Node DE-01", locationId: "2")
        ]
        let res = DeployResourcesInfo(
            current: ResourceBucket(ram: 3260, disk: 9320, cpu: 141, servers: 2),
            allowed: ResourceBucket(ram: 8192, disk: 40960, cpu: 400, servers: 4),
            remaining: ResourceBucket(ram: 4932, disk: 31640, cpu: 259, servers: 2)
        )
        return DeployOptionsResponse(categories: categories, eggs: eggs, locations: locations, nodes: nodes, resources: res)
    }
}

