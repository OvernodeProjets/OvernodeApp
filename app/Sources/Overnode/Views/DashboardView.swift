import SwiftUI

public struct DashboardView: View {
    @ObservedObject var authVM: AuthViewModel
    @StateObject private var dashboardVM: DashboardViewModel
    @ObservedObject var loc = LocalizationManager.shared
    @ObservedObject var updateVM = UpdateViewModel.shared
    @State private var selectedTab: NavigationTab = .dashboard
    @State private var selectedServer: ServerInstance?
    @State private var selectedServerTab: ServerTab = .console
    @State private var isShowingCreateServerModal: Bool = false
    
    public init(authVM: AuthViewModel, initialTab: NavigationTab = .dashboard) {
        self.authVM = authVM
        self._dashboardVM = StateObject(wrappedValue: DashboardViewModel(initialResources: authVM.initialResources))
        self._selectedTab = State(initialValue: initialTab)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HeaderBarView(
                onRefresh: {
                    authVM.checkSession()
                    dashboardVM.loadDashboardData(force: true)
                }
            )
            
            HStack(spacing: 0) {
                SidebarView(
                    selectedTab: $selectedTab,
                    selectedServer: $selectedServer,
                    selectedServerTab: $selectedServerTab,
                    servers: dashboardVM.servers,
                    user: authVM.currentUser,
                    onLogout: { authVM.logout() }
                )
                
                Group {
                    if let server = selectedServer {
                        ServerDetailView(
                            vm: ServerDetailViewModel(server: server),
                            selectedTab: $selectedServerTab,
                            onBack: { selectedServer = nil }
                        )
                    } else {
                        switch selectedTab {
                        case .dashboard:
                            overviewContent
                        case .servers:
                            serversListContent
                        case .wallet:
                            WalletView(userCoins: authVM.currentUser?.coins ?? 0)
                        case .dailyReward:
                            DailyRewardView(
                                userCoins: authVM.currentUser?.coins ?? 0,
                                currentUserId: authVM.currentUser?.id,
                                onRewardClaimed: { newCoins in
                                    authVM.currentUser?.coins = newCoins
                                    authVM.checkSession()
                                    dashboardVM.loadDashboardData(force: true)
                                }
                            )
                        case .store:
                            StoreView(
                                initialCoins: authVM.currentUser?.coins ?? 0,
                                onResourcePurchased: { newCoins in
                                    authVM.currentUser?.coins = newCoins
                                    dashboardVM.loadDashboardData(force: true)
                                }
                            )
                        case .support:
                            SupportView()
                        case .afk:
                            AFKView()
                        case .settings:
                            settingsContent
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(OvernodeTheme.background)
        .onAppear {
            dashboardVM.setInitialResourcesIfNeeded(authVM.initialResources)
            dashboardVM.loadDashboardData()
        }
        .sheet(isPresented: $isShowingCreateServerModal) {
            CreateServerModalView(
                onDismiss: { isShowingCreateServerModal = false },
                onServerCreated: { newServer in
                    dashboardVM.onServerCreatedOptimistic(newServer)
                    authVM.checkSession()
                }
            )
        }
    }
    
    // MARK: - Tab: Overview
    private var overviewContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                HStack {
                    Text(loc.string("dashboard_title"))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    Spacer()
                }
                .padding(.top, 4)
                
                let res = dashboardVM.resources ?? authVM.initialResources ?? ResourcesResponse.empty
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ResourceGaugeView(
                        title: loc.string("resource_ram"),
                        iconName: "chart.pie",
                        usedFormatted: String(format: "%.0f", res.ramUsedGB),
                        totalFormatted: String(format: "%.0f", res.ramTotalGB),
                        unit: "GB",
                        percentage: res.ramPercentage,
                        solidColor: Color(red: 0.35, green: 0.55, blue: 0.95)
                    )
                    ResourceGaugeView(
                        title: loc.string("resource_cpu"),
                        iconName: "cpu",
                        usedFormatted: String(format: "%.0f", res.current.cpu),
                        totalFormatted: String(format: "%.0f", res.limits.cpu),
                        unit: "%",
                        percentage: res.cpuPercentage,
                        solidColor: Color(red: 0.20, green: 0.75, blue: 0.85)
                    )
                    ResourceGaugeView(
                        title: loc.string("resource_disk"),
                        iconName: "archivebox",
                        usedFormatted: String(format: "%.0f", res.diskUsedGB),
                        totalFormatted: String(format: "%.0f", res.diskTotalGB),
                        unit: "GB",
                        percentage: res.diskPercentage,
                        solidColor: Color(red: 0.25, green: 0.78, blue: 0.50)
                    )
                    ResourceGaugeView(
                        title: loc.string("resource_servers"),
                        iconName: "server.rack",
                        usedFormatted: "\(res.current.servers)",
                        totalFormatted: "\(res.limits.servers)",
                        unit: "",
                        percentage: res.serversPercentage,
                        solidColor: Color(red: 0.58, green: 0.45, blue: 0.92)
                    )
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Text(loc.string("dashboard_servers_title"))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(OvernodeTheme.textPrimary)
                        
                        if !dashboardVM.servers.isEmpty {
                            Text("\(dashboardVM.servers.count)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(OvernodeTheme.textSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(red: 0.125, green: 0.133, blue: 0.161))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        Button(action: { isShowingCreateServerModal = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text(loc.string("create_server_button"))
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(OvernodeTheme.accentGold)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if dashboardVM.isLoading && dashboardVM.servers.isEmpty {
                        HStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(loc.string("servers_loading"))
                                .font(.system(size: 13))
                                .foregroundColor(OvernodeTheme.textSecondary)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(OvernodeTheme.cardBackground)
                        .cornerRadius(10)
                    } else if dashboardVM.servers.isEmpty {
                        HStack {
                            Text(loc.string("servers_none_found"))
                                .font(.system(size: 13))
                                .foregroundColor(OvernodeTheme.textSecondary)
                            Spacer()
                            Button(action: { dashboardVM.loadDashboardData() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.clockwise")
                                    Text(loc.string("status_refresh"))
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(OvernodeTheme.accentGold)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(18)
                        .background(OvernodeTheme.cardBackground)
                        .cornerRadius(10)
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(dashboardVM.servers) { server in
                                DashboardServerCardView(server: server) { s in
                                    selectedServer = s
                                    selectedServerTab = .console
                                }
                            }
                        }
                    }
                }
                
                platformStatsSection
                
                Spacer()
            }
            .padding(24)
        }
        .background(OvernodeTheme.background)
    }
    
    // MARK: - Tab: Servers List
    private var serversListContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(loc.string("nav_servers"))
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(OvernodeTheme.textPrimary)
                        Text(loc.string("servers_page_subtitle"))
                            .font(.system(size: 13))
                            .foregroundColor(OvernodeTheme.textSecondary)
                    }
                    Spacer()
                    Button(action: { isShowingCreateServerModal = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text(loc.string("create_server_button"))
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(OvernodeTheme.accentGold)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
                
                if dashboardVM.servers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "server.rack")
                            .font(.system(size: 40))
                            .foregroundColor(OvernodeTheme.textMuted)
                        Text(loc.string("servers_none_found"))
                            .font(.system(size: 14))
                            .foregroundColor(OvernodeTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 280)
                    .background(OvernodeTheme.cardBackground)
                    .cornerRadius(10)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(dashboardVM.servers) { server in
                            DashboardServerCardView(server: server) { s in
                                selectedServer = s
                            }
                        }
                    }
                }
                Spacer()
            }
            .padding(24)
        }
        .background(OvernodeTheme.background)
    }
    
    // MARK: - Tab: App Settings
    private var settingsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(loc.string("nav_settings"))
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(OvernodeTheme.textPrimary)
                    .padding(.top, 4)
                
                // Language Switcher Card
                VStack(alignment: .leading, spacing: 16) {
                    Text(loc.string("settings_language_title"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    
                    HStack(spacing: 12) {
                        ForEach(AppLanguage.allCases) { lang in
                            Button(action: {
                                loc.setLanguage(lang)
                            }) {
                                HStack(spacing: 8) {
                                    Text(lang.flag)
                                    Text(lang.displayName)
                                        .font(.system(size: 13, weight: loc.currentLanguage == lang ? .semibold : .regular))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(loc.currentLanguage == lang ? OvernodeTheme.accentGold.opacity(0.15) : Color.white.opacity(0.04))
                                .foregroundColor(loc.currentLanguage == lang ? OvernodeTheme.accentGold : OvernodeTheme.textPrimary)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(loc.currentLanguage == lang ? OvernodeTheme.accentGold : Color.white.opacity(0.08), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(18)
                .background(OvernodeTheme.cardBackground)
                .cornerRadius(10)
                
                // Software Updates Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(loc.string("update_section_title"))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(OvernodeTheme.textPrimary)
                            Text("\(loc.string("update_version_label")) : v\(updateVM.currentVersion)")
                                .font(.system(size: 12))
                                .foregroundColor(OvernodeTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            Task {
                                await updateVM.checkForUpdates(silent: false)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text(loc.string("update_check_button"))
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(OvernodeTheme.accentGold)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if updateVM.hasUpdateAvailable {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .foregroundColor(OvernodeTheme.accentGold)
                            Text(loc.string("update_badge"))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(OvernodeTheme.textPrimary)
                            Spacer()
                            Button(action: {
                                updateVM.showModal = true
                            }) {
                                Text(loc.string("update_btn_install"))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                        .background(OvernodeTheme.accentGold.opacity(0.1))
                        .cornerRadius(8)
                    } else if case .checking = updateVM.state {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text(loc.string("update_checking"))
                                .font(.system(size: 13))
                                .foregroundColor(OvernodeTheme.textSecondary)
                        }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(red: 0.133, green: 0.773, blue: 0.365))
                            Text(loc.string("update_up_to_date"))
                                .font(.system(size: 13))
                                .foregroundColor(OvernodeTheme.textSecondary)
                        }
                    }
                }
                .padding(18)
                .background(OvernodeTheme.cardBackground)
                .cornerRadius(10)
                
                Spacer()
            }
            .padding(24)
        }
        .background(OvernodeTheme.background)
    }
    
    private var platformStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(loc.string("dashboard_platform_stats"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(OvernodeTheme.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)], spacing: 16) {
                PlatformStatCard(iconName: "person.2", label: loc.string("stats_total_users"), value: dashboardVM.platformStats?.totalUsers.map(String.init) ?? "—")
                PlatformStatCard(iconName: "server.rack", label: loc.string("stats_active_servers"), value: dashboardVM.platformStats?.totalServers.map(String.init) ?? "—")
                PlatformStatCard(iconName: "mappin.and.ellipse", label: loc.string("stats_locations"), value: dashboardVM.platformStats?.totalLocations.map(String.init) ?? "—")
            }
        }
    }
}

private struct PlatformStatCard: View {
    let iconName: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.125, green: 0.133, blue: 0.161))
                    .frame(width: 36, height: 36)
                Image(systemName: iconName)
                    .font(.system(size: 15))
                    .foregroundColor(Color(red: 0.584, green: 0.631, blue: 0.678))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(red: 0.584, green: 0.631, blue: 0.678))
                Text(value)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(OvernodeTheme.textPrimary)
            }
            Spacer()
        }
        .padding(16)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 0.180, green: 0.200, blue: 0.216).opacity(0.5), lineWidth: 1)
        )
    }
}

