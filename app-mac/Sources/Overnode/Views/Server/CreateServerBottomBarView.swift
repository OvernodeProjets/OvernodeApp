import SwiftUI

public struct CreateServerBottomBarView: View {
    @ObservedObject var loc = LocalizationManager.shared
    @ObservedObject var vm: CreateServerViewModel
    let onDismiss: () -> Void
    let onDeploy: () -> Void
    
    public init(vm: CreateServerViewModel, onDismiss: @escaping () -> Void, onDeploy: @escaping () -> Void) {
        self.vm = vm
        self.onDismiss = onDismiss
        self.onDeploy = onDeploy
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            Button(action: onDismiss) {
                Text(loc.string("btn_cancel"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(OvernodeTheme.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button(action: onDeploy) {
                HStack(spacing: 8) {
                    if vm.isDeploying {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                    Text(loc.string("create_server_action_deploy"))
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(vm.canDeploy ? Color.black : OvernodeTheme.textMuted)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(vm.canDeploy ? OvernodeTheme.accentGold : Color.white.opacity(0.08))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(!vm.canDeploy || vm.isDeploying)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(OvernodeTheme.cardBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(OvernodeTheme.borderSubtle),
            alignment: .top
        )
    }
}

