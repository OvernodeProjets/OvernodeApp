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
    
    public init() {
        loadResources()
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
                // If not authenticated or offline, provide preview/fallback
                if self.resources == nil {
                    self.resources = ResourcesResponse.preview
                }
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }
}
