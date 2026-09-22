import XCTest
@testable import Overnode

final class DailyRewardWidgetTests: XCTestCase {
    func testWidgetDataEncodingAndDecoding() throws {
        let now = Date()
        let data = DailyRewardWidgetData(
            canClaim: false,
            currentStreak: 5,
            lastClaimTimestamp: 1727000000000,
            nextRewardAmount: 50,
            coins: 1200,
            lastUpdated: now
        )
        
        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(DailyRewardWidgetData.self, from: encoded)
        
        XCTAssertEqual(decoded.canClaim, false)
        XCTAssertEqual(decoded.currentStreak, 5)
        XCTAssertEqual(decoded.nextRewardAmount, 50)
        XCTAssertEqual(decoded.coins, 1200)
    }
    
    func testWidgetRemainingTimeHoursAndMinutesFormat() {
        // When reward can be claimed
        let readyData = DailyRewardWidgetData(canClaim: true)
        XCTAssertEqual(readyData.formattedRemainingTime, "Ready!")
        
        // When not claimable and time interval is e.g. 5 hours and 24 minutes (19440 seconds)
        let cal = Calendar.current
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
    
    func testDailyRewardStorageSaveAndLoad() {
        let storage = DailyRewardStorage.shared
        let testData = DailyRewardWidgetData(
            canClaim: true,
            currentStreak: 12,
            lastClaimTimestamp: 1727000000000,
            nextRewardAmount: 100,
            coins: 3400,
            lastUpdated: Date()
        )
        
        storage.saveWidgetData(testData)
        let loaded = storage.loadWidgetData()
        
        XCTAssertEqual(loaded.canClaim, true)
        XCTAssertEqual(loaded.currentStreak, 12)
        XCTAssertEqual(loaded.nextRewardAmount, 100)
    }
}
