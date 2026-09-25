import SwiftUI

public struct DailyRewardClaimView: View {
    @ObservedObject var vm: DailyRewardViewModel
    @ObservedObject var loc = LocalizationManager.shared
    let userCoins: Int
    let onRewardClaimed: (Int) -> Void
    
    public init(vm: DailyRewardViewModel, userCoins: Int, onRewardClaimed: @escaping (Int) -> Void) {
        self.vm = vm
        self.userCoins = userCoins
        self.onRewardClaimed = onRewardClaimed
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Main Banner Card for Claiming
            mainClaimBanner
            
            // Streak Stats & Next Reward Row
            streakOverviewCards
            
            // Streak Milestones & Multipliers Map
            streakMilestonesCard
            
            // Streak Protection Card
            streakProtectionCard
        }
    }
    
    // MARK: - Main Claim Banner
    private var mainClaimBanner: some View {
        let status = vm.status
        let canClaim = status?.canClaim ?? false
        let rewardAmount = status?.nextReward?.amount ?? 25
        
        return VStack(spacing: 16) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            canClaim
                                ? LinearGradient(colors: [OvernodeTheme.accentGold.opacity(0.3), Color.orange.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 64, height: 64)
                        .overlay(
                            Circle()
                                .stroke(canClaim ? OvernodeTheme.accentGold : Color.white.opacity(0.1), lineWidth: 2)
                        )
                    
                    Image(systemName: canClaim ? "gift.fill" : "checkmark.seal.fill")
                        .font(.system(size: 28))
                        .foregroundColor(canClaim ? OvernodeTheme.accentGold : OvernodeTheme.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(canClaim ? loc.string("daily_banner_available_title") : loc.string("daily_banner_claimed_title"))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    
                    Text(canClaim ? loc.string("daily_banner_available_desc") : loc.string("daily_banner_claimed_desc"))
                        .font(.system(size: 13))
                        .foregroundColor(OvernodeTheme.textSecondary)
                    
                    if let milestoneMsg = status?.nextReward?.milestoneMessage, canClaim {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11))
                                .foregroundColor(OvernodeTheme.accentGold)
                            Text(milestoneMsg)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(OvernodeTheme.accentGold)
                        }
                        .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                // Action Button
                Button(action: {
                    vm.claim { newBal in
                        onRewardClaimed(newBal)
                    }
                }) {
                    HStack(spacing: 8) {
                        if vm.isClaiming {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: canClaim ? "sparkles" : "clock")
                                .font(.system(size: 13, weight: .bold))
                        }
                        
                        if canClaim {
                            Text(loc.string("daily_claim_button") + " (+\(rewardAmount) coins)")
                                .font(.system(size: 13, weight: .semibold))
                        } else {
                            Text(loc.string("daily_already_claimed"))
                                .font(.system(size: 13, weight: .semibold))
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(canClaim ? OvernodeTheme.accentGold : Color.white.opacity(0.08))
                    .foregroundColor(canClaim ? Color.black : OvernodeTheme.textSecondary)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(!canClaim || vm.isClaiming)
            }
            .padding(20)
        }
        .background(OvernodeTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(canClaim ? OvernodeTheme.accentGold.opacity(0.4) : OvernodeTheme.borderSubtle, lineWidth: 1)
        )
    }
    
    // MARK: - Streak Overview Cards
    private var streakOverviewCards: some View {
        let status = vm.status
        let currentStreak = status?.currentStreak ?? 0
        let longestStreak = status?.longestStreak ?? 0
        let totalClaimed = status?.totalClaimed ?? 0
        let totalCoins = status?.totalCoinsEarned ?? 0
        
        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            statCard(
                icon: "flame.fill",
                iconColor: Color.orange,
                title: loc.string("daily_stat_current_streak"),
                value: "\(currentStreak) " + loc.string("daily_unit_days"),
                subtitle: (status?.streakWillMaintain == true) ? loc.string("daily_streak_active") : loc.string("daily_streak_risk")
            )
            
            statCard(
                icon: "crown.fill",
                iconColor: OvernodeTheme.accentGold,
                title: loc.string("daily_stat_longest_streak"),
                value: "\(longestStreak) " + loc.string("daily_unit_days"),
                subtitle: loc.string("daily_stat_personal_record")
            )
            
            statCard(
                icon: "calendar.badge.checkmark",
                iconColor: Color(red: 0.35, green: 0.65, blue: 0.95),
                title: loc.string("daily_stat_total_claimed"),
                value: "\(totalClaimed)",
                subtitle: loc.string("daily_stat_claims_count")
            )
            
            statCard(
                icon: "circle.circle.fill",
                iconColor: Color(red: 0.95, green: 0.75, blue: 0.20),
                title: loc.string("daily_stat_coins_earned"),
                value: "\(totalCoins)",
                subtitle: loc.string("daily_stat_all_time_coins")
            )
        }
    }
    
    private func statCard(icon: String, iconColor: Color, title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(OvernodeTheme.textSecondary)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(OvernodeTheme.textPrimary)
            
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(OvernodeTheme.textMuted)
        }
        .padding(16)
        .background(OvernodeTheme.cardBackground)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
    }
    
    // MARK: - Streak Milestones
    private var streakMilestonesCard: some View {
        let currentStreak = vm.status?.currentStreak ?? 0
        
        let milestones: [(day: Int, mult: String, bonus: String, title: String)] = [
            (1, "x1.0", "+0", "Jour 1"),
            (3, "x1.1", "+0", "Jour 3"),
            (7, "x1.5", "+50 coins", "Semaine 1"),
            (14, "x1.75", "+100 coins", "Semaine 2"),
            (21, "x2.0", "+150 coins", "Semaine 3"),
            (28, "x2.5", "+200 coins", "Mois 1"),
            (30, "x2.0", "+300c + 🛡️", "Palier 30j")
        ]
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(OvernodeTheme.accentGold)
                Text(loc.string("daily_milestones_title"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(OvernodeTheme.textPrimary)
                Spacer()
                Text(loc.string("daily_milestones_desc"))
                    .font(.system(size: 12))
                    .foregroundColor(OvernodeTheme.textSecondary)
            }
            
            HStack(spacing: 8) {
                ForEach(milestones, id: \.day) { m in
                    let isReached = currentStreak >= m.day
                    
                    VStack(spacing: 6) {
                        Text(m.title)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(isReached ? OvernodeTheme.accentGold : OvernodeTheme.textMuted)
                            .lineLimit(1)
                        
                        ZStack {
                            Circle()
                                .fill(isReached ? OvernodeTheme.accentGold : Color.white.opacity(0.05))
                                .frame(width: 32, height: 32)
                            
                            if isReached {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color.black)
                            } else {
                                Text("\(m.day)j")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(OvernodeTheme.textSecondary)
                            }
                        }
                        
                        Text(m.mult)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(isReached ? OvernodeTheme.textPrimary : OvernodeTheme.textSecondary)
                        
                        Text(m.bonus)
                            .font(.system(size: 9))
                            .foregroundColor(m.bonus.contains("+") && !m.bonus.contains("+0") ? OvernodeTheme.accentGold : OvernodeTheme.textMuted)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 4)
                    .background(isReached ? OvernodeTheme.accentGold.opacity(0.08) : Color.white.opacity(0.02))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isReached ? OvernodeTheme.accentGold.opacity(0.3) : OvernodeTheme.borderSubtle, lineWidth: 1)
                    )
                }
            }
        }
        .padding(16)
        .background(OvernodeTheme.cardBackground)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
    }
    
    // MARK: - Streak Protection
    private var streakProtectionCard: some View {
        let remaining = vm.status?.streakProtection ?? 0
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundColor(Color(red: 0.35, green: 0.75, blue: 0.95))
                Text(loc.string("daily_protection_title"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(OvernodeTheme.textPrimary)
                
                Spacer()
                
                HStack(spacing: 6) {
                    Text(loc.string("daily_protection_remaining") + ":")
                        .font(.system(size: 12))
                        .foregroundColor(OvernodeTheme.textSecondary)
                    Text("\(remaining) " + loc.string("daily_unit_days"))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(remaining > 0 ? Color(red: 0.35, green: 0.75, blue: 0.95) : OvernodeTheme.textMuted)
                }
            }
            
            Text(loc.string("daily_protection_desc"))
                .font(.system(size: 12))
                .foregroundColor(OvernodeTheme.textSecondary)
            
            HStack(spacing: 12) {
                protectionTierButton(
                    level: "bronze",
                    title: "Bronze (1j)",
                    days: 1,
                    price: 100,
                    iconColor: Color(red: 0.80, green: 0.50, blue: 0.20)
                )
                
                protectionTierButton(
                    level: "silver",
                    title: "Silver (3j)",
                    days: 3,
                    price: 250,
                    iconColor: Color(red: 0.75, green: 0.78, blue: 0.82)
                )
                
                protectionTierButton(
                    level: "gold",
                    title: "Gold (7j)",
                    days: 7,
                    price: 500,
                    iconColor: OvernodeTheme.accentGold
                )
            }
        }
        .padding(16)
        .background(OvernodeTheme.cardBackground)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
    }
    
    private func protectionTierButton(level: String, title: String, days: Int, price: Int, iconColor: Color) -> some View {
        let curProtection = vm.status?.streakProtection ?? 0
        let alreadyBetter = curProtection >= days
        let canAfford = userCoins >= price
        
        return Button(action: {
            vm.purchaseProtection(level: level) { newBal in
                onRewardClaimed(newBal)
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "circle.circle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(OvernodeTheme.accentGold)
                        Text("\(price) coins")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(OvernodeTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                if alreadyBetter {
                    Text(loc.string("daily_protection_active"))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(OvernodeTheme.textMuted)
                } else {
                    Text(loc.string("daily_protection_buy"))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(canAfford ? OvernodeTheme.accentGold : OvernodeTheme.textMuted)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.03))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(alreadyBetter || !canAfford || vm.isPurchasingProtection)
    }
}
