import SwiftUI

public struct DashboardView: View {
    @ObservedObject var authVM: AuthViewModel
    @StateObject private var dashboardVM: DashboardViewModel
    @ObservedObject var loc = LocalizationManager.shared
    @State private var selectedTab: NavigationTab = .dashboard
    
    public init(authVM: AuthViewModel) {
        self.authVM = authVM
        self._dashboardVM = StateObject(wrappedValue: DashboardViewModel(initialResources: authVM.initialResources))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar without "Connected" badge or top logout button
            HeaderBarView(
                onRefresh: {
                    authVM.checkSession()
                    dashboardVM.loadDashboardData()
                }
            )
            
            // Content Layout: Sidebar (with user profile & coins) + Main Area
            HStack(spacing: 0) {
                SidebarView(
                    selectedTab: $selectedTab,
                    user: authVM.currentUser,
                    onLogout: { authVM.logout() }
                )
                
                // Main Dashboard Body
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Title Header - Simple and clean without yellow default tag
                        HStack(alignment: .center) {
                            Text("Dashboard")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(OvernodeTheme.textPrimary)
                            
                            Spacer()
                        }
                        .padding(.top, 4)
                        
                        // 4 Resources Cards Grid with solid modern colors
                        let res = dashboardVM.resources ?? authVM.initialResources ?? ResourcesResponse.empty
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            // 1. Memory (Solid Blue)
                            ResourceGaugeView(
                                title: "Memory",
                                iconName: "chart.pie",
                                usedFormatted: String(format: "%.0f", res.ramUsedGB),
                                totalFormatted: String(format: "%.0f", res.ramTotalGB),
                                unit: "GB",
                                percentage: res.ramPercentage,
                                solidColor: Color(red: 0.35, green: 0.55, blue: 0.95)
                            )
                            
                            // 2. CPU (Solid Cyan)
                            ResourceGaugeView(
                                title: "CPU",
                                iconName: "cpu",
                                usedFormatted: String(format: "%.0f", res.current.cpu),
                                totalFormatted: String(format: "%.0f", res.limits.cpu),
                                unit: "%",
                                percentage: res.cpuPercentage,
                                solidColor: Color(red: 0.20, green: 0.75, blue: 0.85)
                            )
                            
                            // 3. Storage (Solid Emerald Green)
                            ResourceGaugeView(
                                title: "Storage",
                                iconName: "archivebox",
                                usedFormatted: String(format: "%.0f", res.diskUsedGB),
                                totalFormatted: String(format: "%.0f", res.diskTotalGB),
                                unit: "GB",
                                percentage: res.diskPercentage,
                                solidColor: Color(red: 0.25, green: 0.78, blue: 0.50)
                            )
                            
                            // 4. Servers (Solid Purple)
                            ResourceGaugeView(
                                title: "Servers",
                                iconName: "server.rack",
                                usedFormatted: "\(res.current.servers)",
                                totalFormatted: "\(res.limits.servers)",
                                unit: "",
                                percentage: res.serversPercentage,
                                solidColor: Color(red: 0.58, green: 0.45, blue: 0.92)
                            )
                        }
                        
                        // User Servers Section (Displayed ONLY if the user has servers)
                        if !dashboardVM.servers.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 8) {
                                    Text(loc.string("dashboard_servers_title"))
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(OvernodeTheme.textPrimary)
                                    
                                    Text("\(dashboardVM.servers.count)")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(OvernodeTheme.textSecondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(red: 0.125, green: 0.133, blue: 0.161))
                                        .cornerRadius(4)
                                }
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 16),
                                    GridItem(.flexible(), spacing: 16)
                                ], spacing: 16) {
                                    ForEach(dashboardVM.servers) { server in
                                        DashboardServerCardView(server: server)
                                    }
                                }
                            }
                        }
                        
                        // Platform Statistics Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Platform Statistics")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(OvernodeTheme.textPrimary)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 16) {
                                PlatformStatCard(
                                    iconName: "person.2",
                                    label: "Total Users",
                                    value: dashboardVM.platformStats?.totalUsers.map(String.init) ?? "—"
                                )
                                PlatformStatCard(
                                    iconName: "server.rack",
                                    label: "Active Servers",
                                    value: dashboardVM.platformStats?.totalServers.map(String.init) ?? "—"
                                )
                                PlatformStatCard(
                                    iconName: "cpu",
                                    label: "Nodes",
                                    value: dashboardVM.platformStats?.totalNodes.map(String.init) ?? "—"
                                )
                                PlatformStatCard(
                                    iconName: "mappin.and.ellipse",
                                    label: "Locations",
                                    value: dashboardVM.platformStats?.totalLocations.map(String.init) ?? "—"
                                )
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(24)
                }
                .background(OvernodeTheme.background)
            }
        }
        .background(OvernodeTheme.background)
        .onAppear {
            dashboardVM.setInitialResourcesIfNeeded(authVM.initialResources)
            dashboardVM.loadDashboardData()
        }
    }
}

// Platform Statistics Card
private struct PlatformStatCard: View {
    let iconName: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.125, green: 0.133, blue: 0.161)) // #202229
                    .frame(width: 36, height: 36)
                Image(systemName: iconName)
                    .font(.system(size: 15))
                    .foregroundColor(Color(red: 0.584, green: 0.631, blue: 0.678)) // #95a1ad
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(red: 0.584, green: 0.631, blue: 0.678)) // #95a1ad
                Text(value)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(OvernodeTheme.textPrimary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 0.180, green: 0.200, blue: 0.216).opacity(0.5), lineWidth: 1)
        )
    }
}
