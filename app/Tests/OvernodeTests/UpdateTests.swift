import XCTest
@testable import Overnode

final class UpdateTests: XCTestCase {
    func testUpdateCheckResponseDecoding() throws {
        let json = #"""
        {
            "updateAvailable": true,
            "clientVersion": "1.0.0",
            "latestVersion": "1.1.0",
            "downloadUrl": "https://github.com/overnode-network/OvernodeApp/releases/download/v1.1.0/Overnode-v1.1.0-macOS-arm64.zip",
            "releaseNotes": "• Nouveautés de version 1.1.0\n• Améliorations Apple Silicon",
            "mandatory": false,
            "sha256": "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8",
            "publishedAt": "2026-09-23T10:00:00.000Z"
        }
        """#.data(using: .utf8)!
        
        let resp = try JSONDecoder().decode(UpdateCheckResponse.self, from: json)
        XCTAssertTrue(resp.updateAvailable)
        XCTAssertEqual(resp.clientVersion, "1.0.0")
        XCTAssertEqual(resp.latestVersion, "1.1.0")
        XCTAssertEqual(resp.downloadUrl, "https://github.com/overnode-network/OvernodeApp/releases/download/v1.1.0/Overnode-v1.1.0-macOS-arm64.zip")
        XCTAssertFalse(resp.mandatory)
        XCTAssertEqual(resp.sha256, "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8")
        XCTAssertEqual(resp.publishedAt, "2026-09-23T10:00:00.000Z")
    }
    
    func testUpdateStateEquality() {
        let s1 = UpdateState.idle
        let s2 = UpdateState.checking
        let s3 = UpdateState.upToDate(currentVersion: "1.0.0")
        let s4 = UpdateState.upToDate(currentVersion: "1.0.0")
        let s5 = UpdateState.downloading(progress: 0.5)
        
        XCTAssertNotEqual(s1, s2)
        XCTAssertEqual(s3, s4)
        XCTAssertNotEqual(s3, s5)
    }
    
    func testUpdateServiceInitialization() {
        let service = UpdateService.shared
        XCTAssertFalse(service.currentAppVersion.isEmpty)
        XCTAssertEqual(UpdateService.defaultUpdaterURLString, "https://zBvoGzjDABxGuLuKux59LtECbKIpNPcp.overnode.fr")
        XCTAssertEqual(service.updaterBaseURL.absoluteString, "https://zBvoGzjDABxGuLuKux59LtECbKIpNPcp.overnode.fr")
    }
    
    @MainActor
    func testUpdateViewModelState() async {
        let vm = UpdateViewModel()
        XCTAssertEqual(vm.state, .idle)
        XCTAssertFalse(vm.hasUpdateAvailable)
        XCTAssertNil(vm.availableUpdate)
        XCTAssertFalse(vm.isDownloading)
        
        let dummy = UpdateCheckResponse(
            updateAvailable: true,
            clientVersion: "1.0.0",
            latestVersion: "1.2.0",
            downloadUrl: "https://example.com/update.zip",
            releaseNotes: "Test release notes",
            mandatory: false
        )
        
        vm.state = .available(dummy)
        XCTAssertTrue(vm.hasUpdateAvailable)
        XCTAssertEqual(vm.availableUpdate?.latestVersion, "1.2.0")
        
        vm.showModal = true
        XCTAssertTrue(vm.showModal)
        vm.dismiss()
        XCTAssertFalse(vm.showModal)
    }
    
    func testUpdateTranslations() async {
        let loc = await LocalizationManager.shared
        await loc.setLanguage(.french)
        let badgeFr = await loc.string("update_badge")
        let titleFr = await loc.string("update_title")
        XCTAssertEqual(badgeFr, "Mise à jour disponible")
        XCTAssertEqual(titleFr, "Nouvelle version d'Overnode")
        
        await loc.setLanguage(.english)
        let badgeEn = await loc.string("update_badge")
        let titleEn = await loc.string("update_title")
        XCTAssertEqual(badgeEn, "Update available")
        XCTAssertEqual(titleEn, "New version of Overnode")
        
        // Reset to French
        await loc.setLanguage(.french)
    }
}

