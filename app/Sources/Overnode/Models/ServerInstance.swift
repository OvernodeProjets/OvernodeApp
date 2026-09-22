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
