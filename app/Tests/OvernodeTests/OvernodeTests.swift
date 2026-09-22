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
    
    func testServerInstanceDecodingWithIntegerNode() throws {
        // Pterodactyl returns node as an integer (e.g. 1)
        let json = """
        [
            {
                "id": 42,
                "identifier": "srv-42a",
                "name": "Production VPS",
                "node": 1,
                "suspended": false,
                "state": "running",
                "memoryUsedMB": 1024,
                "memoryLimitMB": 2048,
                "cpuUsedPercent": 25.5,
                "cpuLimitPercent": 100,
                "diskUsedMB": 4096,
                "diskLimitMB": 10240
            }
        ]
        """.data(using: .utf8)!
        
        let servers = try JSONDecoder().decode([ServerInstance].self, from: json)
        XCTAssertEqual(servers.count, 1)
        XCTAssertEqual(servers[0].id, 42)
        XCTAssertEqual(servers[0].identifier, "srv-42a")
        XCTAssertEqual(servers[0].node, "Node 1")
        XCTAssertTrue(servers[0].isOnline)
        XCTAssertEqual(servers[0].memoryUsedMB, 1024)
    }
    
    func testInitResponseDecodingWithObjectRolesAndStringUserId() throws {
        // Real backend returns cuid userId and objects in roles array
        let json = """
        {
            "user": {
                "id": 1,
                "username": "Matheus",
                "email": "matheus@overnode.fr",
                "global_name": "Matheus"
            },
            "coins": 250,
            "admin": true,
            "roles": [
                { "id": "superadmin", "name": "Super Admin" },
                { "id": "vip", "name": "VIP Member" }
            ],
            "servers": [
                {
                    "attributes": {
                        "id": 99,
                        "identifier": "node-99",
                        "name": "Game Server",
                        "node": 2,
                        "suspended": false,
                        "limits": {
                            "memory": 4096,
                            "cpu": 200,
                            "disk": 20480
                        }
                    }
                }
            ]
        }
        """.data(using: .utf8)!
        
        let initResp = try JSONDecoder().decode(InitResponse.self, from: json)
        XCTAssertNotNil(initResp.user)
        XCTAssertEqual(initResp.coins, 250)
        XCTAssertEqual(initResp.roles?.compactMap { $0.name }, ["Super Admin", "VIP Member"])
        XCTAssertEqual(initResp.servers?.count, 1)
        XCTAssertEqual(initResp.servers?[0].attributes.node, "Node 2")
    }
}
