import XCTest
@testable import Overnode

@MainActor
final class ExternalEditorTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ExternalEditorManager.shared.resetEditor()
        ExternalEditorManager.shared.alwaysOpenInExternalEditor = false
    }
    
    override func tearDown() {
        ExternalEditorManager.shared.resetEditor()
        ExternalEditorManager.shared.alwaysOpenInExternalEditor = false
        super.tearDown()
    }
    
    func testAlwaysOpenInExternalEditorToggle() {
        XCTAssertFalse(ExternalEditorManager.shared.alwaysOpenInExternalEditor)
        
        let expectation = expectation(description: "Notification fired on toggle")
        let token = NotificationCenter.default.addObserver(
            forName: ExternalEditorManager.didChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        
        ExternalEditorManager.shared.alwaysOpenInExternalEditor = true
        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(ExternalEditorManager.shared.alwaysOpenInExternalEditor)
        
        NotificationCenter.default.removeObserver(token)
    }
    
    func testEditorPathAndNamePersistence() {
        XCTAssertNil(ExternalEditorManager.shared.selectedEditorAppPath)
        XCTAssertNil(ExternalEditorManager.shared.selectedEditorAppName)
        
        // Use TextEdit which exists on all macOS systems
        let textEditPath = "/System/Applications/TextEdit.app"
        if FileManager.default.fileExists(atPath: textEditPath) {
            ExternalEditorManager.shared.selectedEditorAppPath = textEditPath
            XCTAssertEqual(ExternalEditorManager.shared.selectedEditorAppPath, textEditPath)
            XCTAssertNotNil(ExternalEditorManager.shared.selectedEditorAppName)
            XCTAssertNotNil(ExternalEditorManager.shared.selectedEditorAppURL)
            
            ExternalEditorManager.shared.resetEditor()
            XCTAssertNil(ExternalEditorManager.shared.selectedEditorAppPath)
            XCTAssertNil(ExternalEditorManager.shared.selectedEditorAppName)
        }
    }
    
    func testLocalizationKeysExist() {
        let frKeys = [
            "files_context_open_external",
            "files_context_choose_editor",
            "files_context_open_internal",
            "settings_external_editor_title",
            "settings_external_editor_always_toggle"
        ]
        
        for key in frKeys {
            let str = LocalizationManager.shared.string(key)
            XCTAssertFalse(str.isEmpty, "Missing key: \(key)")
            XCTAssertNotEqual(str, key, "Key returned itself without localization: \(key)")
        }
    }
    
    func testPurgeAllTemporaryFiles() {
        let tempDir = ExternalEditorManager.shared.temporaryDirectoryURL
            .appendingPathComponent("testServer")
            .appendingPathComponent("testUUID")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let sampleFile = tempDir.appendingPathComponent("test.txt")
        try? "test data".data(using: .utf8)?.write(to: sampleFile)
        XCTAssertTrue(FileManager.default.fileExists(atPath: sampleFile.path))
        
        ExternalEditorManager.shared.purgeAllTemporaryFiles()
        XCTAssertFalse(FileManager.default.fileExists(atPath: sampleFile.path))
    }
    
    func testCleanupStaleTemporaryFiles() {
        let tempDir = ExternalEditorManager.shared.temporaryDirectoryURL
            .appendingPathComponent("testServer")
            .appendingPathComponent("testOldUUID")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let sampleFile = tempDir.appendingPathComponent("old.txt")
        try? "old data".data(using: .utf8)?.write(to: sampleFile)
        XCTAssertTrue(FileManager.default.fileExists(atPath: sampleFile.path))
        
        // With maxAgeSeconds = 0, any file created right now is considered stale
        ExternalEditorManager.shared.cleanupStaleTemporaryFiles(maxAgeSeconds: -1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: sampleFile.path))
    }
}
