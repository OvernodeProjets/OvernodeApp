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
    
    public init(initialResources: ResourcesResponse? = nil) {
        if let initial = initialResources {
            self.resources = initial
            self.lastUpdated = Date()
        }
        loadDashboardData()
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
        
        Task {
            // 1. Fetch servers reliably
            let srvs = await authService.fetchServersStatus()
            self.servers = srvs
            
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
