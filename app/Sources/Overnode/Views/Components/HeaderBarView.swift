import SwiftUI

public struct HeaderBarView: View {
    @ObservedObject var loc = LocalizationManager.shared
    let user: User?
    let onLogout: () -> Void
    let onRefresh: () -> Void
    
    public init(user: User?, onLogout: @escaping () -> Void, onRefresh: @escaping () -> Void) {
        self.user = user
        self.onLogout = onLogout
        self.onRefresh = onRefresh
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            // Brand Logo & Status
            HStack(spacing: 12) {
                if let logoURL = Bundle.module.url(forResource: "overnode_logo", withExtension: "png"),
                   let nsImage = NSImage(contentsOf: logoURL) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 26)
                } else {
                    Image(systemName: "server.rack")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(OvernodeTheme.accentGold)
                }
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(OvernodeTheme.accentSuccess)
                        .frame(width: 7, height: 7)
                    
                    Text(loc.string("status_connected"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
            }
            
            Spacer()
            
            // Real Coins Balance Pill
            if let user = user {
                HStack(spacing: 6) {
                    Image(systemName: "circle.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(OvernodeTheme.accentGold)
                    
                    Text("\(user.coins)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    
                    Text(loc.string("coins_balance"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(OvernodeTheme.secondaryCardBackground)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(OvernodeTheme.border, lineWidth: 1)
                )
            }
            
            // Language Switcher
            HStack(spacing: 4) {
                ForEach(AppLanguage.allCases) { lang in
                    Button(action: {
                        loc.setLanguage(lang)
                    }) {
                        HStack(spacing: 4) {
                            Text(lang.flag)
                                .font(.system(size: 12))
                            Text(lang.rawValue.uppercased())
                                .font(.system(size: 11, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(loc.currentLanguage == lang ? Color.white.opacity(0.15) : Color.clear)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(loc.currentLanguage == lang ? OvernodeTheme.textPrimary : OvernodeTheme.textSecondary)
                }
            }
            .padding(3)
            .background(OvernodeTheme.secondaryCardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(OvernodeTheme.border, lineWidth: 1)
            )
            
            // Refresh Button
            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(OvernodeTheme.textSecondary)
                    .padding(8)
                    .background(OvernodeTheme.secondaryCardBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(OvernodeTheme.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help(loc.string("status_refresh"))
            
            // Real User Profile Pill (Avatar initial + Username + Real Email)
            if let user = user {
                HStack(spacing: 8) {
                    Circle()
                        .fill(OvernodeTheme.accentGold.opacity(0.2))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(String(user.username.prefix(1)).uppercased())
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(OvernodeTheme.accentGold)
                        )
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(user.username)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(OvernodeTheme.textPrimary)
                        
                        if !user.email.isEmpty {
                            Text(user.email)
                                .font(.system(size: 10))
                                .foregroundColor(OvernodeTheme.textMuted)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(OvernodeTheme.secondaryCardBackground)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(OvernodeTheme.border, lineWidth: 1)
                )
            }
            
            // Logout Button
            Button(action: onLogout) {
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 12))
                    Text(loc.string("nav_logout"))
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(OvernodeTheme.accentDanger)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(OvernodeTheme.accentDanger.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(OvernodeTheme.accentDanger.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(OvernodeTheme.cardBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(OvernodeTheme.border),
            alignment: .bottom
        )
    }
}
