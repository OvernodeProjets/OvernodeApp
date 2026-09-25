import XCTest
@testable import Overnode

final class ServerManagementTests: XCTestCase {
    func testServerFileItemFormattedSize() {
        let itemBytes = ServerFileItem(name: "test.txt", size: 512, isFile: true)
        XCTAssertEqual(itemBytes.formattedSize, "512 B")
        
        let itemKB = ServerFileItem(name: "test.txt", size: 2048, isFile: true)
        XCTAssertEqual(itemKB.formattedSize, "2.0 KB")
        
        let itemMB = ServerFileItem(name: "test.jar", size: 15 * 1024 * 1024, isFile: true)
        XCTAssertEqual(itemMB.formattedSize, "15.0 MB")
        
        let itemFolder = ServerFileItem(name: "plugins", size: 4096, isFile: false)
        XCTAssertEqual(itemFolder.formattedSize, "—")
    }
    
    func testServerRenewalStatusParsing() throws {
        let json = """
        {
            "isActive": true,
            "nextRenewalAt": "2026-10-15T12:00:00.000Z",
            "canRenew": true,
            "requiresRenewal": false,
            "isExpired": false,
            "timeRemaining": "23d 4h",
            "renewalCount": 3
        }
        """
        let data = json.data(using: .utf8)!
        let status = try JSONDecoder().decode(ServerRenewalStatus.self, from: data)
        XCTAssertEqual(status.isActive, true)
        XCTAssertEqual(status.canRenew, true)
        XCTAssertEqual(status.renewalCount, 3)
        XCTAssertEqual(status.timeRemaining, "23d 4h")
    }
    
    func testServerPowerSignals() {
        XCTAssertEqual(ServerPowerSignal.start.rawValue, "start")
        XCTAssertEqual(ServerPowerSignal.stop.rawValue, "stop")
        XCTAssertEqual(ServerPowerSignal.restart.rawValue, "restart")
        XCTAssertEqual(ServerPowerSignal.kill.rawValue, "kill")
        
        XCTAssertFalse(ServerPowerSignal.start.iconName.isEmpty)
        XCTAssertFalse(ServerPowerSignal.stop.iconName.isEmpty)
        XCTAssertFalse(ServerPowerSignal.restart.iconName.isEmpty)
        XCTAssertFalse(ServerPowerSignal.kill.iconName.isEmpty)
    }
    
    func testSubdomainFQDN() {
        let subWithDomain = ServerSubdomain(id: "1", serverId: "srv1", subdomain: "play", domainName: "overnode.fr", createdAt: nil)
        XCTAssertEqual(subWithDomain.fqdn, "play.overnode.fr")
        
        let subWithoutDomain = ServerSubdomain(id: "2", serverId: "srv1", subdomain: "alone", domainName: "", createdAt: nil)
        XCTAssertEqual(subWithoutDomain.fqdn, "alone")
    }
    
    func testSubdomainDecodingFromRealApi() throws {
        let json = """
        [{"id":"cmucvse7v00b0uiuup6skfiig","serverId":"96a07e23","userId":"cmn22v1ek0004nunpaf4csbt1","name":"xxxxxxxxxxxxx","domain":"overnode.fr","zoneId":"80007c8fddf9869fd548aadd33da6109","recordId":"87ad5e692281ac7c081fc4d0308b7712","createdAt":"2026-09-22T16:21:07.196Z"}]
        """
        let list = try JSONDecoder().decode([ServerSubdomain].self, from: json.data(using: .utf8)!)
        XCTAssertEqual(list.count, 1)
        XCTAssertEqual(list[0].subdomain, "xxxxxxxxxxxxx")
        XCTAssertEqual(list[0].domainName, "overnode.fr")
        XCTAssertEqual(list[0].fqdn, "xxxxxxxxxxxxx.overnode.fr")
    }
    
