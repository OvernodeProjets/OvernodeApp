import XCTest
import SwiftUI
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
        XCTAssertEqual(loc.string("create_server_location_status_online"), "En ligne")
        XCTAssertEqual(loc.string("create_server_preset_min"), "Min")
        XCTAssertEqual(loc.string("create_server_preset_max"), "Max")
    }
    
    @MainActor
    func testLocationHelperFormatting() {
        let frLoc = ServerLocation(id: "1", name: "fr")
        let frInfo = LocationHelper.format(location: frLoc)
        XCTAssertEqual(frInfo.flag, "🇫🇷")
        XCTAssertEqual(frInfo.countryName, "France")
        
        let usLoc = ServerLocation(id: "2", name: "us")
        let usInfo = LocationHelper.format(location: usLoc)
        XCTAssertEqual(usInfo.flag, "🇺🇸")
        
        let deLoc = ServerLocation(id: "3", name: "de")
        let deInfo = LocationHelper.format(location: deLoc)
        XCTAssertEqual(deInfo.flag, "🇩🇪")
        
        let customLoc = ServerLocation(id: "99", name: "Singapore")
        let customInfo = LocationHelper.format(location: customLoc)
        XCTAssertEqual(customInfo.flag, "🌐")
        XCTAssertEqual(customInfo.countryName, "Singapore")
    }
    
    @MainActor
    func testLocationHelperNodeFormattingAndMatching() {
        let nodeMrs = ServerNode(id: 10, name: "fr.mrs.1", locationId: "1")
        let nodeInfo = LocationHelper.format(node: nodeMrs)
        XCTAssertEqual(nodeInfo.displayName, "fr.mrs.1")
        XCTAssertEqual(nodeInfo.city, "Marseille")
        XCTAssertEqual(nodeInfo.tag, "Game Anti-DDoS")
        
        let frLoc = ServerLocation(id: "1", name: "fr")
        let usLoc = ServerLocation(id: "2", name: "us")
        
        XCTAssertTrue(LocationHelper.isMatch(node: nodeMrs, location: frLoc))
        XCTAssertFalse(LocationHelper.isMatch(node: nodeMrs, location: usLoc))
    }
    
    @MainActor
    func testRenderServerCreationSnapshot() async throws {
        setenv("OVERNODE_DEMO", "1", 1)
        defer { unsetenv("OVERNODE_DEMO") }
        let vm = CreateServerViewModel()
        vm.serverName = "Mon Serveur Minecraft"
        
        for _ in 0..<30 {
            if vm.options != nil && !vm.isLoading { break }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        
        let modal = CreateServerModalView(vm: vm, onDismiss: {}, onServerCreated: { _ in })
            .preferredColorScheme(.dark)
            .environment(\.locale, Locale(identifier: "fr"))
        
        let hostingView = NSHostingView(rootView: modal)
        hostingView.frame = NSRect(x: 0, y: 0, width: 820, height: 740)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 740),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.layoutIfNeeded()
        try? await Task.sleep(nanoseconds: 300_000_000)
        window.displayIfNeeded()
        
        if let bitmap = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) {
            hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)
            if let pngData = bitmap.representation(using: .png, properties: [:]) {
                let ciPath = FileManager.default.temporaryDirectory.appendingPathComponent("redesigned_server_creation.png").path
                try? pngData.write(to: URL(fileURLWithPath: ciPath))
                let brainPath = "/Users/matheus/.gemini/antigravity/brain/5822f35c-3737-4cb4-bbb9-0e6ac15ac67b/redesigned_server_creation.png"
                if FileManager.default.fileExists(atPath: "/Users/matheus/.gemini/antigravity/brain/5822f35c-3737-4cb4-bbb9-0e6ac15ac67b") {
                    try? pngData.write(to: URL(fileURLWithPath: brainPath))
                }
            }
        }
        
        let resourceView = VStack(alignment: .leading, spacing: 16) {
            CreateServerResourceSectionView(vm: vm)
        }
        .padding(24)
        .frame(width: 820)
        .background(OvernodeTheme.background)
        .preferredColorScheme(.dark)
        
        let resHosting = NSHostingView(rootView: resourceView)
        resHosting.frame = NSRect(x: 0, y: 0, width: 820, height: 360)
        let resWin = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 820, height: 360), styleMask: [.borderless], backing: .buffered, defer: false)
        resWin.contentView = resHosting
        resWin.layoutIfNeeded()
        try? await Task.sleep(nanoseconds: 200_000_000)
        resWin.displayIfNeeded()
        
        if let resBitmap = resHosting.bitmapImageRepForCachingDisplay(in: resHosting.bounds) {
            resHosting.cacheDisplay(in: resHosting.bounds, to: resBitmap)
            if let resPng = resBitmap.representation(using: .png, properties: [:]) {
                let ciPath = FileManager.default.temporaryDirectory.appendingPathComponent("redesigned_server_resources.png").path
                try? resPng.write(to: URL(fileURLWithPath: ciPath))
                let brainPath = "/Users/matheus/.gemini/antigravity/brain/5822f35c-3737-4cb4-bbb9-0e6ac15ac67b/redesigned_server_resources.png"
                if FileManager.default.fileExists(atPath: "/Users/matheus/.gemini/antigravity/brain/5822f35c-3737-4cb4-bbb9-0e6ac15ac67b") {
                    try? resPng.write(to: URL(fileURLWithPath: brainPath))
                }
            }
        }
    }
}

