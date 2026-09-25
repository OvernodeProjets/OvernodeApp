import Foundation
import WidgetKit

public struct DailyRewardWidgetData: Codable, Sendable, Equatable {
    public let isAuthenticated: Bool
    public let canClaim: Bool
    public let currentStreak: Int
    public let longestStreak: Int
    public let lastClaimTimestamp: Int64
    public let nextRewardAmount: Int
    public let coins: Int
    public let totalClaimed: Int
    public let streakProtection: Int
    public let lastUpdated: Date
    
    public init(
        isAuthenticated: Bool = false,
        canClaim: Bool = false,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastClaimTimestamp: Int64 = 0,
        nextRewardAmount: Int = 25,
        coins: Int = 0,
        totalClaimed: Int = 0,
        streakProtection: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.isAuthenticated = isAuthenticated
        self.canClaim = canClaim
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastClaimTimestamp = lastClaimTimestamp
        self.nextRewardAmount = nextRewardAmount
        self.coins = coins
        self.totalClaimed = totalClaimed
        self.streakProtection = streakProtection
        self.lastUpdated = lastUpdated
    }
    
    /// Real-time computed eligibility verifying session, previous claims today, and server flag
    public var effectiveCanClaim: Bool {
        guard isAuthenticated else { return false }
        
        // If last claim timestamp is valid, verify whether it was already claimed today
        if lastClaimTimestamp > 0 {
            let claimDate = Date(timeIntervalSince1970: Double(lastClaimTimestamp) / 1000.0)
            if Calendar.current.isDateInToday(claimDate) {
                return false
            }
        }
        
        return canClaim
    }
    
    /// Target date for next claim if already claimed today: next local midnight
    public var nextClaimDate: Date {
        if effectiveCanClaim {
            return Date()
        }
        let calendar = Calendar.current
        if let nextDay = calendar.date(byAdding: .day, value: 1, to: Date()) {
            return calendar.startOfDay(for: nextDay)
        }
        return Date().addingTimeInterval(86400)
    }
    
    /// Time interval remaining until next reward is available (at midnight)
    public var timeIntervalRemaining: TimeInterval {
        if effectiveCanClaim { return 0 }
        return max(0, nextClaimDate.timeIntervalSince(Date()))
    }
    
    /// Formatted time in hours then minutes: e.g. "5h 24m"
    public var formattedRemainingTime: String {
        if effectiveCanClaim {
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
    private let fileName = "daily_reward_widget.json"
    
    private init() {}
    
    private var suiteUserDefaults: UserDefaults? {
        UserDefaults(suiteName: DailyRewardStorage.sharedSuiteName)
    }
    
    private var groupContainerFileURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: DailyRewardStorage.sharedSuiteName)?
            .appendingPathComponent(fileName)
    }
    
    private var appSupportFileURL: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = appSupport.appendingPathComponent("Overnode", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(fileName)
    }
    
    public func saveWidgetData(_ data: DailyRewardWidgetData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        
        // 1. Suite UserDefaults (App Group)
        if let suite = suiteUserDefaults {
            suite.set(encoded, forKey: key)
            suite.synchronize()
        }
        
        // 2. Standard UserDefaults
        UserDefaults.standard.set(encoded, forKey: key)
        UserDefaults.standard.synchronize()
        
        // 3. Shared App Group File
        if let fileURL = groupContainerFileURL {
            try? encoded.write(to: fileURL, options: .atomic)
        }
        
        // 4. Application Support File
        if let appSupportURL = appSupportFileURL {
            try? encoded.write(to: appSupportURL, options: .atomic)
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    public func loadWidgetData() -> DailyRewardWidgetData {
        let decoder = JSONDecoder()
        
        // 1. Read from shared App Group File if present
        if let fileURL = groupContainerFileURL,
           let data = try? Data(contentsOf: fileURL),
           let decoded = try? decoder.decode(DailyRewardWidgetData.self, from: data) {
            return decoded
        }
        
        // 2. Read from suite UserDefaults
        if let data = suiteUserDefaults?.data(forKey: key),
           let decoded = try? decoder.decode(DailyRewardWidgetData.self, from: data) {
            return decoded
        }
        
        // 3. Read from Application Support File
        if let appSupportURL = appSupportFileURL,
           let data = try? Data(contentsOf: appSupportURL),
           let decoded = try? decoder.decode(DailyRewardWidgetData.self, from: data) {
            return decoded
        }
        
        // 4. Read from Standard UserDefaults
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? decoder.decode(DailyRewardWidgetData.self, from: data) {
            return decoded
        }
        
        // Default: unauthenticated, not claimable until real data sync
        return DailyRewardWidgetData(
            isAuthenticated: false,
            canClaim: false,
            currentStreak: 0,
            longestStreak: 0,
            lastClaimTimestamp: 0,
            nextRewardAmount: 25,
            coins: 0,
            totalClaimed: 0,
            streakProtection: 0,
            lastUpdated: Date()
        )
    }
}
