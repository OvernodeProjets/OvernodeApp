import XCTest
@testable import Overnode

final class OvernodeTests: XCTestCase {
    func testLocalizationInitialization() async {
        let loc = await LocalizationManager.shared
        let appNameFr = await loc.string("app_name")
        XCTAssertEqual(appNameFr, "Overnode")
        
        await loc.setLanguage(.english)
        let subtitleEn = await loc.string("app_subtitle")
        XCTAssertEqual(subtitleEn, "Native Cloud Console")
        
        await loc.setLanguage(.french)
        let subtitleFr = await loc.string("app_subtitle")
        XCTAssertEqual(subtitleFr, "Console Cloud Native")
    }
    
    func testResourceCalculations() {
        let res = ResourcesResponse(
            package: "Titanium",
            allowed: ResourceBucket(ram: 8192, disk: 40960, cpu: 200, servers: 4),
            remaining: ResourceBucket(ram: 4096, disk: 20480, cpu: 100, servers: 2),
            current: ResourceBucket(ram: 4096, disk: 20480, cpu: 100, servers: 2),
            limits: ResourceBucket(ram: 8192, disk: 40960, cpu: 200, servers: 4)
        )
        
        XCTAssertEqual(res.ramUsedGB, 4.0)
        XCTAssertEqual(res.ramTotalGB, 8.0)
        XCTAssertEqual(res.ramPercentage, 50.0)
        
        XCTAssertEqual(res.diskUsedGB, 20.0)
        XCTAssertEqual(res.diskTotalGB, 40.0)
        XCTAssertEqual(res.diskPercentage, 50.0)
        
        XCTAssertEqual(res.cpuPercentage, 50.0)
        XCTAssertEqual(res.serversPercentage, 50.0)
    }
    
    func testBase64URLExtension() {
        let sample = "Hello Overnode 2026!"
        let sampleData = sample.data(using: .utf8)!
        let base64url = sampleData.base64URLEncodedString()
        XCTAssertFalse(base64url.contains("+"))
        XCTAssertFalse(base64url.contains("/"))
        XCTAssertFalse(base64url.contains("="))
        
        let restoredData = Data(base64URLEncoded: base64url)
        XCTAssertNotNil(restoredData)
        let restoredString = String(data: restoredData!, encoding: .utf8)
        XCTAssertEqual(restoredString, sample)
    }
}
