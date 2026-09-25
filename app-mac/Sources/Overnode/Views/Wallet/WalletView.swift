import SwiftUI

public struct WalletView: View {
    @StateObject private var vm = WalletViewModel()
    @ObservedObject var loc = LocalizationManager.shared
    let userCoins: Int
    
    public init(userCoins: Int) {
        self.userCoins = userCoins
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header section with title & tabs
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(loc.string("wallet_title"))
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(OvernodeTheme.textPrimary)
                            Text(loc.string("wallet_subtitle"))
                                .font(.system(size: 13))
                                .foregroundColor(OvernodeTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button(action: { vm.loadData() }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(OvernodeTheme.textSecondary)
                                .padding(8)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Toledo horizontal tabs
                    HStack(spacing: 8) {
                        tabButton(.overview, label: loc.string("wallet_tab_overview"))
                        tabButton(.leaderboard, label: loc.string("wallet_tab_leaderboard"))
                        tabButton(.activity, label: loc.string("wallet_tab_activity"))
                    }
                    .overlay(Rectangle().frame(height: 1).foregroundColor(OvernodeTheme.borderSubtle), alignment: .bottom)
                }
                .padding(.top, 4)
                
                // Active tab content
                switch vm.selectedTab {
                case .overview:
                    WalletOverviewView(vm: vm, userCoins: userCoins)
                case .leaderboard:
                    WalletLeaderboardView(vm: vm)
                case .activity:
                    WalletActivityView(vm: vm)
                }
                
                Spacer()
            }
            .padding(24)
        }
        .background(OvernodeTheme.background)
        .onAppear {
            vm.loadData()
        }
    }
    
    private func tabButton(_ tab: WalletTab, label: String) -> some View {
        Button(action: { vm.selectedTab = tab }) {
            HStack(spacing: 6) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 13, weight: vm.selectedTab == tab ? .semibold : .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundColor(vm.selectedTab == tab ? OvernodeTheme.textPrimary : OvernodeTheme.textSecondary)
            .overlay(
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(vm.selectedTab == tab ? Color.white : Color.clear),
                alignment: .bottom
            )
        }
        .buttonStyle(.plain)
    }
}
