import Foundation

public final class DailyRewardService: Sendable {
    public static let shared = DailyRewardService()
    
    private let client = APIClient.shared
    
    private init() {}
    
    /// Récupère le statut de récompense quotidienne (canClaim, streaks, nextReward, etc.)
    public func fetchStatus() async throws -> DailyRewardStatus {
        if ProcessInfo.processInfo.environment["OVERNODE_DEMO"] == "1" {
            return DailyRewardStatus(
                userId: "1",
                canClaim: true,
                daysSinceLastClaim: 1,
                currentStreak: 6,
                longestStreak: 12,
                lastClaimTimestamp: Int64(Date().addingTimeInterval(-86400).timeIntervalSince1970 * 1000),
                totalClaimed: 24,
                totalCoinsEarned: 1150,
                streakProtection: 1,
                projectedStreak: 7,
                streakWillMaintain: true,
                willUseProtection: false,
                nextReward: DailyRewardTier(
                    amount: 87,
                    baseAmount: 25,
                    multiplier: 1.5,
                    milestoneBonus: 50,
                    milestoneMessage: "Weekly streak bonus! +50 coins"
                )
            )
        }
        return try await client.request(endpoint: "/api/daily-rewards/status")
    }
    
    /// Réclame la récompense quotidienne
    public func claimDailyReward() async throws -> DailyRewardClaimResponse {
        if ProcessInfo.processInfo.environment["OVERNODE_DEMO"] == "1" {
            return DailyRewardClaimResponse(
                success: true,
                error: nil,
                code: nil,
                userId: "1",
                timestamp: Int64(Date().timeIntervalSince1970 * 1000),
                streak: 7,
                reward: 87,
                newBalance: 437,
                streakMaintained: true,
                streakProtectionUsed: false,
                streakProtectionRemaining: 1,
                baseAmount: 25,
                multiplier: 1.5,
                milestoneBonus: 50,
                milestoneMessage: "Weekly streak bonus! +50 coins",
                nextReward: DailyRewardTier(amount: 30, baseAmount: 25, multiplier: 1.2)
            )
        }
        return try await client.request(endpoint: "/api/daily-rewards/claim", method: "POST")
    }
    
    /// Récupère le classement des meilleures séries (streaks)
    public func fetchLeaderboard(limit: Int = 15) async throws -> [DailyLeaderboardEntry] {
        if ProcessInfo.processInfo.environment["OVERNODE_DEMO"] == "1" {
            return [
                DailyLeaderboardEntry(userId: "u-101", username: "OverMaster", currentStreak: 64, longestStreak: 78, totalClaimed: 95),
                DailyLeaderboardEntry(userId: "u-102", username: "CloudArchitect", currentStreak: 45, longestStreak: 45, totalClaimed: 60),
                DailyLeaderboardEntry(userId: "u-103", username: "SwiftTitan", currentStreak: 32, longestStreak: 35, totalClaimed: 48),
                DailyLeaderboardEntry(userId: "u-104", username: "VoxelHero", currentStreak: 28, longestStreak: 28, totalClaimed: 33),
                DailyLeaderboardEntry(userId: "1", username: "OvernodeUser", currentStreak: 6, longestStreak: 12, totalClaimed: 24),
                DailyLeaderboardEntry(userId: "u-106", username: "ByteCrafter", currentStreak: 5, longestStreak: 19, totalClaimed: 22)
            ]
        }
        return try await client.request(endpoint: "/api/daily-rewards/leaderboard?limit=\(limit)")
    }
    
    /// Récupère l'historique des récompenses réclamées
    public func fetchHistory(limit: Int = 20) async throws -> [DailyRewardHistoryItem] {
        if ProcessInfo.processInfo.environment["OVERNODE_DEMO"] == "1" {
            let now = Date().timeIntervalSince1970 * 1000
            let dayMs: Double = 86400 * 1000
            return [
                DailyRewardHistoryItem(
                    id: "hist-1",
                    timestamp: Int64(now - dayMs),
                    streak: 6,
                    reward: 30,
                    streakMaintained: true,
                    streakProtectionUsed: false,
                    baseAmount: 25,
                    multiplier: 1.2,
                    milestoneBonus: nil,
                    milestoneMessage: nil
                ),
                DailyRewardHistoryItem(
                    id: "hist-2",
                    timestamp: Int64(now - dayMs * 2),
                    streak: 5,
                    reward: 30,
                    streakMaintained: true,
                    streakProtectionUsed: false,
                    baseAmount: 25,
                    multiplier: 1.2,
                    milestoneBonus: nil,
                    milestoneMessage: nil
                ),
                DailyRewardHistoryItem(
                    id: "hist-3",
                    timestamp: Int64(now - dayMs * 3),
                    streak: 4,
                    reward: 27,
                    streakMaintained: true,
                    streakProtectionUsed: false,
                    baseAmount: 25,
                    multiplier: 1.1,
                    milestoneBonus: nil,
                    milestoneMessage: nil
                )
            ]
        }
        return try await client.request(endpoint: "/api/daily-rewards/history?limit=\(limit)")
    }
    
    /// Acheter une protection de série (bronze: 1j 100c, silver: 3j 250c, gold: 7j 500c)
    public func purchaseStreakProtection(level: String) async throws -> StreakProtectionResponse {
        struct Body: Encodable {
            let level: String
        }
        let data = try JSONEncoder().encode(Body(level: level))
        return try await client.request(
            endpoint: "/api/daily-rewards/protection",
            method: "POST",
            body: data
        )
    }
}

