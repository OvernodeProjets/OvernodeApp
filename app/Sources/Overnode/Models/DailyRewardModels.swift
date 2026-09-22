import Foundation

// MARK: - Daily Reward Status Response
public struct DailyRewardStatus: Codable, Sendable, Equatable {
    public let userId: String?
    public let canClaim: Bool
    public let daysSinceLastClaim: Int
    public let currentStreak: Int
    public let longestStreak: Int
    public let lastClaimTimestamp: Int64
    public let totalClaimed: Int
    public let totalCoinsEarned: Int
    public let streakProtection: Int
    public let projectedStreak: Int
    public let streakWillMaintain: Bool
    public let willUseProtection: Bool
    public let nextReward: DailyRewardTier?
    
    public init(
        userId: String? = nil,
        canClaim: Bool = true,
        daysSinceLastClaim: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastClaimTimestamp: Int64 = 0,
        totalClaimed: Int = 0,
        totalCoinsEarned: Int = 0,
        streakProtection: Int = 0,
        projectedStreak: Int = 1,
        streakWillMaintain: Bool = true,
        willUseProtection: Bool = false,
        nextReward: DailyRewardTier? = nil
    ) {
        self.userId = userId
        self.canClaim = canClaim
        self.daysSinceLastClaim = daysSinceLastClaim
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastClaimTimestamp = lastClaimTimestamp
        self.totalClaimed = totalClaimed
        self.totalCoinsEarned = totalCoinsEarned
        self.streakProtection = streakProtection
        self.projectedStreak = projectedStreak
        self.streakWillMaintain = streakWillMaintain
        self.willUseProtection = willUseProtection
        self.nextReward = nextReward
    }
}

// MARK: - Daily Reward Tier
public struct DailyRewardTier: Codable, Sendable, Equatable {
    public let amount: Int
    public let baseAmount: Int
    public let multiplier: Double
    public let milestoneBonus: Int?
    public let milestoneMessage: String?
    
    public init(
        amount: Int,
        baseAmount: Int = 25,
        multiplier: Double = 1.0,
        milestoneBonus: Int? = nil,
        milestoneMessage: String? = nil
    ) {
        self.amount = amount
        self.baseAmount = baseAmount
        self.multiplier = multiplier
        self.milestoneBonus = milestoneBonus
        self.milestoneMessage = milestoneMessage
    }
}

// MARK: - Daily Reward Claim Response
public struct DailyRewardClaimResponse: Codable, Sendable {
    public let success: Bool?
    public let error: String?
    public let code: String?
    public let userId: String?
    public let timestamp: Int64?
    public let streak: Int?
    public let reward: Int?
    public let newBalance: Int?
    public let streakMaintained: Bool?
    public let streakProtectionUsed: Bool?
    public let streakProtectionRemaining: Int?
    public let baseAmount: Int?
    public let multiplier: Double?
    public let milestoneBonus: Int?
    public let milestoneMessage: String?
    public let nextReward: DailyRewardTier?
}

// MARK: - Daily Reward Leaderboard Entry
public struct DailyLeaderboardEntry: Codable, Identifiable, Sendable, Equatable {
    public var id: String { userId }
    public let userId: String
    public let username: String
    public let currentStreak: Int
    public let longestStreak: Int
    public let totalClaimed: Int
    
    public init(
        userId: String,
        username: String,
        currentStreak: Int,
        longestStreak: Int,
        totalClaimed: Int
    ) {
        self.userId = userId
        self.username = username
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalClaimed = totalClaimed
    }
}

// MARK: - Daily Reward History Entry
public struct DailyRewardHistoryItem: Codable, Identifiable, Sendable, Equatable {
    public let id: String
    public let timestamp: Int64
    public let streak: Int
    public let reward: Int
    public let streakMaintained: Bool
    public let streakProtectionUsed: Bool
    public let baseAmount: Int
    public let multiplier: Double
    public let milestoneBonus: Int?
    public let milestoneMessage: String?
    
    public var formattedDate: String {
        let date = Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    public init(
        id: String = UUID().uuidString,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        streak: Int,
        reward: Int,
        streakMaintained: Bool = true,
        streakProtectionUsed: Bool = false,
        baseAmount: Int = 25,
        multiplier: Double = 1.0,
        milestoneBonus: Int? = nil,
        milestoneMessage: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.streak = streak
        self.reward = reward
        self.streakMaintained = streakMaintained
        self.streakProtectionUsed = streakProtectionUsed
        self.baseAmount = baseAmount
        self.multiplier = multiplier
        self.milestoneBonus = milestoneBonus
        self.milestoneMessage = milestoneMessage
    }
}

// MARK: - Streak Protection Purchase Response
public struct StreakProtectionResponse: Codable, Sendable {
    public let success: Bool?
    public let error: String?
    public let code: String?
    public let userId: String?
    public let level: String?
    public let protectionDays: Int?
    public let price: Int?
    public let newBalance: Int?
}

