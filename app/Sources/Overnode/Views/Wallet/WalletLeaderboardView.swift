import SwiftUI

public struct WalletLeaderboardView: View {
    @ObservedObject var vm: WalletViewModel
    @ObservedObject var loc = LocalizationManager.shared
    
    public init(vm: WalletViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // User rank banner if available
            if let userRank = vm.leaderboard?.userRank {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.125, green: 0.133, blue: 0.161))
                            .frame(width: 36, height: 36)
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 16))
                            .foregroundColor(OvernodeTheme.accentGold)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(loc.string("wallet_user_rank"))
                            .font(.system(size: 11))
                            .foregroundColor(OvernodeTheme.textSecondary)
                        HStack(spacing: 6) {
                            Text("#\(userRank.rank)")
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundColor(OvernodeTheme.accentGold)
                            Text("•")
                                .foregroundColor(OvernodeTheme.textMuted)
                            Text(userRank.username)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(OvernodeTheme.textPrimary)
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(userRank.coins) " + loc.string("wallet_coins_suffix"))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(OvernodeTheme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(6)
                }
                .padding(14)
                .background(Color(red: 0.125, green: 0.133, blue: 0.161).opacity(0.5))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
            }
            
            // Top 25 Leaderboard Table
            VStack(alignment: .leading, spacing: 0) {
                // Table header
                HStack {
                    Text(loc.string("wallet_rank"))
                        .frame(width: 70, alignment: .leading)
                    Text(loc.string("wallet_user"))
                        .frame(minWidth: 150, alignment: .leading)
                    Spacer()
                    Text(loc.string("wallet_coins_suffix").capitalized)
                        .frame(width: 100, alignment: .trailing)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(OvernodeTheme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(red: 0.125, green: 0.133, blue: 0.161).opacity(0.6))
                
                Divider().background(OvernodeTheme.borderSubtle)
                
                if let board = vm.leaderboard?.leaderboard, !board.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(board) { entry in
                            HStack {
                                Text("#\(entry.rank)")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(rankColor(entry.rank))
                                    .frame(width: 70, alignment: .leading)
                                
                                Text(entry.username)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(OvernodeTheme.textPrimary)
                                    .frame(minWidth: 150, alignment: .leading)
                                
                                Spacer()
                                
                                Text("\(entry.coins)")
                                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                    .foregroundColor(OvernodeTheme.textPrimary)
                                    .frame(width: 100, alignment: .trailing)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(isCurrentUser(entry) ? Color.white.opacity(0.04) : Color.clear)
                            
                            Divider().background(OvernodeTheme.borderSubtle.opacity(0.5))
                        }
                    }
                } else if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(32)
                } else {
                    Text(loc.string("wallet_no_leaderboard"))
                        .font(.system(size: 13))
                        .foregroundColor(OvernodeTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(32)
                }
            }
            .background(Color.clear)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
        }
    }
    
    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.843, blue: 0.0) // Gold
        case 2: return Color(red: 0.753, green: 0.753, blue: 0.753) // Silver
        case 3: return Color(red: 0.804, green: 0.498, blue: 0.196) // Bronze
        default: return OvernodeTheme.textSecondary
        }
    }
    
    private func isCurrentUser(_ entry: LeaderboardResponse.UserEntry) -> Bool {
        return vm.leaderboard?.userRank?.username == entry.username
    }
}