    func testRenewalStatusDecodingFromRealApi() throws {
        let json = """
        {"serverIdentifier":"96a07e23","panelId":4159,"userId":"cmn22v1ek0004nunpaf4csbt1","lastRenewedAt":"2026-09-21T19:29:38.337Z","nextRenewalAt":"2026-09-23T19:29:38.337Z","expiredAt":null,"isActive":true,"renewalCount":0,"createdAt":"2026-09-21T19:29:38.337Z","updatedAt":"2026-09-21T19:29:38.337Z","isUnlimited":false,"requiresRenewal":false,"canRenew":false,"isExpired":false,"timeRemaining":{"totalMs":97566460,"totalSeconds":97566,"days":1,"hours":3,"minutes":6,"seconds":6},"overdue":{"totalMs":0,"totalSeconds":0,"days":0,"hours":0,"minutes":0,"seconds":0},"autoDeleteAt":"2026-09-30T19:29:38.337Z","autoDeleteIn":{"totalMs":702366460,"totalSeconds":702366,"days":8,"hours":3,"minutes":6,"seconds":6},"config":{"enabled":true,"renewalPeriodDays":2,"renewalWindowHours":24,"autoDeleteEnabled":true,"autoDeleteAfterDays":7,"checkIntervalMinutes":5}}
        """
        let status = try JSONDecoder().decode(ServerRenewalStatus.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(status.isActive, true)
        XCTAssertEqual(status.timeRemaining, "1j 3h")
        XCTAssertEqual(status.canRenew, false)
        XCTAssertEqual(status.requiresRenewal, false)
    }
    
    func testLivePteroServerDecodingWithIntNode() throws {
        let json = """
        [{"object":"server","attributes":{"id":4159,"external_id":null,"uuid":"96a07e23-934e-429b-a32e-657df0c8c657","identifier":"96a07e23","name":"ccc","description":"","status":null,"suspended":false,"limits":{"memory":2048,"swap":-1,"disk":3072,"io":500,"cpu":100,"threads":null,"oom_disabled":true},"user":3511,"node":31,"allocation":1370,"nest":1,"egg":3}}]
        """
        let list = try JSONDecoder().decode([PteroServerWrapper].self, from: json.data(using: .utf8)!)
        XCTAssertEqual(list.count, 1)
        let server = list[0].toServerInstance()
        XCTAssertEqual(server.name, "ccc")
        XCTAssertEqual(server.identifier, "96a07e23")
        XCTAssertEqual(server.node, "Node 31")
        XCTAssertEqual(server.memoryLimitMB, 2048)
        XCTAssertEqual(server.diskLimitMB, 3072)
        XCTAssertEqual(server.cpuLimitPercent, 100)
    }
    
    @MainActor
    func testServerDetailViewModelInit() {
        let server = ServerInstance(
            id: 1,
            identifier: "abc12345",
            name: "Minecraft Survival",
            node: "Node-1",
            suspended: false,
            state: "running",
            memoryUsedMB: 1024,
            memoryLimitMB: 4096,
            cpuUsedPercent: 25,
            cpuLimitPercent: 200,
            diskUsedMB: 5000,
            diskLimitMB: 10000
        )
        let vm = ServerDetailViewModel(server: server)
        XCTAssertEqual(vm.selectedTab, .console)
        XCTAssertEqual(vm.packageRamMB, 4096)
        XCTAssertEqual(vm.packageDiskMB, 10000)
        XCTAssertEqual(vm.packageCpuPercent, 200)
        XCTAssertFalse(vm.consoleLines.isEmpty)
    }
    
    @MainActor
    func testRenewalActionResponseDecodingWithError() throws {
        let json = """
        {
            "error": "Renewal not available yet",
            "availableIn": {
                "totalMs": 9377175,
                "totalSeconds": 9377,
                "days": 0,
                "hours": 2,
                "minutes": 36,
                "seconds": 17
            }
        }
        """
        let res = try JSONDecoder().decode(ServerRenewalActionResponse.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(res.error, "Renewal not available yet")
        XCTAssertEqual(res.availableIn, "2h 36min")
    }
    
    @MainActor
    func testServerTranslations() {
        let loc = LocalizationManager.shared
        
        loc.setLanguage(.french)
        XCTAssertEqual(loc.string("power_start"), "Démarrer")
        XCTAssertEqual(loc.string("power_restart"), "Redémarrer")
        XCTAssertEqual(loc.string("server_tab_renewal"), "Renouvellement")
        XCTAssertEqual(loc.string("server_tab_files"), "Fichiers")
        XCTAssertEqual(loc.string("server_tab_subdomains"), "Sous-domaines")
        XCTAssertEqual(loc.string("server_tab_subusers"), "Sous-utilisateurs")
        XCTAssertEqual(loc.string("server_tab_plugins"), "Plugins")
        
        loc.setLanguage(.english)
        XCTAssertEqual(loc.string("power_start"), "Start")
        XCTAssertEqual(loc.string("power_restart"), "Restart")
        XCTAssertEqual(loc.string("server_tab_renewal"), "Renewal")
        XCTAssertEqual(loc.string("server_tab_files"), "Files")
        XCTAssertEqual(loc.string("server_tab_subdomains"), "Subdomains")
        XCTAssertEqual(loc.string("server_tab_subusers"), "Subusers")
        XCTAssertEqual(loc.string("server_tab_plugins"), "Plugins")
    }
    func testInitResponseDecoding() throws {
        let json = """
        {"state":{"authenticated":true,"twoFactorPending":false,"twoFactorEnabled":true,"site_name":"Overnode"},"user":{"id":"cmn22v1ek0004nunpaf4csbt1","username":"pan_dev","email":"morais.torres.matheus@gmail.com","global_name":"pan_dev","pterodactylEmail":"discord_cmn22v1ek0004nunpaf4csbt1@gmail.com"},"coins":17,"admin":true,"permissions":["*"],"roles":[{"id":"superadmin","name":"Super Admin","color":"#ef4444"}],"settings":{"name":"Overnode"},"servers":[{"object":"server","attributes":{"id":4159,"external_id":null,"uuid":"96a07e23-934e-429b-a32e-657df0c8c657","identifier":"96a07e23","name":"ccc","description":"","status":null,"suspended":false,"limits":{"memory":2048,"swap":-1,"disk":3072,"io":500,"cpu":100,"threads":null,"oom_disabled":true}}}]}
        """
        let res = try JSONDecoder().decode(InitResponse.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(res.servers?.count, 1)
    }

    @MainActor
    func testServerDeletionTranslations() {
        let loc = LocalizationManager.shared
        
        loc.setLanguage(.french)
        XCTAssertEqual(loc.string("settings_delete_title"), "Supprimer le serveur")
        XCTAssertEqual(loc.string("settings_delete_button"), "Supprimer le serveur")
        XCTAssertEqual(loc.string("settings_delete_confirm_title"), "Confirmation de Suppression")
        XCTAssertEqual(loc.string("settings_delete_confirm_btn"), "Supprimer définitivement")
        XCTAssertEqual(loc.string("server_delete_button"), "Supprimer le serveur")
        XCTAssertEqual(loc.string("server_deleted_success"), "Le serveur a été supprimé avec succès.")
        
        loc.setLanguage(.english)
        XCTAssertEqual(loc.string("settings_delete_title"), "Delete Server")
        XCTAssertEqual(loc.string("settings_delete_button"), "Delete Server")
        XCTAssertEqual(loc.string("settings_delete_confirm_title"), "Confirm Server Deletion")
        XCTAssertEqual(loc.string("settings_delete_confirm_btn"), "Permanently Delete")
        XCTAssertEqual(loc.string("server_delete_button"), "Delete Server")
        XCTAssertEqual(loc.string("server_deleted_success"), "The server has been deleted successfully.")
    }

    @MainActor
    func testServerDetailViewModelDelete() async {
        setenv("OVERNODE_DEMO", "1", 1)
        let server = ServerInstance(
            id: 99,
            identifier: "del123",
            name: "Server To Delete",
            node: "Node 1",
            suspended: false,
            state: "running",
            memoryUsedMB: 1024,
            memoryLimitMB: 2048,
            cpuUsedPercent: 10,
            cpuLimitPercent: 100,
            diskUsedMB: 2000,
            diskLimitMB: 5000
        )
        let vm = ServerDetailViewModel(server: server)
        XCTAssertFalse(vm.isDeleting)
        let success = await vm.deleteServer()
        XCTAssertTrue(success)
        XCTAssertFalse(vm.isDeleting)
        XCTAssertNil(vm.errorMessage)
    }

    @MainActor
    func testDashboardViewModelOnServerDeleted() {
        let server1 = ServerInstance(
            id: 10,
            identifier: "srv10",
            name: "Server 10",
            node: "Node 1",
            suspended: false,
            state: "running",
            memoryUsedMB: 500,
            memoryLimitMB: 2048,
            cpuUsedPercent: 15,
            cpuLimitPercent: 100,
            diskUsedMB: 1000,
            diskLimitMB: 4096
        )
        let server2 = ServerInstance(
            id: 20,
            identifier: "srv20",
            name: "Server 20",
            node: "Node 1",
            suspended: false,
            state: "offline",
            memoryUsedMB: 0,
            memoryLimitMB: 1024,
            cpuUsedPercent: 0,
            cpuLimitPercent: 50,
            diskUsedMB: 500,
            diskLimitMB: 2048
        )
        
        let initialResources = ResourcesResponse(
            package: "Titanium",
            allowed: ResourceBucket(ram: 8192, disk: 20480, cpu: 400, servers: 5),
            remaining: ResourceBucket(ram: 5120, disk: 14336, cpu: 250, servers: 3),
            current: ResourceBucket(ram: 3072, disk: 6144, cpu: 150, servers: 2),
            limits: ResourceBucket(ram: 8192, disk: 20480, cpu: 400, servers: 5)
        )
        
        let dbVM = DashboardViewModel(initialResources: initialResources)
        dbVM.servers = [server1, server2]
        
        dbVM.onServerDeleted(server1)
        
        XCTAssertEqual(dbVM.servers.count, 1)
        XCTAssertEqual(dbVM.servers.first?.identifier, "srv20")
        
        XCTAssertEqual(dbVM.resources?.current.ram, 1024)
        XCTAssertEqual(dbVM.resources?.current.disk, 2048)
        XCTAssertEqual(dbVM.resources?.current.cpu, 50)
        XCTAssertEqual(dbVM.resources?.current.servers, 1)
        
        XCTAssertEqual(dbVM.resources?.remaining.ram, 7168)
        XCTAssertEqual(dbVM.resources?.remaining.disk, 18432)
        XCTAssertEqual(dbVM.resources?.remaining.cpu, 350)
        XCTAssertEqual(dbVM.resources?.remaining.servers, 4)
    }

    @MainActor
    func testServerDetailViewModelWithInitialTab() {
        let server = ServerInstance(
            id: 1,
            identifier: "tab_test",
            name: "Tab Server",
            memoryLimitMB: 2048,
            cpuLimitPercent: 100,
            diskLimitMB: 4096
        )
        let vmFiles = ServerDetailViewModel(server: server, initialTab: .files)
        XCTAssertEqual(vmFiles.selectedTab, .files)
        
        let vmRenewal = ServerDetailViewModel(server: server, initialTab: .renewal)
        XCTAssertEqual(vmRenewal.selectedTab, .renewal)
    }

    @MainActor
    func testServerDetailViewModelUpdateServerPreservesLiveStats() {
        let initialServer = ServerInstance(
            id: 1,
            identifier: "stats_test",
            name: "Initial Name",
            state: "running",
            memoryUsedMB: 512,
            memoryLimitMB: 1024,
            cpuUsedPercent: 42.5,
            cpuLimitPercent: 100,
            diskUsedMB: 2000,
            diskLimitMB: 4096
        )
        let vm = ServerDetailViewModel(server: initialServer)
        XCTAssertEqual(vm.server.memoryUsedMB, 512)
        XCTAssertEqual(vm.server.cpuUsedPercent, 42.5)
        XCTAssertEqual(vm.server.state, "running")
        
        let updatedServer = ServerInstance(
            id: 1,
            identifier: "stats_test",
            name: "Updated Name",
            state: "offline",
            memoryUsedMB: 0,
            memoryLimitMB: 2048,
            cpuUsedPercent: 0,
            cpuLimitPercent: 200,
            diskUsedMB: 0,
            diskLimitMB: 8192
        )
        vm.updateServer(updatedServer)
        
        XCTAssertEqual(vm.server.name, "Updated Name")
        XCTAssertEqual(vm.server.memoryLimitMB, 2048)
        XCTAssertEqual(vm.server.cpuLimitPercent, 200)
        XCTAssertEqual(vm.server.diskLimitMB, 8192)
        XCTAssertEqual(vm.server.memoryUsedMB, 512)
        XCTAssertEqual(vm.server.cpuUsedPercent, 42.5)
        XCTAssertEqual(vm.server.diskUsedMB, 2000)
        XCTAssertEqual(vm.server.state, "running")
    }

    func testServerRenewalStatusNumericDurationDecoding() throws {
        let json = """
        {
            "isActive": true,
            "nextRenewalAt": "2026-10-15T12:00:00Z",
            "timeRemaining": 172800,
            "availableIn": 3600,
            "canRenew": false
        }
        """
        let data = json.data(using: .utf8)!
        let status = try JSONDecoder().decode(ServerRenewalStatus.self, from: data)
        XCTAssertEqual(status.timeRemaining, "2j 0h")
        XCTAssertEqual(status.availableIn, "1h 0min")
    }

    func testServerRenewalStatusCalculatedFallbacks() {
        let futureDate = ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600 * 48))
        let status = ServerRenewalStatus(
            isActive: true,
            nextRenewalAt: futureDate,
            canRenew: false,
            timeRemaining: nil,
            availableIn: nil
        )
        XCTAssertNotNil(status.calculatedTimeRemaining)
        XCTAssertTrue(status.calculatedTimeRemaining?.contains("j") == true || status.calculatedTimeRemaining?.contains("h") == true)
        XCTAssertNotNil(status.calculatedAvailableIn)
    }

}
