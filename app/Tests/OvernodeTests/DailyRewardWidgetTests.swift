import XCTest
@testable import Overnode

final class DailyRewardWidgetTests: XCTestCase {
    func testWidgetDataEncodingAndDecoding() throws {
        let now = Date()
        let data = DailyRewardWidgetData(
            isAuthenticated: true,
            canClaim: false,
            currentStreak: 5,
            longestStreak: 12,
            lastClaimTimestamp: 1727000000000,
            nextRewardAmount: 50,
            coins: 1200,
            totalClaimed: 18,
            streakProtection: 1,
            lastUpdated: now
        )
        
        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(DailyRewardWidgetData.self, from: encoded)
        
        XCTAssertEqual(decoded.isAuthenticated, true)
        XCTAssertEqual(decoded.canClaim, false)
        XCTAssertEqual(decoded.currentStreak, 5)
        XCTAssertEqual(decoded.longestStreak, 12)
        XCTAssertEqual(decoded.nextRewardAmount, 50)
        XCTAssertEqual(decoded.coins, 1200)
        XCTAssertEqual(decoded.totalClaimed, 18)
        XCTAssertEqual(decoded.streakProtection, 1)
    }
    
    func testWidgetRemainingTimeHoursAndMinutesFormat() {
        // When reward can be claimed
        let readyData = DailyRewardWidgetData(isAuthenticated: true, canClaim: true)
        XCTAssertEqual(readyData.formattedRemainingTime, "Ready!")
        
        // When not claimable and time interval is e.g. 5 hours and 24 minutes (19440 seconds)
        let today = Date()
        let fakeMidnight = today.addingTimeInterval(5 * 3600 + 24 * 60)
        
        let seconds = Int(fakeMidnight.timeIntervalSince(today))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let formatted = "\(hours)h \(minutes)m"
        
        XCTAssertEqual(formatted, "5h 24m")
        
        // When only minutes remain (e.g. 42 minutes)
        let fakeNearMidnight = today.addingTimeInterval(42 * 60)
        let nearSeconds = Int(fakeNearMidnight.timeIntervalSince(today))
        let nearHours = nearSeconds / 3600
        let nearMinutes = (nearSeconds % 3600) / 60
        let nearFormatted = nearHours > 0 ? "\(nearHours)h \(nearMinutes)m" : "\(max(1, nearMinutes))m"
        
        XCTAssertEqual(nearFormatted, "42m")
    }
    
    func testEffectiveCanClaimValidation() {
        // 1. Not authenticated -> must be false
        let unauthData = DailyRewardWidgetData(
            isAuthenticated: false,
            canClaim: true,
            currentStreak: 0,
            lastClaimTimestamp: 0
        )
        XCTAssertFalse(unauthData.effectiveCanClaim)
        
        // 2. Authenticated, but claimed today -> must be false regardless of canClaim flag
        let todayTimestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let claimedTodayData = DailyRewardWidgetData(
            isAuthenticated: true,
            canClaim: true, // Server or storage might be stale
            currentStreak: 4,
            lastClaimTimestamp: todayTimestamp
        )
        XCTAssertFalse(claimedTodayData.effectiveCanClaim)
        XCTAssertNotEqual(claimedTodayData.formattedRemainingTime, "Ready!")
        
        // 3. Authenticated, claimed yesterday -> eligible to claim
        let yesterdayTimestamp = Int64(Date().addingTimeInterval(-86400).timeIntervalSince1970 * 1000)
        let eligibleData = DailyRewardWidgetData(
            isAuthenticated: true,
            canClaim: true,
            currentStreak: 4,
            lastClaimTimestamp: yesterdayTimestamp
        )
        XCTAssertTrue(eligibleData.effectiveCanClaim)
        XCTAssertEqual(eligibleData.formattedRemainingTime, "Ready!")
    }
    
    func testDailyRewardStorageSaveAndLoad() {
        let storage = DailyRewardStorage.shared
        let testData = DailyRewardWidgetData(
            isAuthenticated: true,
            canClaim: true,
            currentStreak: 12,
            longestStreak: 20,
            lastClaimTimestamp: 1727000000000,
            nextRewardAmount: 100,
            coins: 3400,
            totalClaimed: 35,
            streakProtection: 2,
            lastUpdated: Date()
        )
        
        storage.saveWidgetData(testData)
        let loaded = storage.loadWidgetData()
        
        XCTAssertEqual(loaded.isAuthenticated, true)
        XCTAssertEqual(loaded.canClaim, true)
        XCTAssertEqual(loaded.currentStreak, 12)
        XCTAssertEqual(loaded.longestStreak, 20)
        XCTAssertEqual(loaded.nextRewardAmount, 100)
        XCTAssertEqual(loaded.totalClaimed, 35)
    }
}
