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
    private var autoRefreshTask: Task<Void, Never>?
    
    public init(initialResources: ResourcesResponse? = nil) {
        if let initial = initialResources {
            self.resources = initial
            self.lastUpdated = Date()
        }
        loadDashboardData(force: true)
        startAutoRefresh()
    }
    
    deinit {
        autoRefreshTask?.cancel()
    }
    
    public func setInitialResourcesIfNeeded(_ res: ResourcesResponse?) {
        if self.resources == nil, let res = res {
            self.resources = res
            self.lastUpdated = Date()
        }
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
    
    public func loadDashboardData(force: Bool = false, isBackground: Bool = false) {
        if isLoading && !force { return }
        if !force, let last = lastUpdated, Date().timeIntervalSince(last) < 2.0 {
            return
        }
        
        if !isBackground {
            isLoading = true
        }
        errorMessage = nil
        
        Task {
            // Concurrently fetch servers, platform statistics, and account resources
            async let srvsTask = authService.fetchServersStatus()
            async let statsTask = authService.fetchPlatformStats()
            async let resTask = authService.fetchResources()
            
            // Progressive assignment as results resolve
            let srvs = await srvsTask
            self.servers = srvs
            
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
