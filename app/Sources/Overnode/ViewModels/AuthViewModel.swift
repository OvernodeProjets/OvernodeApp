import Foundation
import SwiftUI
import Combine

@MainActor
public final class AuthViewModel: ObservableObject {
    @Published public var isAuthenticated: Bool = false
    @Published public var currentUser: User?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    private let authService = AuthService.shared
    private let discordCoordinator = DiscordAuthCoordinator.shared
    private let passkeyCoordinator = PasskeyCoordinator.shared
    
    public init() {
        checkSession()
    }
    
    public func checkSession() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let state = try await authService.checkAuthState()
                if state.authenticated, let user = state.user {
                    self.isAuthenticated = true
                    self.currentUser = user
                } else {
                    self.isAuthenticated = false
                    self.currentUser = nil
                }
            } catch {
                self.isAuthenticated = false
                self.currentUser = nil
            }
            self.isLoading = false
        }
    }
    
    public func loginWithDiscord() {
        isLoading = true
        errorMessage = nil
        
        discordCoordinator.startDiscordAuth { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success:
                    self?.checkSession()
                case .failure(let error):
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    public func loginWithPasskey() {
        isLoading = true
        errorMessage = nil
        
        passkeyCoordinator.startPasskeyAuth { [weak self] result in
            Task { @MainActor in
                self?.isLoading = false
                switch result {
                case .success(let state):
                    if state.authenticated, let user = state.user {
                        self?.isAuthenticated = true
                        self?.currentUser = user
                    } else {
                        self?.checkSession()
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    public func logout() {
        authService.logout()
        isAuthenticated = false
        currentUser = nil
    }
    
    public func setDemoUser() {
        self.currentUser = User(id: 1, username: "OvernodeAdmin", email: "admin@overnode.fr", role: "admin")
        self.isAuthenticated = true
    }
}
