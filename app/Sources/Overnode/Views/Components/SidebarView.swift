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
    
    public init(selectedTab: Binding<NavigationTab>) {
        self._selectedTab = selectedTab
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Navigation items
            ForEach(NavigationTab.allCases) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(selectedTab == tab ? OvernodeTheme.accentGold : OvernodeTheme.textSecondary)
                            .frame(width: 20)
                        
                        Text(loc.string("nav_\(tab.rawValue)"))
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
            
            // External Links section
            VStack(alignment: .leading, spacing: 8) {
                Text("OVERNODE NETWORK")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(OvernodeTheme.textMuted)
                    .padding(.horizontal, 12)
                
                Link(destination: URL(string: "https://console.overnode.fr")!) {
                    HStack(spacing: 8) {
                        Image(systemName: "safari")
                            .font(.system(size: 12))
                        Text(loc.string("links_console"))
                            .font(.system(size: 11, weight: .medium))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(OvernodeTheme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                
                Link(destination: URL(string: "https://mantle.overnode.fr")!) {
                    HStack(spacing: 8) {
                        Image(systemName: "cpu")
                            .font(.system(size: 12))
                        Text(loc.string("links_mantle"))
                            .font(.system(size: 11, weight: .medium))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(OvernodeTheme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                
                Link(destination: URL(string: "https://overnode.fr")!) {
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                            .font(.system(size: 12))
                        Text(loc.string("links_website"))
                            .font(.system(size: 11, weight: .medium))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(OvernodeTheme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 12)
        }
        .padding(12)
        .frame(width: 200)
        .background(OvernodeTheme.cardBackground)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(OvernodeTheme.border),
            alignment: .trailing
        )
    }
}
