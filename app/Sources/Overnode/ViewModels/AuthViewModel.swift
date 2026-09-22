import Foundation
import SwiftUI
import Combine

@MainActor
public final class AuthViewModel: ObservableObject {
    @Published public var isAuthenticated: Bool = false
    @Published public var currentUser: User?
    @Published public var isTwoFactorPending: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var activeWebAuthURL: URL?
    
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
                    self.isTwoFactorPending = false
                } else if state.twoFactorPending == true {
                    self.isTwoFactorPending = true
                    self.isAuthenticated = false
                } else {
                    self.isAuthenticated = false
                    self.currentUser = nil
                    self.isTwoFactorPending = false
                }
            } catch {
                self.isAuthenticated = false
                self.currentUser = nil
                self.isTwoFactorPending = false
            }
            self.isLoading = false
        }
    }
    
    public func loginWithDiscord() {
        errorMessage = nil
        let loginURL = APIClient.shared.baseURL.appendingPathComponent("/auth/discord/login")
        self.activeWebAuthURL = loginURL
    }
    
    public func loginWithPasskey() {
        errorMessage = nil
        let passkeyURL = APIClient.shared.baseURL.appendingPathComponent("/auth")
        self.activeWebAuthURL = passkeyURL
    }
    
    public func onWebAuthCompleted() {
        self.activeWebAuthURL = nil
        checkSession()
    }
    
    public func onWebAuthRequested2FA() {
        self.activeWebAuthURL = nil
        self.isTwoFactorPending = true
    }
    
    public func verifyTwoFactorCode(_ code: String) async throws {
        try await authService.verifyTwoFactor(code: code)
        self.isTwoFactorPending = false
        checkSession()
    }
    
    public func cancelTwoFactor() {
        self.isTwoFactorPending = false
        self.logout()
    }
    
    public func logout() {
        authService.logout()
        isAuthenticated = false
        currentUser = nil
        isTwoFactorPending = false
        activeWebAuthURL = nil
    }
}
