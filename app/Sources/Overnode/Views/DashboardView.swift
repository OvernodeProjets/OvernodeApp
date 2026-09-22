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
                        // Welcome Banner with User Email and Plan
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(loc.string("dashboard_welcome")), \(authVM.currentUser?.username ?? "User")")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(OvernodeTheme.textPrimary)
                                
                                if let email = authVM.currentUser?.email, !email.isEmpty {
                                    HStack(spacing: 6) {
                                        Image(systemName: "envelope.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(OvernodeTheme.textSecondary)
                                        Text(email)
                                            .font(.system(size: 12))
                                            .foregroundColor(OvernodeTheme.textSecondary)
                                    }
                                    .padding(.top, 2)
                                }
                                
                                Text(loc.string("dashboard_resources_desc"))
                                    .font(.system(size: 13))
                                    .foregroundColor(OvernodeTheme.textSecondary)
                                    .padding(.top, 2)
                            }
                            
                            Spacer()
                            
                            // User Package badge
                            if let pkg = dashboardVM.resources?.package {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 12))
                                        .foregroundColor(OvernodeTheme.accentGold)
                                    
                                    Text(pkg.uppercased())
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(OvernodeTheme.accentGold)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(OvernodeTheme.accentGold.opacity(0.12))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(OvernodeTheme.accentGold.opacity(0.25), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.top, 8)
                        
                       // 4 Resources Cards Grid (RAM / CPU / DISK / SERVERS)
                        let res = dashboardVM.resources ?? authVM.initialResources ?? ResourcesResponse.empty
                        
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
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
                                accentColor: OvernodeTheme.accentCyan
                            )
                            
                            // 3. Disk Storage
                            ResourceGaugeView(
                                title: loc.string("resource_disk"),
                                iconName: "internaldrive",
                                usedFormatted: String(format: "%.2f", res.diskUsedGB),
                                totalFormatted: String(format: "%.2f", res.diskTotalGB),
                                unit: "GB",
                                percentage: res.diskPercentage,
                                accentColor: OvernodeTheme.accentSuccess
                            )
                            
                            // 4. Server count
                            ResourceGaugeView(
                                title: loc.string("resource_servers"),
                                iconName: "server.rack",
                                usedFormatted: "\(res.current.servers)",
                                totalFormatted: "\(res.limits.servers)",
                                unit: "",
                                percentage: res.serversPercentage,
                                accentColor: OvernodeTheme.accentDiscord
                            )
                        }
                        
                        // Cloud Infrastructure Overview
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Infrastructure Overnode")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(OvernodeTheme.textPrimary)
                                
                                Spacer()
                                
                                Text("Réseau France 10 Gbps Anti-DDoS")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(OvernodeTheme.textMuted)
                            }
                            
                            HStack(spacing: 16) {
                                InfoMetricPill(
                                    title: "Latence Réseau",
                                    value: "< 5 ms",
                                    icon: "network"
                                )
                                InfoMetricPill(
                                    title: "Disponibilité SLA",
                                    value: "99.98%",
                                    icon: "shield.checkmark"
                                )
                                InfoMetricPill(
                                    title: "Stockage NVMe",
                                    value: "PCIe 4.0",
                                    icon: "bolt.fill"
                                )
                            }
                        }
                        .padding(20)
                        .background(OvernodeTheme.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(OvernodeTheme.border, lineWidth: 1)
                        )
                        
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

private struct InfoMetricPill: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(OvernodeTheme.accentGold)
                .frame(width: 32, height: 32)
                .background(OvernodeTheme.secondaryCardBackground)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(OvernodeTheme.textSecondary)
                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(OvernodeTheme.textPrimary)
            }
            Spacer()
        }
        .padding(12)
        .background(OvernodeTheme.secondaryCardBackground.opacity(0.5))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(OvernodeTheme.borderSubtle, lineWidth: 1)
        )
    }
}
