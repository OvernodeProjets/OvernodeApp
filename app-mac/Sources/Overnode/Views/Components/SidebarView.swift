import SwiftUI

public enum NavigationTab: String, CaseIterable, Identifiable {
    case dashboard = "dashboard"
    case servers = "servers"
    case wallet = "wallet"
    case dailyReward = "daily_reward"
    case store = "store"
    case support = "support"
    case afk = "afk"
    case settings = "settings"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .servers: return "server.rack"
        case .wallet: return "creditcard"
        case .dailyReward: return "gift.fill"
        case .store: return "bag"
        case .support: return "bubble.left.and.bubble.right"
        case .afk: return "clock.arrow.circlepath"
        case .settings: return "gearshape"
        }
    }
}

public struct SidebarView: View {
    @ObservedObject var loc = LocalizationManager.shared
    @Binding var selectedTab: NavigationTab
    @Binding var selectedServer: ServerInstance?
    @Binding var selectedServerTab: ServerTab
    let servers: [ServerInstance]
    let user: User?
    let onLogout: () -> Void
    
    public init(
        selectedTab: Binding<NavigationTab>,
        selectedServer: Binding<ServerInstance?> = .constant(nil),
        selectedServerTab: Binding<ServerTab> = .constant(.console),
        servers: [ServerInstance] = [],
        user: User?,
        onLogout: @escaping () -> Void
    ) {
        self._selectedTab = selectedTab
        self._selectedServer = selectedServer
        self._selectedServerTab = selectedServerTab
        self.servers = servers
        self.user = user
        self.onLogout = onLogout
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let server = selectedServer {
                // Server Management Mode Sidebar
                serverSidebarContent(server: server)
            } else {
                // Global App Navigation Mode Sidebar
                globalSidebarContent
            }
            
            Spacer()
            
            // Single Integrated Account & Credits Card
            if let user = user {
                userProfileCard(user: user)
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
    
    // MARK: - Global Sidebar Content
    private var globalSidebarContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(NavigationTab.allCases) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(selectedTab == tab ? Color.white : OvernodeTheme.textSecondary)
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
            
            if !servers.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc.string("dashboard_servers_title").uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(OvernodeTheme.textMuted)
                        .padding(.horizontal, 12)
                        .padding(.top, 14)
                        .padding(.bottom, 2)
                    
                    ForEach(servers) { srv in
                        Button(action: {
                            selectedServer = srv
                            selectedServerTab = .console
                        }) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(srv.isOnline ? Color(red: 0.133, green: 0.773, blue: 0.365) : Color(red: 0.45, green: 0.49, blue: 0.54))
                                    .frame(width: 6, height: 6)
                                
                                Text(srv.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(OvernodeTheme.textPrimary)
                                    .lineLimit(1)
                                
                                if !srv.isOwner {
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 9))
                                        .foregroundColor(Color(red: 0.961, green: 0.620, blue: 0.106))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(OvernodeTheme.textMuted)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - Server Management Sidebar Content
    private func serverSidebarContent(server: ServerInstance) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Back button to all servers
            Button(action: {
                selectedServer = nil
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .bold))
                    Text(loc.string("server_back_to_servers"))
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                }
                .foregroundColor(OvernodeTheme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.04))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 4)
            
            // Server Identity Header
            HStack(spacing: 8) {
                Circle()
                    .fill(server.isOnline ? Color(red: 0.133, green: 0.773, blue: 0.365) : Color(red: 0.45, green: 0.49, blue: 0.54))
                    .frame(width: 7, height: 7)
                
                Text(server.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(OvernodeTheme.textPrimary)
                    .lineLimit(1)
                
                if !server.isOwner {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.961, green: 0.620, blue: 0.106))
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 6)
            
            Divider()
                .background(Color.white.opacity(0.06))
                .padding(.bottom, 4)
            
            // Server Sub-tabs inside the sidebar
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 2) {
                    ForEach(ServerTab.allCases) { tab in
                        Button(action: {
                            selectedServerTab = tab
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: tab.iconName)
                                    .font(.system(size: 13))
                                    .foregroundColor(selectedServerTab == tab ? OvernodeTheme.accentGold : OvernodeTheme.textSecondary)
                                    .frame(width: 18)
                                
                                Text(loc.string("server_tab_\(tab.rawValue)"))
                                    .font(.system(size: 12, weight: selectedServerTab == tab ? .semibold : .regular))
                                    .foregroundColor(selectedServerTab == tab ? OvernodeTheme.textPrimary : OvernodeTheme.textSecondary)
                                    .lineLimit(1)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(selectedServerTab == tab ? Color.white.opacity(0.08) : Color.clear)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - User Profile Card
    private func userProfileCard(user: User) -> some View {
        VStack(spacing: 0) {
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
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 0.098, green: 0.106, blue: 0.125))
                            .frame(width: 28, height: 28)
                        Text(String(user.username.prefix(1)).uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.8))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.username)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(OvernodeTheme.textPrimary)
                            .lineLimit(1)
                        
                        if !user.email.isEmpty {
                            Text(user.email)
                                .font(.system(size: 10))
                                .foregroundColor(Color(red: 0.584, green: 0.631, blue: 0.678))
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
        .background(Color(red: 0.125, green: 0.133, blue: 0.161))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(red: 0.180, green: 0.200, blue: 0.216).opacity(0.5), lineWidth: 1)
        )
        .padding(.bottom, 6)
    }
}
