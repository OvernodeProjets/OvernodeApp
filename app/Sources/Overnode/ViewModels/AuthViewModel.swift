import Foundation
import SwiftUI
import Combine

@MainActor
public final class AuthViewModel: ObservableObject {
    @Published public var isAuthenticated: Bool = false
    @Published public var currentUser: User?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var activeWebAuthURL: URL?
    @Published public var isPasskeyMode: Bool = false
    
    private let authService = AuthService.shared
    
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
    
    public func onWebAuthCompleted() {
        self.activeWebAuthURL = nil
        self.isPasskeyMode = false
        checkSession()
    }
    
    public func logout() {
        authService.logout()
        isAuthenticated = false
        currentUser = nil
        activeWebAuthURL = nil
        isPasskeyMode = false
    }
}
