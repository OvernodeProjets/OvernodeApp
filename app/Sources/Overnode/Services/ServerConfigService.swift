import Foundation

public final class ServerConfigService: @unchecked Sendable {
    public static let shared = ServerConfigService()
    private let client = APIClient.shared
    
    private init() {}
    
    // MARK: - Subdomains
    public func fetchSubdomains(serverId: String) async throws -> [ServerSubdomain] {
        return try await client.request(endpoint: "/api/v5/server/\(serverId)/subdomains")
    }
    
    public func fetchAvailableDomains() async throws -> [String] {
        struct DomainResponse: Decodable {
            let domains: [String]?
        }
        if let res: DomainResponse = try? await client.request(endpoint: "/api/v5/subdomains/domains"), let list = res.domains {
            return list
        }
        if let list: [String] = try? await client.request(endpoint: "/api/v5/subdomains/domains") {
            return list
        }
        return ["overnode.fr", "overnode.cloud", "play.overnode.fr"]
    }
    
    public func createSubdomain(serverId: String, subdomain: String, domainName: String) async throws {
        struct Payload: Encodable {
            let subdomain: String
            let domainName: String
        }
        let data = try JSONEncoder().encode(Payload(subdomain: subdomain, domainName: domainName))
        try await client.requestEmpty(
            endpoint: "/api/v5/server/\(serverId)/subdomains",
            method: "POST",
            body: data
        )
    }
    
    public func deleteSubdomain(serverId: String, subdomainId: String) async throws {
        try await client.requestEmpty(
            endpoint: "/api/v5/server/\(serverId)/subdomains/\(subdomainId)",
            method: "DELETE"
        )
    }
    
    // MARK: - Subusers
    public func fetchSubusers(serverId: String) async throws -> [ServerSubuser] {
        let res: PteroUsersResponse = try await client.request(endpoint: "/api/server/\(serverId)/users")
        return res.data.map { datum in
            let attr = datum.attributes
            return ServerSubuser(
                id: attr.id ?? attr.uuid ?? UUID().uuidString,
                uuid: attr.uuid,
                email: attr.email,
                image: attr.image,
                twoFactorEnabled: attr.twoFactorEnabled ?? false,
                permissions: attr.permissions ?? []
            )
        }
    }
    
    public func createSubuser(serverId: String, email: String, permissions: [String]) async throws {
        struct Payload: Encodable {
            let email: String
            let permissions: [String]
        }
        let data = try JSONEncoder().encode(Payload(email: email, permissions: permissions))
        try await client.requestEmpty(
            endpoint: "/api/server/\(serverId)/users",
            method: "POST",
            body: data
        )
    }
    
    public func deleteSubuser(serverId: String, userId: String) async throws {
        try await client.requestEmpty(
            endpoint: "/api/server/\(serverId)/users/\(userId)",
            method: "DELETE"
        )
    }
    
    // MARK: - Settings, Reinstall, Variables & Package
    public func renameServer(serverId: String, name: String) async throws {
        struct Payload: Encodable {
            let name: String
        }
        let data = try JSONEncoder().encode(Payload(name: name))
        try await client.requestEmpty(
            endpoint: "/api/server/\(serverId)/rename",
            method: "POST",
            body: data
        )
    }
    
    public func reinstallServer(serverId: String) async throws {
        try await client.requestEmpty(
            endpoint: "/api/server/\(serverId)/reinstall",
            method: "POST"
        )
    }
    
    public func modifyServerResources(serverId: String, ramMB: Int, diskMB: Int, cpuPercent: Int) async throws {
        struct Payload: Encodable {
            let ram: Int
            let disk: Int
            let cpu: Int
        }
        let data = try JSONEncoder().encode(Payload(ram: ramMB, disk: diskMB, cpu: cpuPercent))
        try await client.requestEmpty(
            endpoint: "/api/v5/servers/\(serverId)",
            method: "PATCH",
            body: data
        )
    }
    
    public func fetchVariables(serverId: String) async throws -> [ServerStartupVariable] {
        let res: PteroStartupVariablesResponse = try await client.request(endpoint: "/api/server/\(serverId)/variables")
        return res.data.map { item in
            let attr = item.attributes
            return ServerStartupVariable(
                name: attr.name,
                description: attr.description,
                envVariable: attr.envVariable,
                defaultValue: attr.defaultValue,
                serverValue: attr.serverValue ?? "",
                isEditable: attr.isEditable ?? true,
                rules: attr.rules
            )
        }
    }
    
