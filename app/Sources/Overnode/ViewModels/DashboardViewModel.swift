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
    private var autoRefreshTask: Task<Void, Never>?
    
    public init(initialResources: ResourcesResponse? = nil) {
        if let initial = initialResources {
            self.resources = initial
            self.lastUpdated = Date()
        }
        self.servers = loadCachedServers()
        loadDashboardData(force: true)
        startAutoRefresh()
    }
    
    deinit {
        autoRefreshTask?.cancel()
    }
    
    public func startAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 20_000_000_000)
                if Task.isCancelled { break }
                self?.loadDashboardData(isBackground: true)
            }
        }
    }
    
    public func stopAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
    }
    
    private func loadCachedServers() -> [ServerInstance] {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let list = try? JSONDecoder().decode([ServerInstance].self, from: data),
           !list.isEmpty {
            return list
        }
        return []
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
    
    public func loadDashboardData(force: Bool = false, isBackground: Bool = false) {
        if isLoading && !force { return }
        if !force, let last = lastUpdated, Date().timeIntervalSince(last) < 2.0 {
            return
        }
        
        if !isBackground {
            isLoading = true
        }
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
            async let srvsTask = authService.fetchServersStatus()
            async let statsTask = authService.fetchPlatformStats()
            async let resTask = authService.fetchResources()
            
            let srvs = await srvsTask
            if !srvs.isEmpty {
                self.servers = srvs
                saveCachedServers(srvs)
            }
            
            let stats = await statsTask
            self.platformStats = stats
            
            if let res = try? await resTask {
                self.resources = res
            } else if self.resources == nil {
                self.resources = ResourcesResponse.empty
            }
            
            self.lastUpdated = Date()
            self.isLoading = false
        }
    }
}
