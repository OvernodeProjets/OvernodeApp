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
            // Navigation tabs
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
            
            // Toledo style Single Integrated Account & Credits Card
            if let user = user {
                VStack(spacing: 0) {
                    // Top row: Coins balance
                    HStack(spacing: 6) {
                        Image(systemName: "circle.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(OvernodeTheme.accentGold)
                        
                        Text("\(user.coins)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(OvernodeTheme.textPrimary)
                        
                        Text(loc.string("coins_balance"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(OvernodeTheme.textSecondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 10)
                    
                    Divider()
                        .background(Color.white.opacity(0.06))
                    
                    // Bottom row: User profile + clickable popover/contextual menu with full username
                    Menu {
                        Section {
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
                            // Rounded initials avatar (Toledo h-7 w-7 rounded-lg style)
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(red: 0.098, green: 0.106, blue: 0.125)) // #191b20
                                    .frame(width: 28, height: 28)
                                Text(String(user.username.prefix(1)).uppercased())
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color.white.opacity(0.8))
                            }
                            
                            // Full username and email cleanly displayed
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.username)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(OvernodeTheme.textPrimary)
                                    .lineLimit(1)
                                
                                if !user.email.isEmpty {
                                    Text(user.email)
                                        .font(.system(size: 10))
                                        .foregroundColor(Color(red: 0.584, green: 0.631, blue: 0.678)) // #95a1ad
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer(minLength: 4)
                            
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.35))
                        }
                        .contentShape(Rectangle())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                }
                .background(Color(red: 0.125, green: 0.133, blue: 0.161)) // #202229
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(red: 0.180, green: 0.200, blue: 0.216).opacity(0.5), lineWidth: 1)
                )
                .padding(.bottom, 6)
            }
        }
        .padding(12)
        .frame(width: 230)
        .background(OvernodeTheme.cardBackground)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(OvernodeTheme.borderSubtle),
            alignment: .trailing
        )
    }
}
