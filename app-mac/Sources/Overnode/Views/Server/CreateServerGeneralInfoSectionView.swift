import SwiftUI

public struct CreateServerGeneralInfoSectionView: View {
    @ObservedObject var loc = LocalizationManager.shared
    @ObservedObject var vm: CreateServerViewModel
    
    public init(vm: CreateServerViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "server.rack")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(OvernodeTheme.accentGold)
                
                Text(loc.string("create_server_name_label"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(OvernodeTheme.textPrimary)
                
                Spacer()
                
                if !vm.serverName.isEmpty {
                    if vm.isNameValid {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(OvernodeTheme.accentSuccess)
                            Text(loc.string("create_server_name_valid"))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(OvernodeTheme.accentSuccess)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(OvernodeTheme.accentDanger)
                            Text(loc.string("create_server_name_invalid_chars"))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(OvernodeTheme.accentDanger)
                        }
                    }
                }
            }
            
            HStack(spacing: 10) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 13))
                    .foregroundColor(vm.serverName.isEmpty ? OvernodeTheme.textMuted : OvernodeTheme.accentGold)
                
                TextField(loc.string("create_server_name_placeholder"), text: $vm.serverName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                
                if !vm.serverName.isEmpty {
                    Button(action: { vm.serverName = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(OvernodeTheme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(OvernodeTheme.secondaryCardBackground)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        vm.serverName.isEmpty ? OvernodeTheme.borderSubtle :
                        (vm.isNameValid ? OvernodeTheme.accentGold.opacity(0.8) : Color.red.opacity(0.7)),
                        lineWidth: vm.serverName.isEmpty ? 1 : 1.5
                    )
            )
        }
    }
}
