import SwiftUI

public enum NavigationTab: String, CaseIterable, Identifiable {
    case dashboard = "dashboard"
    case servers = "servers"
    case settings = "settings"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .servers: return "server.rack"
        case .settings: return "gearshape"
        }
    }
}

public struct SidebarView: View {
    @ObservedObject var loc = LocalizationManager.shared
    @Binding var selectedTab: NavigationTab
    let user: User?
    let onLogout: () -> Void
    
    public init(
        selectedTab: Binding<NavigationTab>,
        user: User?,
        onLogout: @escaping () -> Void
    ) {
        self._selectedTab = selectedTab
        self.user = user
        self.onLogout = onLogout
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Navigation items
            ForEach(NavigationTab.allCases) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(selectedTab == tab ? Color.white : OvernodeTheme.textSecondary)
                            .frame(width: 20)
                        
                        Text(loc.string("nav_(tab.rawValue)"))
                            .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .medium))
                            .foregroundColor(selectedTab == tab ? OvernodeTheme.textPrimary : OvernodeTheme.textSecondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedTab == tab ? Color.white.opacity(0.08) : Color.clear)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            // Bottom section: User Profile Pill with Menu + Coins Display
            if let user = user {
                VStack(spacing: 8) {
                    // Overnode Credits Pill (Solid, sleek style)
                    HStack(spacing: 6) {
                        Image(systemName: "circle.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(OvernodeTheme.accentGold)
                        
                        Text("(user.coins)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(OvernodeTheme.textPrimary)
                        
                        Text(loc.string("coins_balance"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(OvernodeTheme.textSecondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color(red: 0.125, green: 0.133, blue: 0.161)) // #202229
                    .cornerRadius(8)
                    
                    // User Profile Menu (Clicking user menu reveals Sign Out)
                    Menu {
                        VStack {
                            Text(user.username)
                                .font(.headline)
                            if !user.email.isEmpty {
                                Text(user.email)
                                    .font(.caption)
                            }
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: onLogout) {
                            Label(loc.string("nav_logout"), systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(String(user.username.prefix(1)).uppercased())
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(OvernodeTheme.textPrimary)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.username)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(OvernodeTheme.textPrimary)
                                    .lineLimit(1)
                                
                                if !user.email.isEmpty {
                                    Text(user.email)
                                        .font(.system(size: 10))
                                        .foregroundColor(OvernodeTheme.textMuted)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "ellipsis")
                                .font(.system(size: 11))
                                .foregroundColor(OvernodeTheme.textMuted)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.125, green: 0.133, blue: 0.161)) // #202229
                        .cornerRadius(8)
                    }
                    .menuStyle(.borderlessButton)
                }
                .padding(.bottom, 8)
            }
        }
        .padding(12)
        .frame(width: 220)
        .background(OvernodeTheme.cardBackground)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(OvernodeTheme.borderSubtle),
            alignment: .trailing
        )
    }
}
