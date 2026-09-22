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
            // Header Bar
            HeaderBarView(
                user: authVM.currentUser,
                onLogout: { authVM.logout() },
                onRefresh: {
                    authVM.checkSession()
                    dashboardVM.loadDashboardData()
                }
            )
            
            // Content Layout: Sidebar + Main Area
            HStack(spacing: 0) {
                SidebarView(selectedTab: $selectedTab)
                
                // Main Dashboard Body - Exact Toledo Layout & Spacing
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Title Header (exact Toledo style)
                        HStack(alignment: .center) {
                            Text("Dashboard")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(OvernodeTheme.textPrimary)
                            
                            Spacer()
                            
                            if let pkg = dashboardVM.resources?.package, !pkg.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 11))
                                        .foregroundColor(OvernodeTheme.accentGold)
                                    Text(pkg.uppercased())
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(OvernodeTheme.accentGold)
                                }
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(OvernodeTheme.accentGold.opacity(0.12))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(OvernodeTheme.accentGold.opacity(0.25), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.top, 4)
                        
                        // 4 Resources Cards Grid: Memory, CPU, Storage, Servers
                        let res = dashboardVM.resources ?? authVM.initialResources ?? ResourcesResponse.empty
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            // 1. Memory
                            ResourceGaugeView(
                                title: "Memory",
                                iconName: "chart.pie",
                                usedFormatted: String(format: "%.0f", res.ramUsedGB),
                                totalFormatted: String(format: "%.0f", res.ramTotalGB),
                                unit: "GB",
                                percentage: res.ramPercentage
                            )
                            
                            // 2. CPU
                            ResourceGaugeView(
                                title: "CPU",
                                iconName: "cpu",
                                usedFormatted: String(format: "%.0f", res.current.cpu),
                                totalFormatted: String(format: "%.0f", res.limits.cpu),
                                unit: "%",
                                percentage: res.cpuPercentage
                            )
                            
                            // 3. Storage
                            ResourceGaugeView(
                                title: "Storage",
                                iconName: "archivebox",
                                usedFormatted: String(format: "%.0f", res.diskUsedGB),
                                totalFormatted: String(format: "%.0f", res.diskTotalGB),
                                unit: "GB",
                                percentage: res.diskPercentage
                            )
                            
                            // 4. Servers
                            ResourceGaugeView(
                                title: "Servers",
                                iconName: "server.rack",
                                usedFormatted: "(res.current.servers)",
                                totalFormatted: "(res.limits.servers)",
                                unit: "",
                                percentage: res.serversPercentage
                            )
                        }
                        
                        // FAQ Section - Integrated from Toledo
                        FAQSectionView()
                        
                        // Platform Statistics Section (Exact Toledo 4-column cards)
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

// Toledo exact Platform Statistics Card
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

// Toledo FAQ Section view
private struct FAQSectionView: View {
    @State private var isExpanded: Bool = false
    
    private let faqs: [(icon: String, title: String, desc: String)] = [
        ("book", "Get started", "Welcome to Overnode! Start by creating your first server. We give every user a balance of resources (Memory, CPU, Disk and Servers) - you can split them across multiple servers or use them all on one."),
        ("questionmark.circle", "Get support", "Need help? Our support team is available 24/7. Submit a ticket, chat with our team, or browse our knowledge base for quick answers to common questions."),
        ("globe", "Join our community", "Connect with other Overnode users in our Discord server. Get quick help via public support or chat with our community."),
        ("speedometer", "Server optimization tips", "Learn advanced techniques to optimize your server performance. From resource allocation to networking configurations, discover how to get the most out of your infrastructure."),
        ("creditcard", "Billing and subscriptions", "Understand our pricing structure, billing cycles, and subscription options. Find out how to upgrade your plan, manage payment methods, and view your billing history."),
        ("lock.shield", "Security best practices", "Keep your servers and data safe with our security recommendations. Learn about access controls, firewall configurations, and encryption.")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("FAQ")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(OvernodeTheme.textPrimary)
            
            let displayed = isExpanded ? faqs : Array(faqs.prefix(3))
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(displayed, id: \.title) { item in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(red: 0.125, green: 0.133, blue: 0.161)) // #202229
                                    .frame(width: 28, height: 28)
                                Image(systemName: item.icon)
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(red: 0.584, green: 0.631, blue: 0.678)) // #95a1ad
                            }
                            
                            Text(item.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(OvernodeTheme.textPrimary)
                        }
                        
                        Text(item.desc)
                            .font(.system(size: 12, weight: .regular))
                            .lineSpacing(3)
                            .foregroundColor(Color(red: 0.584, green: 0.631, blue: 0.678)) // #95a1ad
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(Color.clear)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.180, green: 0.200, blue: 0.216).opacity(0.5), lineWidth: 1)
                    )
                }
            }
            
            HStack {
                Spacer()
                Button(action: { withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() } }) {
                    HStack(spacing: 8) {
                        Text(isExpanded ? "Show less" : "Show more")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(OvernodeTheme.textPrimary)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(OvernodeTheme.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.125, green: 0.133, blue: 0.161)) // #202229
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.top, 4)
        }
    }
}
