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
                    dashboardVM.loadResources()
                }
            )
            
            // Content Layout: Sidebar + Main Area
            HStack(spacing: 0) {
                SidebarView(selectedTab: $selectedTab)
                
                // Main Dashboard Body
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Clean, minimal Overview Header
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 10) {
                                    Text(authVM.currentUser?.username ?? "Utilisateur")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(OvernodeTheme.textPrimary)
                                    
                                    if let pkg = dashboardVM.resources?.package, !pkg.isEmpty {
                                        Text(pkg.uppercased())
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(OvernodeTheme.accentGold)
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 3)
                                            .background(OvernodeTheme.accentGold.opacity(0.12))
                                            .cornerRadius(6)
                                    }
                                }
                                
                                if let email = authVM.currentUser?.email, !email.isEmpty {
                                    Text(email)
                                        .font(.system(size: 12))
                                        .foregroundColor(OvernodeTheme.textMuted)
                                }
                            }
                            
                            Spacer()
                            
                            // Discreet status indicator
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(OvernodeTheme.accentSuccess)
                                    .frame(width: 6, height: 6)
                                Text("Infrastructure active")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(OvernodeTheme.textSecondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(OvernodeTheme.borderSubtle, lineWidth: 1)
                            )
                        }
                        .padding(.top, 4)
                        
                        // 4 Resources Cards Grid (RAM / CPU / DISK / SERVERS)
                        let res = dashboardVM.resources ?? authVM.initialResources ?? ResourcesResponse.empty
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Ressources allouées")
                                .font(.system(size: 12, weight: .semibold))
                                .textCase(.uppercase)
                                .tracking(0.5)
                                .foregroundColor(OvernodeTheme.textMuted)
                            
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                                // 1. Memory RAM
                                ResourceGaugeView(
                                    title: loc.string("resource_ram"),
                                    iconName: "memorychip",
                                    usedFormatted: String(format: "%.2f", res.ramUsedGB),
                                    totalFormatted: String(format: "%.2f", res.ramTotalGB),
                                    unit: "GB",
                                    percentage: res.ramPercentage,
                                    accentColor: OvernodeTheme.accentGold
                                )
                                
                                // 2. CPU Processor
                                ResourceGaugeView(
                                    title: loc.string("resource_cpu"),
                                    iconName: "cpu",
                                    usedFormatted: String(format: "%.0f", res.current.cpu),
                                    totalFormatted: String(format: "%.0f", res.limits.cpu),
                                    unit: "%",
                                    percentage: res.cpuPercentage,
                                    accentColor: Color(red: 0.35, green: 0.65, blue: 0.95)
                                )
                                
                                // 3. Disk Storage
                                ResourceGaugeView(
                                    title: loc.string("resource_disk"),
                                    iconName: "internaldrive",
                                    usedFormatted: String(format: "%.2f", res.diskUsedGB),
                                    totalFormatted: String(format: "%.2f", res.diskTotalGB),
                                    unit: "GB",
                                    percentage: res.diskPercentage,
                                    accentColor: Color(red: 0.25, green: 0.78, blue: 0.55)
                                )
                                
                                // 4. Server count
                                ResourceGaugeView(
                                    title: loc.string("resource_servers"),
                                    iconName: "server.rack",
                                    usedFormatted: "(res.current.servers)",
                                    totalFormatted: "(res.limits.servers)",
                                    unit: "",
                                    percentage: res.serversPercentage,
                                    accentColor: OvernodeTheme.accentDiscord
                                )
                            }
                        }
                        
                        // Cloud Infrastructure Overview - Flat, refined layout
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Infrastructure Overnode")
                                .font(.system(size: 12, weight: .semibold))
                                .textCase(.uppercase)
                                .tracking(0.5)
                                .foregroundColor(OvernodeTheme.textMuted)
                            
                            HStack(spacing: 12) {
                                MinimalMetricCard(
                                    title: "Latence réseau",
                                    value: "< 5 ms",
                                    detail: "Transit direct France"
                                )
                                MinimalMetricCard(
                                    title: "Disponibilité SLA",
                                    value: "99.98%",
                                    detail: "Haute disponibilité"
                                )
                                MinimalMetricCard(
                                    title: "Protection Anti-DDoS",
                                    value: "Active",
                                    detail: "Filtrage matériel 10 Gbps"
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
            dashboardVM.loadResources()
        }
    }
}

private struct MinimalMetricCard: View {
    let title: String
    let value: String
    let detail: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(OvernodeTheme.textMuted)
            
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(OvernodeTheme.textPrimary)
            
            Text(detail)
                .font(.system(size: 11))
                .foregroundColor(OvernodeTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(OvernodeTheme.cardBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(OvernodeTheme.borderSubtle, lineWidth: 1)
        )
    }
}
