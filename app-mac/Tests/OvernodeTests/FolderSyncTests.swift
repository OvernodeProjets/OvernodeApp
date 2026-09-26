import XCTest
@testable import Overnode

final class FolderSyncTests: XCTestCase {
    private var tempDir: URL!
    
    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("OvernodeSyncTests_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        if let dir = tempDir {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }
    
    func testFolderSyncScannerIgnoresSystemArtifacts() throws {
        // Create normal file
        let regularFile = tempDir.appendingPathComponent("config.yml")
        try "port: 25565".write(to: regularFile, atomically: true, encoding: .utf8)
        
        // Create ignored files
        let dsStore = tempDir.appendingPathComponent(".DS_Store")
        try "junk".write(to: dsStore, atomically: true, encoding: .utf8)
        
        let tmpFile = tempDir.appendingPathComponent("editor.tmp")
        try "temp".write(to: tmpFile, atomically: true, encoding: .utf8)
        
        let records = FolderSyncScanner.scan(rootURL: tempDir)
        XCTAssertNotNil(records["config.yml"])
        XCTAssertNil(records[".DS_Store"])
        XCTAssertNil(records["editor.tmp"])
    }
    
    func testFolderSyncScannerDiffsCreationsModificationsAndDeletions() throws {
        let fileA = tempDir.appendingPathComponent("fileA.txt")
        try "initial A".write(to: fileA, atomically: true, encoding: .utf8)
        
        let subDir = tempDir.appendingPathComponent("sub")
        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        let fileB = subDir.appendingPathComponent("fileB.txt")
        try "initial B".write(to: fileB, atomically: true, encoding: .utf8)
        
        let snap1 = FolderSyncScanner.scan(rootURL: tempDir)
        XCTAssertEqual(snap1.count, 3) // sub (dir), fileA.txt, sub/fileB.txt
        
        // 1. Modify fileA
        sleep(1) // ensure modDate advances
        try "modified A with more bytes".write(to: fileA, atomically: true, encoding: .utf8)
        
        // 2. Add fileC
        let fileC = tempDir.appendingPathComponent("fileC.json")
        try "{}".write(to: fileC, atomically: true, encoding: .utf8)
        
        // 3. Delete fileB
        try FileManager.default.removeItem(at: fileB)
        
        let snap2 = FolderSyncScanner.scan(rootURL: tempDir)
        let diff = FolderSyncScanner.diff(oldSnapshot: snap1, newSnapshot: snap2)
        
        XCTAssertTrue(diff.hasChanges)
        XCTAssertTrue(diff.addedOrModifiedFiles.contains(where: { $0.relativePath == "fileA.txt" }))
        XCTAssertTrue(diff.addedOrModifiedFiles.contains(where: { $0.relativePath == "fileC.json" }))
        XCTAssertTrue(diff.deletedPaths.contains("sub/fileB.txt"))
    }
    
    func testFolderSyncManagerRegistrationAndUnregistration() async throws {
        let manager = FolderSyncManager.shared
        let serverId = "test-server-123"
        let remotePath = "/plugins"
        let localFolder = tempDir.appendingPathComponent("LocalPlugins")
        
        let config = try await manager.registerSyncedFolder(
            serverId: serverId,
            remotePath: remotePath,
            localURL: localFolder,
            initialPull: false
        )
        
        XCTAssertEqual(config.serverId, serverId)
        XCTAssertEqual(config.remotePath, "/plugins")
        XCTAssertTrue(manager.isFolderSynced(serverId: serverId, remotePath: "/plugins"))
        XCTAssertTrue(manager.isFolderSynced(serverId: serverId, remotePath: "plugins")) // with/without leading slash
        
        let found = manager.configFor(serverId: serverId, remotePath: "/plugins")
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, config.id)
        
        // Stop sync
        manager.stopSync(configId: config.id)
        XCTAssertFalse(manager.isFolderSynced(serverId: serverId, remotePath: "/plugins"))
    }
    
    func testFolderWatcherLifecycle() throws {
        let exp = expectation(description: "Watcher created and stopped without errors")
        let watcher = FolderWatcher(path: tempDir.path) { _ in }
        watcher.start()
        watcher.stop()
        exp.fulfill()
        wait(for: [exp], timeout: 2.0)
    }
}
