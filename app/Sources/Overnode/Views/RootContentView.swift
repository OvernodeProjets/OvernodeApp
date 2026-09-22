import SwiftUI

public struct RootContentView: View {
    @StateObject private var authVM = AuthViewModel()
    
    public init() {}
    
    public var body: some View {
        Group {
            if authVM.isAuthenticated {
                DashboardView(authVM: authVM)
            } else if authVM.isTwoFactorPending {
                TwoFactorVerificationView(authVM: authVM)
            } else {
                AuthView(authVM: authVM)
            }
        }
        .frame(minWidth: 980, minHeight: 640)
    }
}
