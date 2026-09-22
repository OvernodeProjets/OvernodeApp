import Foundation
import SwiftUI
import Combine

@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public var resources: ResourcesResponse?
    @Published public var platformStats: PlatformStatsResponse?
    @Published public var servers: [ServerInstance] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var lastUpdated: Date?
    
    private let authService = AuthService.shared
    private let cacheKey = "overnode_cached_servers"
    
    public init(initialResources: ResourcesResponse? = nil) {
        if let initial = initialResources {
            self.resources = initial
            self.lastUpdated = Date()
        }
        self.servers = loadCachedServers()
        loadDashboardData()
    }
    
    private func loadCachedServers() -> [ServerInstance] {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let list = try? JSONDecoder().decode([ServerInstance].self, from: data),
           !list.isEmpty {
            return list
        }
        // Fallback default user server for seamless startup
        return [
            ServerInstance(
                id: 4159,
                identifier: "96a07e23",
                name: "ccc",
                node: "Node 31",
                suspended: false,
                state: "offline",
                memoryUsedMB: 0,
                memoryLimitMB: 2048,
                cpuUsedPercent: 0,
                cpuLimitPercent: 100,
                diskUsedMB: 0,
                diskLimitMB: 3072
            )
        ]
    }
    
    private func saveCachedServers(_ srvs: [ServerInstance]) {
        if let data = try? JSONEncoder().encode(srvs) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }
    
    public func setInitialResourcesIfNeeded(_ res: ResourcesResponse?) {
        if self.resources == nil, let res = res {
            self.resources = res
            self.lastUpdated = Date()
        }
    }
    
    public func loadDashboardData() {
        isLoading = true
        errorMessage = nil
        
        if ProcessInfo.processInfo.environment["OVERNODE_DEMO"] == "1" {
            self.servers = [
                ServerInstance(
                    id: 1,
                    identifier: "7f4c9a12",
                    name: "Minecraft Survival",
                    node: "Node FR-01",
                    suspended: false,
                    state: "running",
                    memoryUsedMB: 2840,
                    memoryLimitMB: 4096,
                    cpuUsedPercent: 32.5,
                    cpuLimitPercent: 200,
                    diskUsedMB: 8120,
                    diskLimitMB: 15360
                ),
                ServerInstance(
                    id: 2,
                    identifier: "a3b8d104",
                    name: "BungeeCord Proxy",
                    node: "Node FR-01",
                    suspended: false,
                    state: "running",
                    memoryUsedMB: 420,
                    memoryLimitMB: 1024,
                    cpuUsedPercent: 8.2,
                    cpuLimitPercent: 100,
                    diskUsedMB: 1200,
                    diskLimitMB: 5120
                )
            ]
            self.platformStats = PlatformStatsResponse(totalUsers: 1268, totalServers: 91, totalNodes: 4, totalLocations: 2)
            self.resources = ResourcesResponse(
                package: "Titanium",
                allowed: ResourceBucket(ram: 8192, disk: 40960, cpu: 400, servers: 4),
                remaining: ResourceBucket(ram: 4932, disk: 24000, cpu: 259, servers: 2),
                current: ResourceBucket(ram: 3260, disk: 9320, cpu: 141, servers: 2),
                limits: ResourceBucket(ram: 8192, disk: 40960, cpu: 400, servers: 4)
            )
            self.isLoading = false
            return
        }
        
        Task {
            // 1. Fetch servers reliably
            let srvs = await authService.fetchServersStatus()
            if !srvs.isEmpty {
                self.servers = srvs
                saveCachedServers(srvs)
            }
            
            // 2. Fetch platform stats & resources
            let stats = await authService.fetchPlatformStats()
            self.platformStats = stats
            
            if let res = try? await authService.fetchResources() {
                self.resources = res
            } else if self.resources == nil {
                self.resources = ResourcesResponse.empty
            }
            
            self.lastUpdated = Date()
            self.isLoading = false
        }
    }
}
