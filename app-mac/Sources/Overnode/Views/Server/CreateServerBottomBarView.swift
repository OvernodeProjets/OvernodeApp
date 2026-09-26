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
        HStack(spacing: 16) {
            summaryView
            
            Spacer()
            
            cancelButton
            deployButton
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(OvernodeTheme.cardBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(OvernodeTheme.borderSubtle),
            alignment: .top
        )
    }
    
    @ViewBuilder
    private var summaryView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                if let locItem = vm.selectedLocation {
                    let info = LocationHelper.format(location: locItem)
                    HStack(spacing: 4) {
                        Text(info.flag)
                        Text(info.countryName)
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(OvernodeTheme.textPrimary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(6)
                }
                
                if let egg = vm.selectedEgg {
                    HStack(spacing: 4) {
                        Image(systemName: egg.iconName)
                            .font(.system(size: 10))
                            .foregroundColor(OvernodeTheme.accentGold)
                        Text(egg.name)
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(OvernodeTheme.textPrimary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(6)
                }
                
                if let remServers = vm.options?.resources.remaining.servers {
                    HStack(spacing: 4) {
                        Image(systemName: "server.rack")
                            .font(.system(size: 10))
                        Text("\(loc.string("create_server_servers_remaining")) : \(remServers)")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(remServers > 0 ? OvernodeTheme.textSecondary : OvernodeTheme.accentDanger)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(remServers > 0 ? Color.white.opacity(0.04) : Color.red.opacity(0.12))
                    .cornerRadius(6)
                }
            }
        }
    }
    
    private var cancelButton: some View {
        Button(action: onDismiss) {
            Text(loc.string("btn_cancel"))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(OvernodeTheme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(Color.white.opacity(0.06))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(OvernodeTheme.borderSubtle, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
    
    private var deployButton: some View {
        Button(action: onDeploy) {
            HStack(spacing: 8) {
                if vm.isDeploying {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                }
                Text(loc.string("create_server_action_deploy"))
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(vm.canDeploy ? Color.black : OvernodeTheme.textMuted)
            .padding(.horizontal, 22)
            .padding(.vertical, 9)
            .background(vm.canDeploy ? AnyShapeStyle(OvernodeTheme.goldGradient) : AnyShapeStyle(Color.white.opacity(0.08)))
            .cornerRadius(8)
            .shadow(color: vm.canDeploy ? OvernodeTheme.accentGold.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(!vm.canDeploy || vm.isDeploying)
    }
}
