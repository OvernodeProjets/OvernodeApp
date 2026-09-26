import Foundation

public struct ServerInstance: Codable, Identifiable, Equatable, Sendable {
    public let id: Int
    public let identifier: String
    public let name: String
    public let node: String?
    public let suspended: Bool
    public var state: String // "running", "starting", "stopping", "offline", "suspended"
    public var isOwner: Bool
    public var permissions: [String]
    public var memoryUsedMB: Double
    public var memoryLimitMB: Double
    public var cpuUsedPercent: Double
    public var cpuLimitPercent: Double
    public var diskUsedMB: Double
    public var diskLimitMB: Double
    
    enum CodingKeys: String, CodingKey {
        case id, identifier, name, node, suspended, state
        case isOwner, permissions
        case memoryUsedMB, memoryLimitMB, cpuUsedPercent, cpuLimitPercent, diskUsedMB, diskLimitMB
    }
    
    public init(
        id: Int,
        identifier: String,
        name: String,
        node: String? = nil,
        suspended: Bool = false,
        state: String = "offline",
        isOwner: Bool = true,
        permissions: [String] = ["*"],
        memoryUsedMB: Double = 0,
        memoryLimitMB: Double = 0,
        cpuUsedPercent: Double = 0,
        cpuLimitPercent: Double = 0,
        diskUsedMB: Double = 0,
        diskLimitMB: Double = 0
    ) {
        self.id = id
        self.identifier = identifier
        self.name = name
        self.node = node
        self.suspended = suspended
        self.state = state
        self.isOwner = isOwner
        self.permissions = permissions
        self.memoryUsedMB = memoryUsedMB
        self.memoryLimitMB = memoryLimitMB
        self.cpuUsedPercent = cpuUsedPercent
        self.cpuLimitPercent = cpuLimitPercent
        self.diskUsedMB = diskUsedMB
        self.diskLimitMB = diskLimitMB
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        if let idInt = try? c.decode(Int.self, forKey: .id) {
            self.id = idInt
        } else if let idStr = try? c.decode(String.self, forKey: .id), let idParsed = Int(idStr) {
            self.id = idParsed
        } else {
            self.id = 0
        }
        
        self.identifier = (try? c.decode(String.self, forKey: .identifier)) ?? ""
        self.name = (try? c.decode(String.self, forKey: .name)) ?? "Server"
        
        if let nodeStr = try? c.decode(String.self, forKey: .node) {
            self.node = nodeStr
        } else if let nodeInt = try? c.decode(Int.self, forKey: .node) {
            self.node = "Node \(nodeInt)"
        } else {
            self.node = nil
        }
        
        if let suspBool = try? c.decode(Bool.self, forKey: .suspended) {
            self.suspended = suspBool
        } else if let suspInt = try? c.decode(Int.self, forKey: .suspended) {
            self.suspended = suspInt != 0
        } else {
            self.suspended = false
        }
        
        self.state = (try? c.decode(String.self, forKey: .state)) ?? (self.suspended ? "suspended" : "offline")
        self.isOwner = (try? c.decode(Bool.self, forKey: .isOwner)) ?? true
        self.permissions = (try? c.decode([String].self, forKey: .permissions)) ?? (self.isOwner ? ["*"] : [])
        self.memoryUsedMB = (try? c.decode(Double.self, forKey: .memoryUsedMB)) ?? 0
        self.memoryLimitMB = (try? c.decode(Double.self, forKey: .memoryLimitMB)) ?? 0
        self.cpuUsedPercent = (try? c.decode(Double.self, forKey: .cpuUsedPercent)) ?? 0
        self.cpuLimitPercent = (try? c.decode(Double.self, forKey: .cpuLimitPercent)) ?? 0
        self.diskUsedMB = (try? c.decode(Double.self, forKey: .diskUsedMB)) ?? 0
        self.diskLimitMB = (try? c.decode(Double.self, forKey: .diskLimitMB)) ?? 0
    }
    
    public var isOnline: Bool {
        return state.lowercased() == "running"
    }
    
    public func hasPermission(_ perm: String) -> Bool {
        if isOwner { return true }
        if permissions.contains("*") { return true }
        return permissions.contains(perm)
    }
    
    public var canStart: Bool { hasPermission("control.start") }
    public var canStop: Bool { hasPermission("control.stop") }
    public var canRestart: Bool { hasPermission("control.restart") }
    public var canConsole: Bool { hasPermission("control.console") }
    public var canManageFiles: Bool { hasPermission("file.read") || hasPermission("file.create") }
    public var canDelete: Bool { isOwner }
    public var canRenew: Bool { isOwner }
}

// Model for Pterodactyl Application API server item returned in /api/v5/servers or /api/v5/init
public struct PteroServerWrapper: Codable, Equatable, Sendable {
    public struct Attributes: Codable, Equatable, Sendable {
        public let id: Int
        public let identifier: String
        public let name: String
        public let node: String?
        public let suspended: Bool?
        
        public struct Limits: Codable, Equatable, Sendable {
            public let memory: Double?
            public let cpu: Double?
            public let disk: Double?
            
            enum CodingKeys: String, CodingKey {
                case memory, cpu, disk
            }
            
            public init(memory: Double?, cpu: Double?, disk: Double?) {
                self.memory = memory
                self.cpu = cpu
                self.disk = disk
            }
            
            public init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                self.memory = (try? c.decode(Double.self, forKey: .memory)) ?? (try? c.decode(Int.self, forKey: .memory)).map(Double.init)
                self.cpu = (try? c.decode(Double.self, forKey: .cpu)) ?? (try? c.decode(Int.self, forKey: .cpu)).map(Double.init)
                self.disk = (try? c.decode(Double.self, forKey: .disk)) ?? (try? c.decode(Int.self, forKey: .disk)).map(Double.init)
            }
        }
        public let limits: Limits?
        
        enum CodingKeys: String, CodingKey {
            case id, identifier, name, node, suspended, limits
        }
        
        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            
            if let idInt = try? c.decode(Int.self, forKey: .id) {
                self.id = idInt
            } else if let idStr = try? c.decode(String.self, forKey: .id), let idParsed = Int(idStr) {
                self.id = idParsed
            } else {
                self.id = 0
            }
            
            self.identifier = (try? c.decode(String.self, forKey: .identifier)) ?? ""
            self.name = (try? c.decode(String.self, forKey: .name)) ?? "Server"
            
            if let nodeStr = try? c.decode(String.self, forKey: .node) {
                self.node = nodeStr
            } else if let nodeInt = try? c.decode(Int.self, forKey: .node) {
                self.node = "Node \(nodeInt)"
            } else {
                self.node = nil
            }
            
            self.suspended = try? c.decode(Bool.self, forKey: .suspended)
            self.limits = try? c.decode(Limits.self, forKey: .limits)
        }
    }
    
    public let attributes: Attributes
    
    public func toServerInstance() -> ServerInstance {
        return ServerInstance(
            id: attributes.id,
            identifier: attributes.identifier,
            name: attributes.name,
            node: attributes.node,
            suspended: attributes.suspended ?? false,
            state: (attributes.suspended ?? false) ? "suspended" : "offline",
            memoryUsedMB: 0,
            memoryLimitMB: attributes.limits?.memory ?? 0,
            cpuUsedPercent: 0,
            cpuLimitPercent: attributes.limits?.cpu ?? 0,
            diskUsedMB: 0,
            diskLimitMB: attributes.limits?.disk ?? 0
        )
    }
}

