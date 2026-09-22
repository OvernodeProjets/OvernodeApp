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
            async let resTask = authService.fetchResources()
            async let statsTask = authService.fetchPlatformStats()
            async let serversTask = authService.fetchServersStatus()
            
            do {
                let (res, stats, srvs) = try await (resTask, statsTask, serversTask)
                self.resources = res
                self.platformStats = stats
                self.servers = srvs
                self.lastUpdated = Date()
            } catch {
                if let res = try? await authService.fetchResources() {
                    self.resources = res
                } else if self.resources == nil {
                    self.resources = ResourcesResponse.empty
                }
                
                if let stats = try? await authService.fetchPlatformStats() {
                    self.platformStats = stats
                }
                
                if let srvs = try? await authService.fetchServersStatus() {
                    self.servers = srvs
                }
                
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }
}
