import SwiftUI

public struct CreateServerModalView: View {
    @ObservedObject var loc = LocalizationManager.shared
    @StateObject private var vm: CreateServerViewModel
    let onDismiss: () -> Void
    let onServerCreated: (ServerInstance) -> Void
    
    public init(
        vm: CreateServerViewModel? = nil,
        onDismiss: @escaping () -> Void,
        onServerCreated: @escaping (ServerInstance) -> Void
    ) {
        if let customVM = vm {
            self._vm = StateObject(wrappedValue: customVM)
        } else {
            self._vm = StateObject(wrappedValue: CreateServerViewModel())
        }
        self.onDismiss = onDismiss
        self.onServerCreated = onServerCreated
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            CreateServerHeaderView(onDismiss: onDismiss)
            
            if vm.isLoading {
                loadingView
            } else {
                contentScrollView
            }
            
            CreateServerBottomBarView(
                vm: vm,
                onDismiss: onDismiss,
                onDeploy: {
                    Task {
                        if let newServer = await vm.deployServer() {
                            onServerCreated(newServer)
                            onDismiss()
                        }
                    }
                }
            )
        }
        .frame(width: 820, height: 740)
        .background(OvernodeTheme.background)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(OvernodeTheme.borderSubtle, lineWidth: 1)
        )
    }
    
    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .scaleEffect(1.2)
            Text(loc.string("create_server_loading"))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(OvernodeTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var contentScrollView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 22) {
                quotaAlertIfNeeded
                
                CreateServerGeneralInfoSectionView(vm: vm)
                
                CreateServerLocationSectionView(vm: vm)
                
                CreateServerSoftwareSectionView(vm: vm)
                
                CreateServerResourceSectionView(vm: vm)
                
                errorMessageBanner
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var quotaAlertIfNeeded: some View {
        if let rem = vm.options?.resources.remaining, rem.servers <= 0 {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(OvernodeTheme.accentDanger)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc.string("create_server_quota_exceeded"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    Text(loc.string("create_server_quota_exceeded_desc"))
                        .font(.system(size: 11.5))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                
                Spacer()
            }
            .padding(14)
            .background(Color.red.opacity(0.12))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    @ViewBuilder
    private var errorMessageBanner: some View {
        if let err = vm.errorMessage {
            HStack(spacing: 10) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(OvernodeTheme.accentDanger)
                Text(err)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(OvernodeTheme.accentDanger)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.12))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
