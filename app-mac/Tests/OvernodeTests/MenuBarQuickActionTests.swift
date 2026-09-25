import XCTest
@testable import Overnode

final class MenuBarQuickActionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "overnode_quick_action_server_id")
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "overnode_quick_action_server_id")
        super.tearDown()
    }
    
    func testQuickActionServerStorageSetAndGet() {
        let storage = QuickActionServerStorage.shared
        XCTAssertNil(storage.getSelectedServerIdentifier())
        
        storage.setSelectedServerIdentifier("test-server-123")
        XCTAssertEqual(storage.getSelectedServerIdentifier(), "test-server-123")
        
        storage.setSelectedServerIdentifier(nil)
        XCTAssertNil(storage.getSelectedServerIdentifier())
        
        storage.setSelectedServerIdentifier("   ")
        XCTAssertNil(storage.getSelectedServerIdentifier())
    }
    
    func testQuickActionNotificationFired() {
        let expectation = expectation(description: "Notification should fire")
        let observer = NotificationCenter.default.addObserver(
            forName: QuickActionServerStorage.didChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        
        QuickActionServerStorage.shared.setSelectedServerIdentifier("server-xyz")
        wait(for: [expectation], timeout: 2.0)
       NotificationCenter.default.removeObserver(observer)
   }
   
    @MainActor func testQuickActionTranslationsExist() {
        let loc = LocalizationManager.shared
        loc.setLanguage(.french)
        XCTAssertFalse(loc.string("settings_quickaction_title").isEmpty)
        XCTAssertFalse(loc.string("menubar_action_start").isEmpty)
        XCTAssertFalse(loc.string("menubar_action_restart").isEmpty)
        XCTAssertFalse(loc.string("menubar_action_kill").isEmpty)
        XCTAssertFalse(loc.string("menubar_open_app").isEmpty)
        XCTAssertFalse(loc.string("menubar_quit").isEmpty)
        
        loc.setLanguage(.english)
        XCTAssertFalse(loc.string("settings_quickaction_title").isEmpty)
        XCTAssertFalse(loc.string("menubar_action_start").isEmpty)
        XCTAssertFalse(loc.string("menubar_action_restart").isEmpty)
        XCTAssertFalse(loc.string("menubar_action_kill").isEmpty)
        XCTAssertFalse(loc.string("menubar_open_app").isEmpty)
        XCTAssertFalse(loc.string("menubar_quit").isEmpty)
    }
    
    @MainActor
    func testMenuBarManagerRebuildWithoutCrashing() {
        let manager = MenuBarManager.shared
        manager.setup()
        
        let testServers = [
            ServerInstance(
                id: 1,
                identifier: "srv-001",
                name: "VPS Node 1",
                node: "FR-1",
                suspended: false,
                state: "running",
                memoryUsedMB: 1024,
                memoryLimitMB: 4096,
                cpuUsedPercent: 25.0,
                cpuLimitPercent: 100,
                diskUsedMB: 2048,
                diskLimitMB: 10240
            ),
            ServerInstance(
                id: 2,
                identifier: "srv-002",
                name: "Survival MC",
                node: "FR-2",
                suspended: false,
                state: "offline",
                memoryUsedMB: 0,
                memoryLimitMB: 2048,
                cpuUsedPercent: 0,
                cpuLimitPercent: 100,
                diskUsedMB: 500,
                diskLimitMB: 5120
            )
        ]
        
        manager.updateServers(testServers)
        QuickActionServerStorage.shared.setSelectedServerIdentifier("srv-001")
        manager.rebuildMenu()
        
        QuickActionServerStorage.shared.setSelectedServerIdentifier("srv-002")
        manager.rebuildMenu()
        
        QuickActionServerStorage.shared.setSelectedServerIdentifier(nil)
        manager.rebuildMenu()
    }
}
