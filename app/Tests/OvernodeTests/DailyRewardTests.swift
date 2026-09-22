import XCTest
@testable import Overnode

final class DailyRewardTests: XCTestCase {
    func testDailyRewardStatusDecoding() throws {
        let json = """
        {
            "userId": "usr_99",
            "canClaim": true,
            "daysSinceLastClaim": 1,
            "currentStreak": 6,
            "longestStreak": 14,
            "lastClaimTimestamp": 1726990000000,
            "totalClaimed": 25,
            "totalCoinsEarned": 1250,
            "streakProtection": 2,
            "projectedStreak": 7,
            "streakWillMaintain": true,
            "willUseProtection": false,
            "nextReward": {
                "amount": 87,
                "baseAmount": 25,
                "multiplier": 1.5,
                "milestoneBonus": 50,
                "milestoneMessage": "Weekly streak bonus! +50 coins"
            }
        }
        """.data(using: .utf8)!
        
        let status = try JSONDecoder().decode(DailyRewardStatus.self, from: json)
        XCTAssertEqual(status.userId, "usr_99")
        XCTAssertTrue(status.canClaim)
        XCTAssertEqual(status.daysSinceLastClaim, 1)
        XCTAssertEqual(status.currentStreak, 6)
        XCTAssertEqual(status.longestStreak, 14)
        XCTAssertEqual(status.totalClaimed, 25)
        XCTAssertEqual(status.totalCoinsEarned, 1250)
        XCTAssertEqual(status.streakProtection, 2)
        XCTAssertEqual(status.projectedStreak, 7)
        XCTAssertTrue(status.streakWillMaintain)
        XCTAssertFalse(status.willUseProtection)
        XCTAssertEqual(status.nextReward?.amount, 87)
        XCTAssertEqual(status.nextReward?.baseAmount, 25)
        XCTAssertEqual(status.nextReward?.multiplier, 1.5)
        XCTAssertEqual(status.nextReward?.milestoneBonus, 50)
        XCTAssertEqual(status.nextReward?.milestoneMessage, "Weekly streak bonus! +50 coins")
    }
    
    func testDailyRewardClaimResponseDecoding() throws {
        let json = """
        {
            "success": true,
            "userId": "usr_99",
            "timestamp": 1727000000000,
            "streak": 7,
            "reward": 87,
            "newBalance": 1587,
            "streakMaintained": true,
            "streakProtectionUsed": false,
            "streakProtectionRemaining": 2,
            "baseAmount": 25,
            "multiplier": 1.5,
            "milestoneBonus": 50,
            "milestoneMessage": "Weekly streak bonus! +50 coins",
            "nextReward": {
                "amount": 30,
                "baseAmount": 25,
                "multiplier": 1.2
            }
        }
        """.data(using: .utf8)!
        
        let res = try JSONDecoder().decode(DailyRewardClaimResponse.self, from: json)
        XCTAssertEqual(res.success, true)
        XCTAssertEqual(res.streak, 7)
        XCTAssertEqual(res.reward, 87)
        XCTAssertEqual(res.newBalance, 1587)
        XCTAssertEqual(res.streakMaintained, true)
        XCTAssertEqual(res.streakProtectionUsed, false)
        XCTAssertEqual(res.streakProtectionRemaining, 2)
        XCTAssertEqual(res.nextReward?.amount, 30)
    }
    
    func testDailyLeaderboardDecoding() throws {
        let json = """
        [
            { "userId": "u1", "username": "Alice", "currentStreak": 15, "longestStreak": 20, "totalClaimed": 45 },
            { "userId": "u2", "username": "Bob", "currentStreak": 10, "longestStreak": 12, "totalClaimed": 30 }
        ]
        """.data(using: .utf8)!
        
        let list = try JSONDecoder().decode([DailyLeaderboardEntry].self, from: json)
        XCTAssertEqual(list.count, 2)
        XCTAssertEqual(list[0].id, "u1")
        XCTAssertEqual(list[0].username, "Alice")
        XCTAssertEqual(list[0].currentStreak, 15)
        XCTAssertEqual(list[0].longestStreak, 20)
        XCTAssertEqual(list[0].totalClaimed, 45)
        XCTAssertEqual(list[1].username, "Bob")
    }
    
    func testDailyHistoryItemDecoding() throws {
        let json = """
        [
            {
                "id": "tx-123",
                "timestamp": 1727000000000,
                "streak": 7,
                "reward": 87,
                "streakMaintained": true,
                "streakProtectionUsed": false,
                "baseAmount": 25,
                "multiplier": 1.5,
                "milestoneBonus": 50,
                "milestoneMessage": "Weekly streak bonus! +50 coins"
            }
        ]
        """.data(using: .utf8)!
        
        let items = try JSONDecoder().decode([DailyRewardHistoryItem].self, from: json)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].id, "tx-123")
        XCTAssertEqual(items[0].streak, 7)
        XCTAssertEqual(items[0].reward, 87)
        XCTAssertTrue(items[0].streakMaintained)
        XCTAssertFalse(items[0].streakProtectionUsed)
        XCTAssertEqual(items[0].milestoneBonus, 50)
        XCTAssertFalse(items[0].formattedDate.isEmpty)
    }
    
    func testStreakProtectionResponseDecoding() throws {
        let json = """
        {
            "success": true,
            "userId": "usr_99",
            "level": "silver",
            "protectionDays": 3,
            "price": 250,
            "newBalance": 950
        }
        """.data(using: .utf8)!
        
        let res = try JSONDecoder().decode(StreakProtectionResponse.self, from: json)
        XCTAssertEqual(res.success, true)
        XCTAssertEqual(res.level, "silver")
        XCTAssertEqual(res.protectionDays, 3)
        XCTAssertEqual(res.price, 250)
        XCTAssertEqual(res.newBalance, 950)
    }
    
    func testNavigationTabIncludesDailyReward() {
        let tabs = NavigationTab.allCases
        XCTAssertTrue(tabs.contains(.dailyReward))
        XCTAssertEqual(NavigationTab.dailyReward.rawValue, "daily_reward")
        XCTAssertEqual(NavigationTab.dailyReward.iconName, "gift.fill")
    }
    
    @MainActor func testDailyRewardTranslations() {
        let loc = LocalizationManager.shared
        
        // French translations
        loc.setLanguage(.french)
        XCTAssertEqual(loc.string("nav_daily_reward"), "Récompense Quotidienne")
        XCTAssertEqual(loc.string("daily_title"), "Récompense Quotidienne")
        XCTAssertEqual(loc.string("daily_tab_claim"), "Réclamer")
        XCTAssertEqual(loc.string("daily_tab_leaderboard"), "Classement Séries")
        XCTAssertEqual(loc.string("daily_tab_history"), "Historique")
        XCTAssertEqual(loc.string("daily_claim_button"), "Récupérer")
        
        // English translations
        loc.setLanguage(.english)
        XCTAssertEqual(loc.string("nav_daily_reward"), "Daily Reward")
        XCTAssertEqual(loc.string("daily_title"), "Daily Reward")
        XCTAssertEqual(loc.string("daily_tab_claim"), "Claim")
        XCTAssertEqual(loc.string("daily_tab_leaderboard"), "Streak Scoreboard")
        XCTAssertEqual(loc.string("daily_tab_history"), "History")
        XCTAssertEqual(loc.string("daily_claim_button"), "Claim Reward")
        
        // Reset to French
        loc.setLanguage(.french)
    }
}

