import SwiftUI

public struct DailyRewardView: View {
    @StateObject private var vm = DailyRewardViewModel()
    @ObservedObject var loc = LocalizationManager.shared
    let userCoins: Int
    let currentUserId: String?
    let onRewardClaimed: (Int) -> Void
    
    public init(
        userCoins: Int,
        currentUserId: String? = nil,
        onRewardClaimed: @escaping (Int) -> Void
    ) {
        self.userCoins = userCoins
        self.currentUserId = currentUserId
        self.onRewardClaimed = onRewardClaimed
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header section with title & tabs
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(loc.string("daily_title"))
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(OvernodeTheme.textPrimary)
                            Text(loc.string("daily_subtitle"))
                                .font(.system(size: 13))
                                .foregroundColor(OvernodeTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        // Current Coins Badge
                        HStack(spacing: 6) {
                            Image(systemName: "circle.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(OvernodeTheme.accentGold)
                            Text("\(userCoins) " + loc.string("wallet_coins_suffix"))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(OvernodeTheme.textPrimary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.125, green: 0.133, blue: 0.161))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
                        
                        // Refresh button
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
                        tabButton(.claim, label: loc.string("daily_tab_claim"))
                        tabButton(.leaderboard, label: loc.string("daily_tab_leaderboard"))
                        tabButton(.history, label: loc.string("daily_tab_history"))
                    }
                    .overlay(Rectangle().frame(height: 1).foregroundColor(OvernodeTheme.borderSubtle), alignment: .bottom)
                }
                .padding(.top, 4)
                
                // Feedback banners (Success / Error)
                if let success = vm.successMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(red: 0.133, green: 0.773, blue: 0.365))
                        Text(success)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(OvernodeTheme.textPrimary)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green.opacity(0.2), lineWidth: 1))
                }
                
                if let err = vm.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color.red)
                        Text(err)
                            .font(.system(size: 13))
                            .foregroundColor(Color.red.opacity(0.9))
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.2), lineWidth: 1))
                }
                
                // Content of current tab
                switch vm.selectedTab {
                case .claim:
                    DailyRewardClaimView(
                        vm: vm,
                        userCoins: userCoins,
                        onRewardClaimed: { newBal in
                            onRewardClaimed(newBal)
                        }
                    )
                case .leaderboard:
                    DailyRewardLeaderboardView(
                        vm: vm,
                        currentUserId: currentUserId
                    )
                case .history:
                    DailyRewardHistoryView(
                        vm: vm
                    )
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
    
    private func tabButton(_ tab: DailyRewardTab, label: String) -> some View {
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
