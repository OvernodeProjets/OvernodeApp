import SwiftUI

public struct ServerSettingsTabView: View {
    @ObservedObject var vm: ServerDetailViewModel
    @ObservedObject var loc = LocalizationManager.shared
    @State private var showingReinstallAlert = false
    
    public init(vm: ServerDetailViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Section 1: Rename Server
                VStack(alignment: .leading, spacing: 14) {
                    Text(loc.string("settings_rename_title"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    
                    HStack(spacing: 10) {
                        TextField(loc.string("settings_name_placeholder"), text: $vm.serverRenameText)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13))
                        
                        Button(action: {
                            let n = vm.serverRenameText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !n.isEmpty else { return }
                            Task { await vm.renameServer(newName: n) }
                        }) {
                            Text(loc.string("settings_rename_button"))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(OvernodeTheme.accentGold)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
                .background(OvernodeTheme.cardBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                
                // Section 2: Startup Variables (Paramètres de démarrage)
                if !vm.startupVariables.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(loc.string("settings_variables_title"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(OvernodeTheme.textPrimary)
                        
                        VStack(spacing: 10) {
                            ForEach($vm.startupVariables) { $variable in
                                VariableRowView(variable: $variable) { key, val in
                                    Task { await vm.updateStartupVariable(key: key, value: val) }
                                }
                            }
                        }
                    }
                    .padding(18)
                    .background(OvernodeTheme.cardBackground)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                }
                
                // Section 3: Danger Zone (Reinstall)
                VStack(alignment: .leading, spacing: 14) {
                    Text(loc.string("settings_danger_zone"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 0.95, green: 0.35, blue: 0.35))
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(loc.string("settings_reinstall_title"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(OvernodeTheme.textPrimary)
                            Text(loc.string("settings_reinstall_desc"))
                                .font(.system(size: 11))
                                .foregroundColor(OvernodeTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button(role: .destructive, action: {
                            showingReinstallAlert = true
                        }) {
                            Text(loc.string("settings_reinstall_button"))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(Color(red: 0.90, green: 0.25, blue: 0.25))
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
                .background(OvernodeTheme.cardBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(.bottom, 24)
        }
        .confirmationDialog(
            loc.string("settings_reinstall_confirm_title"),
            isPresented: $showingReinstallAlert,
            titleVisibility: .visible
        ) {
            Button(loc.string("settings_reinstall_confirm_btn"), role: .destructive) {
                Task { await vm.reinstallServer() }
            }
            Button(loc.string("generic_cancel"), role: .cancel) {}
        } message: {
            Text(loc.string("settings_reinstall_confirm_msg"))
        }
        .onAppear {
            Task { await vm.loadSettings() }
        }
    }
}

private struct VariableRowView: View {
    @Binding var variable: ServerStartupVariable
    let onSave: (String, String) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(variable.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(OvernodeTheme.textPrimary)
                Text(variable.envVariable)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(OvernodeTheme.textSecondary)
            }
            .frame(width: 160, alignment: .leading)
            
            TextField(variable.defaultValue ?? "", text: $variable.serverValue)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12, design: .monospaced))
            
            Button(action: {
                onSave(variable.envVariable, variable.serverValue)
            }) {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(Color(red: 0.25, green: 0.78, blue: 0.50))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

