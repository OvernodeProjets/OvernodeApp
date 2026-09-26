import XCTest
import UniformTypeIdentifiers
@testable import Overnode

final class FileDownloadManagerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        FileDownloadManager.shared.purgeAllTemporaryFiles()
    }
    
    override func tearDown() {
        FileDownloadManager.shared.purgeAllTemporaryFiles()
        super.tearDown()
    }
    
    func testCreateDragItemProviderForFile() {
        let fileItem = ServerFileItem(
            name: "server.properties",
            mode: "-rw-r--r--",
            size: 1024,
            isFile: true,
            isSymlink: false,
            isEditable: true,
            mimetype: "text/plain",
            modifiedAt: "2026-09-26T12:00:00Z"
        )
        
        let provider = FileDownloadManager.shared.createDragItemProvider(
            serverId: "srv_test",
            currentDirectory: "/",
            item: fileItem
        )
        
        XCTAssertEqual(provider.suggestedName, "server.properties")
        XCTAssertTrue(provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier))
    }
    
    func testCreateDragItemProviderForFolder() {
        let folderItem = ServerFileItem(
            name: "plugins",
            mode: "drwxr-xr-x",
            size: 4096,
            isFile: false,
            isSymlink: false,
            isEditable: false,
            mimetype: "inode/directory",
            modifiedAt: "2026-09-26T12:00:00Z"
        )
        
        let provider = FileDownloadManager.shared.createDragItemProvider(
            serverId: "srv_test",
            currentDirectory: "/",
            item: folderItem
        )
        
        XCTAssertEqual(provider.suggestedName, "plugins")
        XCTAssertTrue(provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier))
        XCTAssertTrue(provider.hasItemConformingToTypeIdentifier(UTType.folder.identifier))
    }
    
    func testPurgeAllTemporaryFiles() {
        let baseDir = FileDownloadManager.shared.downloadDirectoryURL
            .appendingPathComponent("srv_test")
            .appendingPathComponent("uuid")
        try? FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
        let sample = baseDir.appendingPathComponent("dummy.txt")
        try? "dummy content".data(using: .utf8)?.write(to: sample)
        XCTAssertTrue(FileManager.default.fileExists(atPath: sample.path))
        
        FileDownloadManager.shared.purgeAllTemporaryFiles()
        XCTAssertFalse(FileManager.default.fileExists(atPath: sample.path))
    }
    
    func testCleanupStaleTemporaryFiles() {
        let baseDir = FileDownloadManager.shared.downloadDirectoryURL
            .appendingPathComponent("srv_test")
            .appendingPathComponent("old_uuid")
        try? FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
        let sample = baseDir.appendingPathComponent("stale.txt")
        try? "stale content".data(using: .utf8)?.write(to: sample)
        XCTAssertTrue(FileManager.default.fileExists(atPath: sample.path))
        
        FileDownloadManager.shared.cleanupStaleTemporaryFiles(maxAgeSeconds: -1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: sample.path))
    }
}
