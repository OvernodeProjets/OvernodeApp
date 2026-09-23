import Foundation

public struct PlatformStatsResponse: Codable, Equatable, Sendable {
    public let totalUsers: Int?
    public let totalServers: Int?
    public let totalNodes: Int?
    public let totalLocations: Int?
    
    public init(
        totalUsers: Int? = 0,
        totalServers: Int? = 0,
        totalNodes: Int? = 0,
        totalLocations: Int? = 0
    ) {
        self.totalUsers = totalUsers
        self.totalServers = totalServers
        self.totalNodes = totalNodes
        self.totalLocations = totalLocations
    }
}
