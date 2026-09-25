import Foundation
import WidgetKit

public struct ServerWidgetRenewalInfo: Codable, Sendable, Equatable, Identifiable {
    public var id: String { identifier }
    public let identifier: String
    public let name: String
    public let nextRenewalAt: String?
    public let remainingSeconds: TimeInterval?
    public let formattedRemainingTime: String
    public let canRenew: Bool
    public let isExpired: Bool
    
    public init(
        identifier: String,
        name: String,
        nextRenewalAt: String? = nil,
        remainingSeconds: TimeInterval? = nil,
        formattedRemainingTime: String,
        canRenew: Bool = false,
        isExpired: Bool = false
    ) {
        self.identifier = identifier
        self.name = name
        self.nextRenewalAt = nextRenewalAt
        self.remainingSeconds = remainingSeconds
        self.formattedRemainingTime = formattedRemainingTime
        self.canRenew = canRenew
        self.isExpired = isExpired
    }
    
    public static func parseRemainingSeconds(from dateString: String?) -> TimeInterval? {
        guard let dateString = dateString, !dateString.isEmpty else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = isoFormatter.date(from: dateString)
        if date == nil {
            isoFormatter.formatOptions = [.withInternetDateTime]
            date = isoFormatter.date(from: dateString)
        }
        guard let target = date else { return nil }
        return target.timeIntervalSinceNow
    }
    
    public static func formatRemaining(seconds: TimeInterval?) -> String {
        guard let sec = seconds else { return "Unlimited" }
        if sec <= 0 { return "Expired" }
        let total = Int(sec)
        let days = total / 86400
        let hours = (total % 86400) / 3600
        let minutes = (total % 3600) / 60
        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "< 1m"
        }
    }
}

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
    public let servers: [ServerWidgetRenewalInfo]
    
    enum CodingKeys: String, CodingKey {
        case isAuthenticated, canClaim, currentStreak, longestStreak
        case lastClaimTimestamp, nextRewardAmount, coins, totalClaimed
        case streakProtection, lastUpdated, servers
    }
    
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
        lastUpdated: Date = Date(),
        servers: [ServerWidgetRenewalInfo] = []
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
        self.servers = servers
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.isAuthenticated = (try? c.decode(Bool.self, forKey: .isAuthenticated)) ?? false
        self.canClaim = (try? c.decode(Bool.self, forKey: .canClaim)) ?? false
        self.currentStreak = (try? c.decode(Int.self, forKey: .currentStreak)) ?? 0
        self.longestStreak = (try? c.decode(Int.self, forKey: .longestStreak)) ?? 0
        self.lastClaimTimestamp = (try? c.decode(Int64.self, forKey: .lastClaimTimestamp)) ?? 0
        self.nextRewardAmount = (try? c.decode(Int.self, forKey: .nextRewardAmount)) ?? 25
        self.coins = (try? c.decode(Int.self, forKey: .coins)) ?? 0
        self.totalClaimed = (try? c.decode(Int.self, forKey: .totalClaimed)) ?? 0
        self.streakProtection = (try? c.decode(Int.self, forKey: .streakProtection)) ?? 0
        self.lastUpdated = (try? c.decode(Date.self, forKey: .lastUpdated)) ?? Date()
        self.servers = (try? c.decode([ServerWidgetRenewalInfo].self, forKey: .servers)) ?? []
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(isAuthenticated, forKey: .isAuthenticated)
        try c.encode(canClaim, forKey: .canClaim)
        try c.encode(currentStreak, forKey: .currentStreak)
        try c.encode(longestStreak, forKey: .longestStreak)
        try c.encode(lastClaimTimestamp, forKey: .lastClaimTimestamp)
        try c.encode(nextRewardAmount, forKey: .nextRewardAmount)
        try c.encode(coins, forKey: .coins)
        try c.encode(totalClaimed, forKey: .totalClaimed)
        try c.encode(streakProtection, forKey: .streakProtection)
        try c.encode(lastUpdated, forKey: .lastUpdated)
        try c.encode(servers, forKey: .servers)
    }
    
    public var nextExpiringServer: ServerWidgetRenewalInfo? {
        let active = servers.filter { !$0.isExpired }
        if !active.isEmpty {
            return active.sorted { ($0.remainingSeconds ?? .infinity) < ($1.remainingSeconds ?? .infinity) }.first
        }
        return servers.first
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
    
    private var sharedUsersFileURL: URL? {
        let dir = URL(fileURLWithPath: "/Users/Shared/Overnode", isDirectory: true)
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
        
        // 5. Shared /Users/Shared File (Zero sandbox restriction)
        if let sharedURL = sharedUsersFileURL {
            try? encoded.write(to: sharedURL, options: .atomic)
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    public func loadWidgetData() -> DailyRewardWidgetData {
        let decoder = JSONDecoder()
        
        // 0. Read from Shared /Users/Shared File if present
        if let sharedURL = sharedUsersFileURL,
           let data = try? Data(contentsOf: sharedURL),
           let decoded = try? decoder.decode(DailyRewardWidgetData.self, from: data) {
            return decoded
        }
        
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
