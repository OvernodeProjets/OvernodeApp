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
    
    func testServerWidgetRenewalInfoFormattingAndParsing() {
        // Formatting tests
        XCTAssertEqual(ServerWidgetRenewalInfo.formatRemaining(seconds: nil), "Unlimited")
        XCTAssertEqual(ServerWidgetRenewalInfo.formatRemaining(seconds: -10), "Expired")
        XCTAssertEqual(ServerWidgetRenewalInfo.formatRemaining(seconds: 0), "Expired")
        XCTAssertEqual(ServerWidgetRenewalInfo.formatRemaining(seconds: 2 * 86400 + 4 * 3600), "2d 4h")
        XCTAssertEqual(ServerWidgetRenewalInfo.formatRemaining(seconds: 5 * 3600 + 30 * 60), "5h 30m")
        XCTAssertEqual(ServerWidgetRenewalInfo.formatRemaining(seconds: 45 * 60), "45m")
        XCTAssertEqual(ServerWidgetRenewalInfo.formatRemaining(seconds: 30), "< 1m")
        
        // Parsing test from ISO-8601
        let futureDate = Date().addingTimeInterval(3600 * 24)
        let iso = ISO8601DateFormatter().string(from: futureDate)
        let parsed = ServerWidgetRenewalInfo.parseRemainingSeconds(from: iso)
        XCTAssertNotNil(parsed)
        XCTAssertGreaterThan(parsed ?? 0, 3600 * 23)
        XCTAssertLessThanOrEqual(parsed ?? 0, 3600 * 25)
    }
    
    func testServerWidgetRenewalInfoNextExpiringSelection() {
        let server1 = ServerWidgetRenewalInfo(
            identifier: "srv-1",
            name: "Server 1",
            remainingSeconds: 400000,
            formattedRemainingTime: "4d 15h"
        )
        let server2 = ServerWidgetRenewalInfo(
            identifier: "srv-2",
            name: "Server 2",
            remainingSeconds: 36000,
            formattedRemainingTime: "10h 00m"
        )
        let server3 = ServerWidgetRenewalInfo(
            identifier: "srv-3",
            name: "Server 3",
            remainingSeconds: -100,
            formattedRemainingTime: "Expired",
            isExpired: true
        )
        
        // Server 2 is active and expiring soonest
        let data = DailyRewardWidgetData(
            isAuthenticated: true,
            servers: [server1, server2, server3]
        )
        
        XCTAssertEqual(data.nextExpiringServer?.identifier, "srv-2")
    }
    
    func testBackwardCompatibilityWithoutServersKey() throws {
        let legacyJson = """
        {
            "isAuthenticated": true,
            "canClaim": false,
            "currentStreak": 3,
            "longestStreak": 5,
            "lastClaimTimestamp": 1727000000000,
            "nextRewardAmount": 25,
            "coins": 500,
            "totalClaimed": 4,
            "streakProtection": 0,
            "lastUpdated": 812000000.0
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode(DailyRewardWidgetData.self, from: legacyJson)
        XCTAssertEqual(decoded.isAuthenticated, true)
        XCTAssertEqual(decoded.servers, [])
        XCTAssertNil(decoded.nextExpiringServer)
    }
    
    func testServerWidgetRenewalInfoAvailableInFormattingAndParsing() {
        // Parsing test for "23h 58min"
        let sec1 = ServerWidgetRenewalInfo.parseAvailableInSeconds(
            canRenew: false,
            isExpired: false,
            availableInString: "23h 58min",
            nextRenewalAt: nil
        )
        XCTAssertEqual(sec1, 23 * 3600 + 58 * 60)
        
        // Parsing test for "1j 4h" (french)
        let sec2 = ServerWidgetRenewalInfo.parseAvailableInSeconds(
            canRenew: false,
            isExpired: false,
            availableInString: "1j 4h",
            nextRenewalAt: nil
        )
        XCTAssertEqual(sec2, 86400 + 4 * 3600)
        
        // Ready now when canRenew is true
        let secReady = ServerWidgetRenewalInfo.parseAvailableInSeconds(
            canRenew: true,
            isExpired: false,
            availableInString: "10h",
            nextRenewalAt: nil
        )
        XCTAssertEqual(secReady, 0)
        
        // Formatting tests
        XCTAssertEqual(ServerWidgetRenewalInfo.formatAvailableIn(seconds: 0, canRenew: true, isExpired: false), "Ready now")
        XCTAssertEqual(ServerWidgetRenewalInfo.formatAvailableIn(seconds: nil, canRenew: false, isExpired: true), "Expired")
        XCTAssertEqual(ServerWidgetRenewalInfo.formatAvailableIn(seconds: 86280, canRenew: false, isExpired: false, rawString: "23h 58min"), "23h 58m")
        XCTAssertEqual(ServerWidgetRenewalInfo.formatAvailableIn(seconds: 86400 + 4 * 3600, canRenew: false, isExpired: false, rawString: "1j 4h"), "1d 4h")
    }
    
    func testServerWidgetRenewalInfoNextRenewalSelection() {
        let serverPending = ServerWidgetRenewalInfo(
            identifier: "srv-pending",
            name: "Server Pending",
            remainingSeconds: 400000,
            formattedRemainingTime: "4d 15h",
            canRenew: false,
            availableIn: "23h 58min",
            availableInSeconds: 86280,
            formattedAvailableIn: "23h 58m"
        )
        let serverReady = ServerWidgetRenewalInfo(
            identifier: "srv-ready",
            name: "Server Ready",
            remainingSeconds: 43200,
            formattedRemainingTime: "12h 00m",
            canRenew: true,
            availableIn: nil,
            availableInSeconds: 0,
            formattedAvailableIn: "Ready now"
        )
        
        // Server ready is prioritized because renewal is open right now
        let data = DailyRewardWidgetData(
            isAuthenticated: true,
            servers: [serverPending, serverReady]
        )
        XCTAssertEqual(data.nextRenewalServer?.identifier, "srv-ready")
    }
}