    public func updateVariable(serverId: String, key: String, value: String) async throws {
        struct Payload: Encodable {
            let key: String
            let value: String
        }
        let data = try JSONEncoder().encode(Payload(key: key, value: value))
        try await client.requestEmpty(
            endpoint: "/api/server/\(serverId)/variables",
            method: "PUT",
            body: data
        )
    }
    
    // MARK: - Plugins
    public func fetchInstalledPlugins(serverId: String) async throws -> [ServerPluginItem] {
        if let res: InstalledPluginsResponse = try? await client.request(endpoint: "/api/plugins/installed/\(serverId)") {
            return res.plugins.map { p in
                ServerPluginItem(
                    id: p.id,
                    name: p.name,
                    description: p.description,
                    iconUrl: p.iconUrl,
                    version: p.version,
                    author: p.author,
                    platform: p.platform ?? "modrinth",
                    downloads: nil,
                    isInstalled: true
                )
            }
        }
        return []
    }
    
    public func searchPlugins(query: String, platform: String = "modrinth") async throws -> [ServerPluginItem] {
        let cleanQuery = query.trimmingCharacters(in: .whitespaces).isEmpty ? "world" : query
        let encoded = cleanQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleanQuery
        struct RawPluginItem: Decodable {
            let id: String
            let name: String
            let description: String?
            let iconUrl: String?
            let downloads: Int?
            let platform: String?
            
            enum CodingKeys: String, CodingKey {
                case id, name, tag, description, icon, iconUrl, downloads, platform
            }
            
            init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                if let idStr = try? c.decode(String.self, forKey: .id) {
                    self.id = idStr
                } else if let idInt = try? c.decode(Int.self, forKey: .id) {
                    self.id = String(idInt)
                } else {
                    self.id = UUID().uuidString
                }
                self.name = (try? c.decode(String.self, forKey: .name)) ?? "Plugin"
                self.description = (try? c.decode(String.self, forKey: .tag)) ?? (try? c.decode(String.self, forKey: .description))
                self.iconUrl = (try? c.decode(String.self, forKey: .icon)) ?? (try? c.decode(String.self, forKey: .iconUrl))
                self.downloads = try? c.decode(Int.self, forKey: .downloads)
                self.platform = try? c.decode(String.self, forKey: .platform)
            }
        }
        let endpoint = "/api/plugins/search?query=\(encoded)&platform=\(platform)&size=30"
        
        // Direct array response
        if let list: [RawPluginItem] = try? await client.request(endpoint: endpoint) {
            return list.map {
                ServerPluginItem(
                    id: $0.id,
                    name: $0.name,
                    description: $0.description,
                    iconUrl: $0.iconUrl,
                    version: "latest",
                    author: nil,
                    platform: $0.platform ?? platform,
                    downloads: $0.downloads,
                    isInstalled: false
                )
            }
        }
        
        // Wrapped response fallback
        struct WrappedResponse: Decodable {
            let data: [RawPluginItem]?
        }
        if let res: WrappedResponse = try? await client.request(endpoint: endpoint), let list = res.data {
            return list.map {
                ServerPluginItem(
                    id: $0.id,
                    name: $0.name,
                    description: $0.description,
                    iconUrl: $0.iconUrl,
                    version: "latest",
                    author: nil,
                    platform: $0.platform ?? platform,
                    downloads: $0.downloads,
                    isInstalled: false
                )
            }
        }
        
        return []
    }
    
    public func installPlugin(serverId: String, pluginId: String, platform: String = "modrinth") async throws {
        struct Payload: Encodable {
            let pluginId: String
            let platform: String
        }
        let data = try JSONEncoder().encode(Payload(pluginId: pluginId, platform: platform))
        try await client.requestEmpty(
            endpoint: "/api/plugins/install/\(serverId)",
            method: "POST",
            body: data
        )
    }
    
    public func untrackPlugin(serverId: String, pluginId: String, platform: String = "modrinth") async throws {
        struct Payload: Encodable {
            let pluginId: String
            let platform: String
        }
        let data = try JSONEncoder().encode(Payload(pluginId: pluginId, platform: platform))
        try await client.requestEmpty(
            endpoint: "/api/plugins/untrack/\(serverId)",
            method: "DELETE",
            body: data
        )
    }
    
    // MARK: - Activity Logs
    public func fetchLogs(serverId: String, page: Int = 1) async throws -> [ServerActivityLog] {
        let res: ActivityLogsResponse = try await client.request(endpoint: "/api/server/\(serverId)/logs?page=\(page)&limit=30")
        return res.data.map {
            ServerActivityLog(
                id: $0.id,
                timestamp: $0.timestamp,
                action: $0.action,
                username: $0.username,
                details: nil
            )
        }
    }
}
