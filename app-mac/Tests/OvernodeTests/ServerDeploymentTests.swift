import XCTest
@testable import Overnode

final class ServerDeploymentTests: XCTestCase {
    func testServerEggIcons() {
        let mcEgg = ServerEgg(id: "paper", name: "Paper", category: "minecraft")
        XCTAssertEqual(mcEgg.iconName, "cube.fill")
        
        let botEgg = ServerEgg(id: "nodejs", name: "Node.js", category: "discord")
        XCTAssertEqual(botEgg.iconName, "bubble.left.and.text.bubble.right.fill")
        
        let webEgg = ServerEgg(id: "redis", name: "Redis", category: "web")
        XCTAssertEqual(webEgg.iconName, "globe.americas.fill")
        
        let gameEgg = ServerEgg(id: "csgo", name: "CS:GO", category: "game")
        XCTAssertEqual(gameEgg.iconName, "gamecontroller.fill")
        
        let otherEgg = ServerEgg(id: "other", name: "Custom", category: "custom")
        XCTAssertEqual(otherEgg.iconName, "shippingbox.fill")
    }
    
    func testCreateServerPayloadEncoding() throws {
        let payload = CreateServerPayload(
            name: "Survival-FR",
            egg: "minecraft_paper",
            nodeId: 2,
            ram: 2048,
            disk: 4096,
            cpu: 100
        )
        
        let data = try JSONEncoder().encode(payload)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertEqual(json?["name"] as? String, "Survival-FR")
        XCTAssertEqual(json?["egg"] as? String, "minecraft_paper")
        XCTAssertEqual(json?["nodeId"] as? Int, 2)
        XCTAssertEqual(json?["ram"] as? Int, 2048)
        XCTAssertEqual(json?["disk"] as? Int, 4096)
        XCTAssertEqual(json?["cpu"] as? Int, 100)
    }
    
    @MainActor
    func testCreateServerViewModelValidation() {
        let vm = CreateServerViewModel()
        
        vm.serverName = ""
        XCTAssertFalse(vm.isNameValid)
        
        vm.serverName = "Invalid @ Server !"
        XCTAssertFalse(vm.isNameValid)
        
        vm.serverName = "Valid-Server_01 Production"
        XCTAssertTrue(vm.isNameValid)
        
        let egg = ServerEgg(
            id: "paper",
            name: "Paper",
            category: "minecraft",
            minimum: ResourceRequirement(ram: 1024, disk: 2048, cpu: 50)
        )
        let node = ServerNode(id: 1, name: "Node 1", locationId: "loc1")
        
        vm.selectedEgg = egg
        vm.selectedNode = node
        vm.ramMB = 2048
        vm.cpuPercent = 100
        vm.diskMB = 4096
        
        vm.options = DeployOptionsResponse(
            categories: [],
            eggs: [egg],
            locations: [ServerLocation(id: "loc1", name: "Paris")],
            nodes: [node],
            resources: DeployResourcesInfo(
                current: ResourceBucket(ram: 1024, disk: 2048, cpu: 50, servers: 1),
                allowed: ResourceBucket(ram: 8192, disk: 20480, cpu: 200, servers: 3),
                remaining: ResourceBucket(ram: 4096, disk: 10240, cpu: 150, servers: 2)
            )
        )
        
        XCTAssertTrue(vm.canDeploy)
        
        // Exceed remaining RAM
        vm.ramMB = 8192
        XCTAssertFalse(vm.canDeploy)
        
        // Restore RAM, exceed remaining CPU
        vm.ramMB = 2048
        vm.cpuPercent = 300
        XCTAssertFalse(vm.canDeploy)
        
        // Restore CPU, exceed remaining Disk
        vm.cpuPercent = 100
        vm.diskMB = 50000
        XCTAssertFalse(vm.canDeploy)
    }
    
    @MainActor
    func testServerCreationTranslations() {
        let loc = LocalizationManager.shared
        loc.setLanguage(.english)
        XCTAssertEqual(loc.string("create_server_button"), "Create Server")
        XCTAssertEqual(loc.string("create_server_title"), "Create a Server")
        XCTAssertFalse(loc.string("create_server_resources_title").isEmpty)
        
        loc.setLanguage(.french)
        XCTAssertEqual(loc.string("create_server_button"), "Créer un serveur")
        XCTAssertEqual(loc.string("create_server_title"), "Créer un serveur")
        XCTAssertFalse(loc.string("create_server_resources_title").isEmpty)
    }
}

