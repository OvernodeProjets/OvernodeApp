import SwiftUI

public struct DailyRewardLeaderboardView: View {
    @ObservedObject var vm: DailyRewardViewModel
    @ObservedObject var loc = LocalizationManager.shared
    let currentUserId: String?
    
    public init(vm: DailyRewardViewModel, currentUserId: String?) {
        self.vm = vm
        self.currentUserId = currentUserId
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc.string("daily_leaderboard_title"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    Text(loc.string("daily_leaderboard_desc"))
                        .font(.system(size: 12))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                
                Spacer()
                
                Button(action: { vm.loadData() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(OvernodeTheme.textSecondary)
                        .padding(6)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 4)
            
            if vm.leaderboard.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "trophy")
                        .font(.system(size: 32))
                        .foregroundColor(OvernodeTheme.textMuted)
                    Text(loc.string("daily_leaderboard_empty"))
                        .font(.system(size: 13))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 180)
                .background(OvernodeTheme.cardBackground)
                .cornerRadius(10)
            } else {
                VStack(spacing: 6) {
                    // Header columns
                    HStack(spacing: 12) {
                        Text(loc.string("daily_lb_rank"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(OvernodeTheme.textMuted)
                            .frame(width: 44, alignment: .leading)
                        
                        Text(loc.string("daily_lb_player"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(OvernodeTheme.textMuted)
                        
                        Spacer()
                        
                        Text(loc.string("daily_lb_streak"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(OvernodeTheme.textMuted)
                            .frame(width: 100, alignment: .trailing)
                        
                        Text(loc.string("daily_lb_record"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(OvernodeTheme.textMuted)
                            .frame(width: 80, alignment: .trailing)
                        
                        Text(loc.string("daily_lb_claims"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(OvernodeTheme.textMuted)
                            .frame(width: 80, alignment: .trailing)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    
                    Divider()
                        .background(Color.white.opacity(0.06))
                    
                    ForEach(Array(vm.leaderboard.enumerated()), id: \.element.id) { index, entry in
                        let rank = index + 1
                        let isMe = entry.userId == currentUserId
                        
                        HStack(spacing: 12) {
                            // Rank Badge
                            rankBadge(rank: rank)
                                .frame(width: 44, alignment: .leading)
                            
                            // User Info
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(isMe ? OvernodeTheme.accentGold.opacity(0.2) : Color.white.opacity(0.05))
                                        .frame(width: 26, height: 26)
                                    Text(String(entry.username.prefix(1)).uppercased())
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(isMe ? OvernodeTheme.accentGold : OvernodeTheme.textPrimary)
                                }
                                
                                Text(entry.username)
                                    .font(.system(size: 13, weight: isMe ? .bold : .medium))
                                    .foregroundColor(isMe ? OvernodeTheme.accentGold : OvernodeTheme.textPrimary)
                                
                                if isMe {
                                    Text(loc.string("daily_lb_you"))
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(OvernodeTheme.accentGold.opacity(0.2))
                                        .foregroundColor(OvernodeTheme.accentGold)
                                        .cornerRadius(4)
                                }
                            }
                            
                            Spacer()
                            
                            // Current streak
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.orange)
                                Text("\(entry.currentStreak)j")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(OvernodeTheme.textPrimary)
                            }
                            .frame(width: 100, alignment: .trailing)
                            
                            // Longest streak
                            Text("\(entry.longestStreak)j")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(OvernodeTheme.textSecondary)
                                .frame(width: 80, alignment: .trailing)
                            
                            // Total claims
                            Text("\(entry.totalClaimed)")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(OvernodeTheme.textSecondary)
                                .frame(width: 80, alignment: .trailing)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(isMe ? OvernodeTheme.accentGold.opacity(0.06) : (index % 2 == 0 ? Color.white.opacity(0.02) : Color.clear))
                        .cornerRadius(8)
                    }
                }
                .padding(12)
                .background(OvernodeTheme.cardBackground)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
            }
        }
    }
    
    private func rankBadge(rank: Int) -> some View {
        HStack(spacing: 4) {
            switch rank {
            case 1:
                Image(systemName: "crown.fill")
                    .foregroundColor(OvernodeTheme.accentGold)
                    .font(.system(size: 13))
            case 2:
                Image(systemName: "medal.fill")
                    .foregroundColor(Color(red: 0.75, green: 0.78, blue: 0.82))
                    .font(.system(size: 13))
            case 3:
                Image(systemName: "medal.fill")
                    .foregroundColor(Color(red: 0.80, green: 0.50, blue: 0.20))
                    .font(.system(size: 13))
            default:
                Text("#\(rank)")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(OvernodeTheme.textMuted)
            }
        }
    }
}
