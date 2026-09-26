import SwiftUI

public struct ServerDetailView: View {
    let server: ServerInstance
    @StateObject private var vm: ServerDetailViewModel
    @ObservedObject var loc = LocalizationManager.shared
    @Binding var selectedTab: ServerTab
    let onBack: () -> Void
    let onServerDeleted: (() -> Void)?
    @State private var showingKillConfirmation = false
    
    public init(
        server: ServerInstance,
        selectedTab: Binding<ServerTab>,
        onBack: @escaping () -> Void,
        onServerDeleted: (() -> Void)? = nil
    ) {
        self.server = server
        self._vm = StateObject(wrappedValue: ServerDetailViewModel(server: server, initialTab: selectedTab.wrappedValue))
        self._selectedTab = selectedTab
        self.onBack = onBack
        self.onServerDeleted = onServerDeleted
    }
    
    public init(
        vm: ServerDetailViewModel,
        selectedTab: Binding<ServerTab>,
        onBack: @escaping () -> Void,
        onServerDeleted: (() -> Void)? = nil
    ) {
        self.server = vm.server
        self._vm = StateObject(wrappedValue: vm)
        self._selectedTab = selectedTab
        self.onBack = onBack
        self.onServerDeleted = onServerDeleted
    }
    
    private var statusColor: Color {
        if vm.server.suspended {
            return Color.red
        }
        switch vm.server.state.lowercased() {
        case "running":
            return Color(red: 0.133, green: 0.773, blue: 0.365) // emerald green
        case "starting", "stopping":
            return Color(red: 0.961, green: 0.620, blue: 0.106) // amber
        default:
            return Color(red: 0.45, green: 0.49, blue: 0.54) // neutral gray
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Server Header with Power Controls
            HStack(spacing: 16) {
                // Server Name & Status dot & Identifier
                HStack(spacing: 10) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    
                    Text(vm.server.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    
                    Text(vm.server.identifier)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(OvernodeTheme.textMuted)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(red: 0.125, green: 0.133, blue: 0.161))
                        .cornerRadius(4)
                    
                    if !vm.server.isOwner {
                        HStack(spacing: 3) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 9))
                            Text(loc.string("server_badge_shared"))
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(Color(red: 0.961, green: 0.620, blue: 0.106))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(red: 0.961, green: 0.620, blue: 0.106).opacity(0.12))
                        .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                // Power Actions Bar
                HStack(spacing: 8) {
                    PowerActionButton(
                        tooltip: vm.server.canStart ? loc.string("power_start") : loc.string("server_permission_denied"),
                        icon: "play.fill",
                        color: Color(red: 0.133, green: 0.773, blue: 0.365),
                        disabled: vm.isPowerLoading || vm.server.state.lowercased() == "running" || !vm.server.canStart
                    ) {
                        vm.sendPowerSignal(.start)
                    }
                    
                    PowerActionButton(
                        tooltip: vm.server.canRestart ? loc.string("power_restart") : loc.string("server_permission_denied"),
                        icon: "arrow.clockwise",
                        color: Color(red: 0.961, green: 0.620, blue: 0.106),
                        disabled: vm.isPowerLoading || vm.server.state.lowercased() != "running" || !vm.server.canRestart
                    ) {
                        vm.sendPowerSignal(.restart)
                    }
                    
                    PowerActionButton(
                        tooltip: vm.server.canStop ? loc.string("power_stop") : loc.string("server_permission_denied"),
                        icon: "stop.fill",
                        color: Color(red: 0.937, green: 0.267, blue: 0.267),
                        disabled: vm.isPowerLoading || vm.server.state.lowercased() == "offline" || !vm.server.canStop
                    ) {
                        vm.sendPowerSignal(.stop)
                    }
                    
                    PowerActionButton(
                        tooltip: vm.server.canStop ? loc.string("power_kill") : loc.string("server_permission_denied"),
                        icon: "bolt.slash.fill",
                        color: Color(red: 0.60, green: 0.15, blue: 0.15),
                        disabled: vm.isPowerLoading || !vm.server.canStop
                    ) {
                        showingKillConfirmation = true
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(OvernodeTheme.cardBackground)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(OvernodeTheme.borderSubtle),
                alignment: .bottom
            )
            
            // Tab Content Body
            ScrollView {
                VStack(spacing: 0) {
                    switch selectedTab {
                    case .console:
                        ServerConsoleTabView(vm: vm)
                    case .renewal:
                        ServerRenewalTabView(vm: vm)
                    case .files:
                        ServerFilesTabView(vm: vm)
                    case .subdomains:
                        ServerSubdomainsTabView(vm: vm)
                    case .subusers:
                        ServerSubusersTabView(vm: vm)
                    case .package:
                        ServerPackageTabView(vm: vm)
                    case .plugins:
                        ServerPluginsTabView(vm: vm)
                    case .logs:
                        ServerLogsTabView(vm: vm)
                    case .settings:
                        ServerSettingsTabView(vm: vm, onServerDeleted: onServerDeleted)
                    }
                }
                .padding(24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(OvernodeTheme.background)
        }
        .onChange(of: selectedTab) { _, newTab in
            vm.selectedTab = newTab
            vm.loadCurrentTabData()
        }
        .onChange(of: server) { _, newServer in
            vm.updateServer(newServer)
        }
        .confirmationDialog(
            loc.string("power_kill_confirm_title"),
            isPresented: $showingKillConfirmation,
            titleVisibility: .visible
        ) {
            Button(loc.string("power_kill"), role: .destructive) {
                vm.sendPowerSignal(.kill)
            }
            Button(loc.string("generic_cancel"), role: .cancel) {}
        } message: {
            Text(loc.string("power_kill_confirm_msg"))
        }
    }
}

private struct PowerActionButton: View {
    let tooltip: String
    let icon: String
    let color: Color
    let disabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(disabled ? OvernodeTheme.textMuted : Color.white)
                .frame(width: 32, height: 32)
                .background(disabled ? Color.white.opacity(0.04) : color.opacity(0.85))
                .cornerRadius(7)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .help(tooltip)
    }
}
