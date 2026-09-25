import Foundation
import SwiftUI
import Combine

@MainActor
public final class AuthViewModel: ObservableObject {
    @Published public var isAuthenticated: Bool = false
    @Published public var currentUser: User?
    @Published public var initialResources: ResourcesResponse?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var activeWebAuthURL: URL?
    @Published public var isPasskeyMode: Bool = false
    
    private let authService = AuthService.shared
    
    public init() {
        if ProcessInfo.processInfo.environment["OVERNODE_DEMO"] == "1" {
            self.currentUser = User(id: "1", username: "OvernodeUser", email: "user@overnode.fr", globalName: "Overnode User", role: "Client", avatarUrl: nil, coins: 350)
            self.isAuthenticated = true
            return
        }
        checkSession()
    }
    
    public func checkSession() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let initData = try await authService.fetchInit()
                if let u = initData.user {
                    self.currentUser = User(
                        id: u.id,
                        username: u.username,
                        email: u.email.isEmpty ? (u.pterodactylEmail ?? "") : u.email,
                        globalName: u.globalName,
                        role: initData.roles?.first?.name,
                        avatarUrl: nil,
                        coins: initData.coins ?? 0
                    )
                    self.isAuthenticated = true
                    DailyRewardSyncManager.shared.sync()
                } else {
                    self.isAuthenticated = false
                    self.currentUser = nil
                    DailyRewardSyncManager.shared.onLogout()
                }
            } catch {
                // If /api/v5/init fails, fallback to checking /api/v5/state
                do {
                    let state = try await authService.checkAuthState()
                    if state.authenticated, let user = state.user {
                        self.isAuthenticated = true
                        self.currentUser = user
                        // Try fetching coins
                        if let coins = try? await authService.fetchCoins() {
                            self.currentUser?.coins = coins
                        }
                        DailyRewardSyncManager.shared.sync()
                    } else {
                        self.isAuthenticated = false
                        self.currentUser = nil
                        DailyRewardSyncManager.shared.onLogout()
                    }
                } catch {
                    self.isAuthenticated = false
                    self.currentUser = nil
                    DailyRewardSyncManager.shared.onLogout()
                }
            }
            self.isLoading = false
        }
    }
    
    public func loginWithDiscord() {
        errorMessage = nil
        isPasskeyMode = false
        let loginURL = APIClient.shared.baseURL.appendingPathComponent("/auth/discord/login")
        self.activeWebAuthURL = loginURL
    }
    
    public func loginWithPasskey() {
        errorMessage = nil
        isPasskeyMode = true
        let passkeyURL = APIClient.shared.baseURL.appendingPathComponent("/auth")
        self.activeWebAuthURL = passkeyURL
    }
    
    public func onWebAuthCompleted(with user: User, resources: ResourcesResponse?) {
        self.currentUser = user
        self.initialResources = resources
        self.isAuthenticated = true
        self.activeWebAuthURL = nil
        self.isPasskeyMode = false
        self.isLoading = false
        DailyRewardSyncManager.shared.sync()
    }
    
    public func logout() {
        authService.logout()
        isAuthenticated = false
        currentUser = nil
        initialResources = nil
        activeWebAuthURL = nil
        isPasskeyMode = false
        DailyRewardSyncManager.shared.onLogout()
    }
}
