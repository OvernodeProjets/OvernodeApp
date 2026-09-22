import Foundation

public struct ServerInstance: Codable, Identifiable, Equatable {
    public let id: Int
    public let identifier: String
    public let name: String
    public let node: String?
    public let suspended: Bool
    public let state: String // "running", "starting", "stopping", "offline", "suspended"
    public let memoryUsedMB: Double
    public let memoryLimitMB: Double
    public let cpuUsedPercent: Double
    public let cpuLimitPercent: Double
    public let diskUsedMB: Double
    public let diskLimitMB: Double
    
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
    
    public var isStartingOrStopping: Bool {
        let s = state.lowercased()
        return s == "starting" || s == "stopping"
    }
}
