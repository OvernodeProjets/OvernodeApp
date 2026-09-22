import XCTest
@testable import Overnode

final class WalletStoreSupportTests: XCTestCase {
    func testBillingInfoDecoding() throws {
        let json = """
        {
            "balances": {
                "credit_eur": 12.50,
                "coins": 3500
            },
            "currency": "EUR",
            "coin_packages": [
                { "amount": 1000, "price_eur": 1.79 },
                { "amount": 2500, "price_eur": 3.99 },
                { "amount": 5000, "price_eur": 5.99 }
            ]
        }
        """.data(using: .utf8)!
        
        let billing = try JSONDecoder().decode(BillingInfo.self, from: json)
        XCTAssertEqual(billing.balances?.creditEur, 12.50)
        XCTAssertEqual(billing.balances?.coins, 3500)
        XCTAssertEqual(billing.currency, "EUR")
        XCTAssertEqual(billing.coinPackages?.count, 3)
        XCTAssertEqual(billing.coinPackages?[0].amount, 1000)
        XCTAssertEqual(billing.coinPackages?[0].priceEur, 1.79)
        XCTAssertEqual(billing.coinPackages?[1].amount, 2500)
        XCTAssertEqual(billing.coinPackages?[1].priceEur, 3.99)
        XCTAssertEqual(billing.coinPackages?[2].amount, 5000)
        XCTAssertEqual(billing.coinPackages?[2].priceEur, 5.99)
    }
    
    func testLeaderboardDecoding() throws {
        let json = """
        {
            "leaderboard": [
                { "rank": 1, "username": "Alice", "coins": 15000 },
                { "rank": 2, "username": "Bob", "coins": 9000 },
                { "rank": 3, "username": "Charlie", "coins": 4500 }
            ],
            "userRank": {
                "rank": 2,
                "username": "Bob",
                "coins": 9000,
                "inTop": true
            }
        }
        """.data(using: .utf8)!
        
        let board = try JSONDecoder().decode(LeaderboardResponse.self, from: json)
        XCTAssertEqual(board.leaderboard.count, 3)
        XCTAssertEqual(board.leaderboard[0].rank, 1)
        XCTAssertEqual(board.leaderboard[0].username, "Alice")
        XCTAssertEqual(board.leaderboard[0].coins, 15000)
        XCTAssertEqual(board.userRank?.rank, 2)
        XCTAssertEqual(board.userRank?.username, "Bob")
        XCTAssertEqual(board.userRank?.inTop, true)
    }
    
    func testStoreConfigDecoding() throws {
        let json = """
        {
            "prices": {
                "resources": {
                    "ram": 600,
                    "disk": 400,
                    "cpu": 500,
                    "servers": 200
                }
            },
            "multipliers": {
                "ram": 1024,
                "disk": 5120,
                "cpu": 100,
                "servers": 1
            },
            "limits": {
                "ram": 96,
                "disk": 200,
                "cpu": 36,
                "servers": 20
            },
            "userBalance": 1200,
            "canAfford": {
                "ram": true,
                "disk": true,
                "cpu": true,
                "servers": true
            }
        }
        """.data(using: .utf8)!
        
        let config = try JSONDecoder().decode(StoreConfigResponse.self, from: json)
        XCTAssertEqual(config.prices?.resources?["ram"], 600)
        XCTAssertEqual(config.multipliers?["ram"], 1024)
        XCTAssertEqual(config.limits?["disk"], 200)
        XCTAssertEqual(config.userBalance, 1200)
        XCTAssertEqual(config.canAfford?["ram"], true)
    }
    
    func testStoreBuyPayloadEncoding() throws {
        let payload = StoreBuyPayload(resourceType: "ram", amount: 2)
        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(StoreBuyPayload.self, from: data)
        XCTAssertEqual(decoded.resourceType, "ram")
        XCTAssertEqual(decoded.amount, 2)
    }
    
    func testSupportTicketDecoding() throws {
        let json = """
        {
            "id": "tkt-12345",
            "userId": "user-88",
            "subject": "Need more RAM",
            "description": "Please help me configure extra memory.",
            "priority": "high",
            "category": "technical",
            "status": "open",
            "createdAt": "2026-09-22T10:00:00Z",
            "messages": [
                {
                    "id": "msg-1",
                    "ticketId": "tkt-12345",
                    "userId": "user-88",
                    "content": "Initial message",
                    "isStaff": false,
                    "createdAt": "2026-09-22T10:00:00Z"
                },
                {
                    "id": "msg-2",
                    "ticketId": "tkt-12345",
                    "userId": "staff-01",
                    "content": "Hello! We are looking into this.",
                    "isStaff": true,
                    "createdAt": "2026-09-22T10:05:00Z"
                }
            ]
        }
        """.data(using: .utf8)!
        
        let ticket = try JSONDecoder().decode(SupportTicket.self, from: json)
        XCTAssertEqual(ticket.id, "tkt-12345")
        XCTAssertEqual(ticket.subject, "Need more RAM")
        XCTAssertEqual(ticket.priority, "high")
        XCTAssertTrue(ticket.isOpen)
        XCTAssertEqual(ticket.messages?.count, 2)
        XCTAssertEqual(ticket.messages?[1].isStaff, true)
    }
    
    func testNavigationTabs() {
        let tabs = NavigationTab.allCases
        XCTAssertTrue(tabs.contains(.dashboard))
        XCTAssertTrue(tabs.contains(.servers))
        XCTAssertTrue(tabs.contains(.wallet))
        XCTAssertTrue(tabs.contains(.store))
        XCTAssertTrue(tabs.contains(.support))
        XCTAssertTrue(tabs.contains(.afk))
        XCTAssertTrue(tabs.contains(.settings))
        
        for tab in tabs {
            XCTAssertFalse(tab.iconName.isEmpty)
        }
    }

    @MainActor func testWalletStoreSupportTranslations() {
        let loc = LocalizationManager.shared
        
        // Test French
        loc.setLanguage(.french)
        XCTAssertEqual(loc.string("nav_wallet"), "Wallet")
        XCTAssertEqual(loc.string("nav_store"), "Boutique")
        XCTAssertEqual(loc.string("nav_support"), "Support")
        XCTAssertEqual(loc.string("nav_afk"), "Session AFK")
        XCTAssertEqual(loc.string("wallet_add_funds"), "Ajouter des fonds")
        XCTAssertEqual(loc.string("store_buy_button"), "Acheter")
        XCTAssertEqual(loc.string("support_new_ticket"), "Nouveau Ticket")
        XCTAssertEqual(loc.string("afk_btn_open"), "Ouvrir la session AFK")
        
        // Test English
        loc.setLanguage(.english)
        XCTAssertEqual(loc.string("nav_wallet"), "Wallet")
        XCTAssertEqual(loc.string("nav_store"), "Store")
        XCTAssertEqual(loc.string("nav_support"), "Support")
        XCTAssertEqual(loc.string("nav_afk"), "AFK Rewards")
        XCTAssertEqual(loc.string("wallet_add_funds"), "Add Funds")
        XCTAssertEqual(loc.string("store_buy_button"), "Purchase")
        XCTAssertEqual(loc.string("support_new_ticket"), "New Ticket")
        XCTAssertEqual(loc.string("afk_btn_open"), "Open AFK Session")
        
        // Reset to French
        loc.setLanguage(.french)
    }
}
