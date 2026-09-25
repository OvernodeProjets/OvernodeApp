import SwiftUI

public struct QuickActionSettingsCardView: View {
    @ObservedObject var loc = LocalizationManager.shared
    let servers: [ServerInstance]
    @State private var selectedServerId: String = ""
    
    public init(servers: [ServerInstance]) {
        self.servers = servers
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(OvernodeTheme.accentGold.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "menubar.rectangle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(OvernodeTheme.accentGold)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc.string("settings_quickaction_title"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    Text(loc.string("settings_quickaction_desc"))
                        .font(.system(size: 12))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
            }
            
            Divider()
                .background(OvernodeTheme.borderSubtle)
            
            if servers.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(OvernodeTheme.accentGold)
                    Text(loc.string("settings_quickaction_no_servers"))
                        .font(.system(size: 13))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                .padding(.vertical, 4)
            } else {
                HStack(spacing: 16) {
                    Text(loc.string("settings_quickaction_select_label"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    
                    Spacer()
                    
                    Picker("", selection: $selectedServerId) {
                        Text(loc.string("settings_quickaction_none")).tag("")
                        ForEach(servers) { srv in
                            Text("\(srv.name) (\(srv.identifier))").tag(srv.identifier)
                        }
                    }
                    .labelsHidden()
                    .frame(minWidth: 220)
                    .onChange(of: selectedServerId) { _, newValue in
                        QuickActionServerStorage.shared.setSelectedServerIdentifier(newValue.isEmpty ? nil : newValue)
                    }
                }
                
                if let current = servers.first(where: { $0.identifier == selectedServerId || String($0.id) == selectedServerId }) {
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(statusColor(for: current.state))
                                .frame(width: 8, height: 8)
                            Text("\(loc.string("settings_quickaction_status_label")): \(current.state.capitalized)")
                                .font(.system(size: 12))
                                .foregroundColor(OvernodeTheme.textSecondary)
                        }
                        
                        Text("•")
                            .foregroundColor(OvernodeTheme.textMuted)
                        
                        Text("RAM: \(Int(current.memoryLimitMB)) MB")
                            .font(.system(size: 12))
                            .foregroundColor(OvernodeTheme.textSecondary)
                        
                        Text("•")
                            .foregroundColor(OvernodeTheme.textMuted)
                        
                        Text("CPU: \(Int(current.cpuLimitPercent))%")
                            .font(.system(size: 12))
                            .foregroundColor(OvernodeTheme.textSecondary)
                    }
                    .padding(10)
                    .background(OvernodeTheme.secondaryCardBackground)
                    .cornerRadius(8)
                }
            }
        }
        .padding(18)
        .background(OvernodeTheme.cardBackground)
        .cornerRadius(10)
        .onAppear {
            self.selectedServerId = QuickActionServerStorage.shared.getSelectedServerIdentifier() ?? ""
        }
    }
    
    private func statusColor(for state: String) -> Color {
        switch state.lowercased() {
        case "running": return OvernodeTheme.accentSuccess
        case "starting", "stopping": return OvernodeTheme.accentWarning
        default: return OvernodeTheme.accentDanger
        }
    }
}
