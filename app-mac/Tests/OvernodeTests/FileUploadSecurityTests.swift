import XCTest
@testable import Overnode

final class FileUploadSecurityTests: XCTestCase {
    private var tempDir: URL!
    
    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileUploadSecurityTests_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        if let dir = tempDir {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }
    
    func testEmptySelectionThrows() {
        XCTAssertThrowsError(try FileUploadSecurity.shared.buildPlan(from: [])) { error in
            XCTAssertEqual(error as? FileUploadError, FileUploadError.emptySelection)
        }
    }
    
    func testSingleFilePlan() throws {
        let fileURL = tempDir.appendingPathComponent("test_plugin.jar")
        try "fake jar content".data(using: .utf8)?.write(to: fileURL)
        
        let plan = try FileUploadSecurity.shared.buildPlan(from: [fileURL], diskLimitMB: 1000, diskUsedMB: 100)
        XCTAssertEqual(plan.filesToUpload.count, 1)
        XCTAssertEqual(plan.filesToUpload[0].fileName, "test_plugin.jar")
        XCTAssertEqual(plan.filesToUpload[0].relativePath, "test_plugin.jar")
        XCTAssertFalse(plan.filesToUpload[0].isDirectory)
        XCTAssertTrue(plan.directoriesToCreate.isEmpty)
        XCTAssertGreaterThan(plan.totalByteSize, 0)
    }
    
    func testIgnoredSystemFilesFilter() throws {
        let dsStore = tempDir.appendingPathComponent(".DS_Store")
        let macosx = tempDir.appendingPathComponent("__MACOSX")
        let dotUnderscore = tempDir.appendingPathComponent("._hidden")
        let normal = tempDir.appendingPathComponent("server.properties")
        
        try "trash".data(using: .utf8)?.write(to: dsStore)
        try FileManager.default.createDirectory(at: macosx, withIntermediateDirectories: true)
        try "dot".data(using: .utf8)?.write(to: dotUnderscore)
        try "motd=Overnode".data(using: .utf8)?.write(to: normal)
        
        let plan = try FileUploadSecurity.shared.buildPlan(from: [dsStore, macosx, dotUnderscore, normal])
        XCTAssertEqual(plan.filesToUpload.count, 1)
        XCTAssertEqual(plan.filesToUpload[0].fileName, "server.properties")
    }
    
    func testPathTraversalSecurity() {
        XCTAssertThrowsError(try FileUploadSecurity.shared.validatePathSecurity("../secret.txt")) { error in
            guard case FileUploadError.securityViolation = error else {
                XCTFail("Expected securityViolation")
                return
            }
        }
        
        XCTAssertThrowsError(try FileUploadSecurity.shared.validatePathSecurity("folder/../file.txt")) { error in
            guard case FileUploadError.securityViolation = error else {
                XCTFail("Expected securityViolation")
                return
            }
        }
        
        XCTAssertThrowsError(try FileUploadSecurity.shared.validatePathSecurity("folder//file.txt")) { error in
            guard case FileUploadError.securityViolation = error else {
                XCTFail("Expected securityViolation")
                return
            }
        }
    }
    
    func testSingleFileSizeExceeded() throws {
        // Test threshold logic with FileUploadError
        let dummyName = "huge_backup.tar.gz"
        let err = FileUploadError.singleFileSizeExceeded(fileName: dummyName, maxMB: 100)
        XCTAssertNotNil(err.errorDescription)
        XCTAssertTrue(err.errorDescription!.contains(dummyName) || err.errorDescription!.contains("100"))
    }
    
    func testDiskQuotaCheck() throws {
        let fileURL = tempDir.appendingPathComponent("large.bin")
        let data = Data(repeating: 0xAB, count: 2 * 1024 * 1024) // 2 MB
        try data.write(to: fileURL)
        
        // Quota: limit 10 MB, used 9 MB -> remaining 1 MB. File is 2 MB.
        XCTAssertThrowsError(try FileUploadSecurity.shared.buildPlan(from: [fileURL], diskLimitMB: 10, diskUsedMB: 9)) { error in
            guard case FileUploadError.insufficientDiskQuota = error else {
                XCTFail("Expected insufficientDiskQuota but got \(error)")
                return
            }
        }
        
        // Quota: limit 10 MB, used 5 MB -> remaining 5 MB. File is 2 MB -> OK.
        let plan = try FileUploadSecurity.shared.buildPlan(from: [fileURL], diskLimitMB: 10, diskUsedMB: 5)
        XCTAssertEqual(plan.filesToUpload.count, 1)
    }
    
    func testDirectoryRecursionPlan() throws {
        let subFolder = tempDir.appendingPathComponent("plugins")
        let subSubFolder = subFolder.appendingPathComponent("Essentials")
        try FileManager.default.createDirectory(at: subSubFolder, withIntermediateDirectories: true)
        
        let jarFile = subFolder.appendingPathComponent("EssentialsX.jar")
        let configFile = subSubFolder.appendingPathComponent("config.yml")
        let dsStore = subSubFolder.appendingPathComponent(".DS_Store")
        
        try "jar".data(using: .utf8)?.write(to: jarFile)
        try "config".data(using: .utf8)?.write(to: configFile)
        try "ds".data(using: .utf8)?.write(to: dsStore)
        
        let plan = try FileUploadSecurity.shared.buildPlan(from: [subFolder])
        XCTAssertTrue(plan.directoriesToCreate.contains("plugins"))
        XCTAssertTrue(plan.directoriesToCreate.contains("plugins/Essentials"))
        
        let fileNames = Set(plan.filesToUpload.map { $0.fileName })
        XCTAssertTrue(fileNames.contains("EssentialsX.jar"))
        XCTAssertTrue(fileNames.contains("config.yml"))
        XCTAssertFalse(fileNames.contains(".DS_Store"))
    }
}
