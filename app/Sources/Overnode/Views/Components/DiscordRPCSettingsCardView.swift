import SwiftUI

public struct DiscordRPCSettingsCardView: View {
    @ObservedObject private var rpc = DiscordRPCService.shared
    @ObservedObject private var loc = LocalizationManager.shared
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.345, green: 0.396, blue: 0.949).opacity(0.15))
                        .frame(width: 38, height: 38)
                    Image(systemName: "bubble.left.and.text.bubble.right.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.345, green: 0.396, blue: 0.949))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc.string("settings_discord_rpc_title"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    Text(loc.string("settings_discord_rpc_desc"))
                        .font(.system(size: 12))
                        .foregroundColor(OvernodeTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Status badge (always active)
                HStack(spacing: 6) {
                    Circle()
                        .fill(rpc.isConnected ? Color(red: 0.133, green: 0.773, blue: 0.365) : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(rpc.isConnected ? loc.string("settings_discord_rpc_connected") : loc.string("settings_discord_rpc_waiting"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(rpc.isConnected ? Color(red: 0.133, green: 0.773, blue: 0.365) : Color.orange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background((rpc.isConnected ? Color(red: 0.133, green: 0.773, blue: 0.365) : Color.orange).opacity(0.12))
                .cornerRadius(6)
            }
            
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11))
                        .foregroundColor(OvernodeTheme.accentGold)
                    Text(loc.string("settings_discord_rpc_always_active"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "link")
                        .font(.system(size: 10))
                    Text("overnode.fr")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(OvernodeTheme.accentGold)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(OvernodeTheme.accentGold.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(18)
        .background(OvernodeTheme.cardBackground)
        .cornerRadius(10)
    }
}
