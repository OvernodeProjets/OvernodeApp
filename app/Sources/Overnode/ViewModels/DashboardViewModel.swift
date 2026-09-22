import Foundation
import SwiftUI
import Combine

@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public var resources: ResourcesResponse?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var lastUpdated: Date?
    
    private let authService = AuthService.shared
    
    public init(initialResources: ResourcesResponse? = nil) {
        if let initial = initialResources {
            self.resources = initial
            self.lastUpdated = Date()
        }
        loadResources()
    }
    
    public func setInitialResourcesIfNeeded(_ res: ResourcesResponse?) {
        if self.resources == nil, let res = res {
            self.resources = res
            self.lastUpdated = Date()
        }
    }
    
    public func loadResources() {
        isLoading = true
        errorMessage = nil
        
       Task {
           do {
               let data = try await authService.fetchResources()
               self.resources = data
               self.lastUpdated = Date()
           } catch {
               if self.resources == nil {
                    self.resources = ResourcesResponse.empty
               }
               self.errorMessage = error.localizedDescription
           }
           self.isLoading = false
       }
    }
}
