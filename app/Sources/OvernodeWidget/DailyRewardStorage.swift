import Foundation
import WidgetKit

public struct DailyRewardWidgetData: Codable, Sendable, Equatable {
    public let canClaim: Bool
    public let currentStreak: Int
    public let lastClaimTimestamp: Int64
    public let nextRewardAmount: Int
    public let coins: Int
    public let lastUpdated: Date
    
    public init(
        canClaim: Bool = true,
        currentStreak: Int = 0,
        lastClaimTimestamp: Int64 = 0,
        nextRewardAmount: Int = 25,
        coins: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.canClaim = canClaim
        self.currentStreak = currentStreak
        self.lastClaimTimestamp = lastClaimTimestamp
        self.nextRewardAmount = nextRewardAmount
        self.coins = coins
        self.lastUpdated = lastUpdated
    }
    
    /// Target date for next claim if already claimed today: next local midnight
    public var nextClaimDate: Date {
        if canClaim {
            return Date()
        }
        let calendar = Calendar.current
        if let nextDay = calendar.date(byAdding: .day, value: 1, to: Date()) {
            return calendar.startOfDay(for: nextDay)
        }
        return Date().addingTimeInterval(86400)
    }
    
    /// Time interval remaining until next reward is available
    public var timeIntervalRemaining: TimeInterval {
        if canClaim { return 0 }
        return max(0, nextClaimDate.timeIntervalSince(Date()))
    }
    
    /// Formatted time in hours then minutes: e.g. "5h 24m"
    public var formattedRemainingTime: String {
        if canClaim {
            return "Ready!"
        }
        let totalSeconds = Int(timeIntervalRemaining)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(max(1, minutes))m"
        }
    }
}

public final class DailyRewardStorage: Sendable {
    public static let shared = DailyRewardStorage()
    
    public static let sharedSuiteName = "group.fr.overnode.OvernodeApp"
    private let key = "overnode_daily_reward_widget_data"
    
    private init() {}
    
    private var userDefaults: UserDefaults {
        UserDefaults(suiteName: DailyRewardStorage.sharedSuiteName) ?? UserDefaults.standard
    }
    
    public func saveWidgetData(_ data: DailyRewardWidgetData) {
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: key)
            userDefaults.synchronize()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    public func loadWidgetData() -> DailyRewardWidgetData {
        if let data = userDefaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(DailyRewardWidgetData.self, from: data) {
            return decoded
        }
        return DailyRewardWidgetData(
            canClaim: true,
            currentStreak: 0,
            lastClaimTimestamp: 0,
            nextRewardAmount: 25,
            coins: 0,
            lastUpdated: Date()
        )
    }
}

