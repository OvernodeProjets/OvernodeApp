import SwiftUI

public struct RootContentView: View {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var updateVM = UpdateViewModel.shared
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Group {
                if authVM.isAuthenticated {
                    DashboardView(authVM: authVM)
                } else {
                    AuthView(authVM: authVM)
                }
            }
            .frame(minWidth: 980, minHeight: 640)
            
            if updateVM.showModal {
                UpdateModalView(vm: updateVM)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: updateVM.showModal)
        .task {
            // Check for updates on application launch
            await updateVM.checkForUpdates(silent: true)
        }
    }
}

