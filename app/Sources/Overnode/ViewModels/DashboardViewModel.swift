import Foundation
import SwiftUI
import Combine

@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public var resources: ResourcesResponse?
    @Published public var platformStats: PlatformStatsResponse?
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
            
            do {
                let (res, stats) = try await (resTask, statsTask)
                self.resources = res
                self.platformStats = stats
                self.lastUpdated = Date()
            } catch {
                // If parallel load fails, fallback to individually trying resources
                if let res = try? await authService.fetchResources() {
                    self.resources = res
                } else if self.resources == nil {
                    self.resources = ResourcesResponse.empty
                }
                
                if let stats = try? await authService.fetchPlatformStats() {
                    self.platformStats = stats
                }
                
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }
}
