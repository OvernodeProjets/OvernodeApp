import Foundation

public struct ServerInstance: Codable, Identifiable, Equatable, Sendable {
    public let id: Int
    public let identifier: String
    public let name: String
    public let node: String?
    public let suspended: Bool
    public var state: String // "running", "starting", "stopping", "offline", "suspended"
    public var memoryUsedMB: Double
    public var memoryLimitMB: Double
    public var cpuUsedPercent: Double
    public var cpuLimitPercent: Double
    public var diskUsedMB: Double
    public var diskLimitMB: Double
    
    public init(
        id: Int,
        identifier: String,
        name: String,
        node: String? = nil,
        suspended: Bool = false,
        state: String = "offline",
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
        self.memoryUsedMB = memoryUsedMB
        self.memoryLimitMB = memoryLimitMB
        self.cpuUsedPercent = cpuUsedPercent
        self.cpuLimitPercent = cpuLimitPercent
        self.diskUsedMB = diskUsedMB
        self.diskLimitMB = diskLimitMB
    }
    
    public var isOnline: Bool {
        return state.lowercased() == "running"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, identifier, name, node, suspended, state
        case memoryUsedMB, memoryLimitMB, cpuUsedPercent, cpuLimitPercent, diskUsedMB, diskLimitMB
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let intId = try? container.decode(Int.self, forKey: .id) {
            self.id = intId
        } else if let strId = try? container.decode(String.self, forKey: .id), let parsed = Int(strId) {
            self.id = parsed
        } else {
            self.id = 0
        }
        
        self.identifier = (try? container.decode(String.self, forKey: .identifier)) ?? "\(self.id)"
        self.name = (try? container.decode(String.self, forKey: .name)) ?? "Server"
        
        if let strNode = try? container.decode(String.self, forKey: .node) {
            self.node = strNode
        } else if let intNode = try? container.decode(Int.self, forKey: .node) {
            self.node = "\(intNode)"
        } else {
            self.node = nil
        }
        
        if let b = try? container.decode(Bool.self, forKey: .suspended) {
            self.suspended = b
        } else if let i = try? container.decode(Int.self, forKey: .suspended) {
            self.suspended = (i != 0)
        } else {
            self.suspended = false
        }
        
        self.state = (try? container.decode(String.self, forKey: .state)) ?? (self.suspended ? "suspended" : "offline")
        
        self.memoryUsedMB = (try? container.decode(Double.self, forKey: .memoryUsedMB)) ?? 0
        self.memoryLimitMB = (try? container.decode(Double.self, forKey: .memoryLimitMB)) ?? 0
        self.cpuUsedPercent = (try? container.decode(Double.self, forKey: .cpuUsedPercent)) ?? 0
        self.cpuLimitPercent = (try? container.decode(Double.self, forKey: .cpuLimitPercent)) ?? 0
        self.diskUsedMB = (try? container.decode(Double.self, forKey: .diskUsedMB)) ?? 0
        self.diskLimitMB = (try? container.decode(Double.self, forKey: .diskLimitMB)) ?? 0
    }
}

// Model for Pterodactyl Application API server item returned in /api/v5/init or /api/servers
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
        }
        public let limits: Limits?
        
        enum CodingKeys: String, CodingKey {
            case id, identifier, name, node, suspended, limits
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            if let intId = try? container.decode(Int.self, forKey: .id) {
                self.id = intId
            } else if let strId = try? container.decode(String.self, forKey: .id), let parsed = Int(strId) {
                self.id = parsed
            } else {
                self.id = 0
            }
            
            self.identifier = (try? container.decode(String.self, forKey: .identifier)) ?? "\(self.id)"
            self.name = (try? container.decode(String.self, forKey: .name)) ?? "Server"
            
            if let strNode = try? container.decode(String.self, forKey: .node) {
                self.node = strNode
            } else if let intNode = try? container.decode(Int.self, forKey: .node) {
                self.node = "\(intNode)"
            } else {
                self.node = nil
            }
            
            self.suspended = try? container.decode(Bool.self, forKey: .suspended)
            self.limits = try? container.decode(Limits.self, forKey: .limits)
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
