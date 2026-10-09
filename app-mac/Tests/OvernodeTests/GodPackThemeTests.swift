import XCTest
@testable import Overnode

final class GodPackThemeTests: XCTestCase {
    
    func testAppThemeConfigSerializationAndDeserialization() throws {
        var colors = ThemeColorsConfig()
        colors.accentGoldHex = "#FF5500"
        colors.backgroundHex = "#121212"
        colors.cardBackgroundHex = "#1A1A1A"
        colors.borderHex = "#333333"
        colors.borderSubtleOpacity = 0.15
        
        let config = AppThemeConfig(
            id: "test-theme-01",
            name: "Test Orange",
            author: "Tester",
            version: "1.0.0",
            colors: colors,
            backgroundImageUrl: "https://example.com/bg.png",
            backgroundLocalPath: nil,
            backgroundOpacity: 0.85,
            backgroundBlur: 5.0,
            backgroundOverlayDarkness: 0.4,
            landingTab: "servers",
            sidebarPosition: .right,
            cardCornerRadius: 16.0
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AppThemeConfig.self, from: data)
        
        XCTAssertEqual(decoded.id, "test-theme-01")
        XCTAssertEqual(decoded.name, "Test Orange")
        XCTAssertEqual(decoded.author, "Tester")
        XCTAssertEqual(decoded.colors.accentGoldHex, "#FF5500")
        XCTAssertEqual(decoded.colors.backgroundHex, "#121212")
        XCTAssertEqual(decoded.sidebarPosition, SidebarPosition.right)
        XCTAssertEqual(decoded.landingTab, "servers")
        XCTAssertEqual(decoded.cardCornerRadius, 16.0)
        XCTAssertEqual(decoded.backgroundOpacity, 0.85)
        XCTAssertEqual(decoded.backgroundBlur, 5.0)
        XCTAssertEqual(decoded.backgroundOverlayDarkness, 0.4)
    }
    
    func testPresetThemesIntegrity() {
        let presets = PresetThemes.all
        XCTAssertEqual(presets.count, 9)
        
        let original = PresetThemes.overnodeOriginal
        XCTAssertEqual(original.id, "overnode_original")
        XCTAssertEqual(original.colors.accentGoldHex, "#F59E0B")
        XCTAssertEqual(original.colors.backgroundHex, "#101218")
        XCTAssertEqual(original.sidebarPosition, .left)
        XCTAssertEqual(original.landingTab, "dashboard")
        
        for preset in presets {
            XCTAssertFalse(preset.id.isEmpty)
            XCTAssertFalse(preset.name.isEmpty)
            XCTAssertTrue(preset.colors.accentGoldHex.hasPrefix("#"))
            XCTAssertTrue(preset.colors.backgroundHex.hasPrefix("#"))
        }
    }
    
    func testColorHexHelper() {
        let defaultColor = ColorHexHelper.color(from: "#InvalidHex", defaultColor: .red)
        XCTAssertNotNil(defaultColor)
        
        let validHex = ColorHexHelper.color(from: "#0B0D13", defaultColor: .black)
        XCTAssertNotNil(validHex)
        
        let hexWithAlpha = ColorHexHelper.color(from: "#0B0D13FF", defaultColor: .black)
        XCTAssertNotNil(hexWithAlpha)
    }
    
    func testDynamicThemeColorsBuilder() {
        let originalColors = PresetThemes.overnodeOriginal.colors
        let dynamicColors = ThemeManager.buildColors(from: originalColors)
        
        XCTAssertNotNil(dynamicColors.background)
        XCTAssertNotNil(dynamicColors.cardBackground)
        XCTAssertNotNil(dynamicColors.accentGold)
        XCTAssertNotNil(dynamicColors.goldGradient)
    }
    
    @MainActor
    func testThemeManagerPresetAndModifications() {
        let manager = ThemeManager.shared
        manager.resetToDefault()
        
        XCTAssertEqual(manager.currentConfig.id, "overnode_original")
        XCTAssertEqual(manager.currentConfig.sidebarPosition, .left)
        
        if let cyberpunk = manager.presets.first(where: { $0.id == "cyberpunk_neon" }) {
            manager.applyPreset(cyberpunk)
            XCTAssertEqual(manager.currentConfig.id, "cyberpunk_neon")
            XCTAssertEqual(manager.currentConfig.colors.accentGoldHex, "#00F5D4")
        }
        
        manager.updateSidebarPosition(.right)
        XCTAssertEqual(manager.currentConfig.sidebarPosition, .right)
        
        manager.updateLandingTab("wallet")
        XCTAssertEqual(manager.currentConfig.landingTab, "wallet")
        XCTAssertEqual(manager.resolvedLandingTab, .wallet)
        
        manager.updateCornerRadius(18)
        XCTAssertEqual(manager.currentConfig.cardCornerRadius, 18)
        
        manager.resetToDefault()
        XCTAssertEqual(manager.currentConfig.id, "overnode_original")
        XCTAssertEqual(manager.currentConfig.sidebarPosition, .left)
    }
    
    @MainActor
    func testExportAndImportConfiguration() throws {
        let manager = ThemeManager.shared
        manager.resetToDefault()
        
        manager.updateLandingTab("store")
        manager.updateSidebarPosition(.right)
        manager.updateColors { colors in
            colors.accentGoldHex = "#00FFAA"
        }
        
        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("test_config.overnode.app")
        defer { try? FileManager.default.removeItem(at: tempUrl) }
        
        try manager.exportConfiguration(to: tempUrl)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempUrl.path))
        
        manager.resetToDefault()
        XCTAssertEqual(manager.currentConfig.id, "overnode_original")
        XCTAssertEqual(manager.currentConfig.landingTab, "dashboard")
        
        try manager.importConfiguration(from: tempUrl)
        XCTAssertEqual(manager.currentConfig.landingTab, "store")
        XCTAssertEqual(manager.currentConfig.sidebarPosition, .right)
        XCTAssertEqual(manager.currentConfig.colors.accentGoldHex, "#00FFAA")
        
        manager.resetToDefault()
    }
    
    func testUserDiscordIdDecoding() throws {
        let jsonSnakeCase = """
        {
            "id": 100,
            "username": "vipuser",
            "email": "vip@example.com",
            "discord_id": "123456789012345678"
        }
        """.data(using: .utf8)!
        
        let userSnake = try JSONDecoder().decode(User.self, from: jsonSnakeCase)
        XCTAssertEqual(userSnake.discordId, "123456789012345678")
        
        let jsonCamelCase = """
        {
            "id": 101,
            "username": "vipuser2",
            "email": "vip2@example.com",
            "discordId": "987654321098765432"
        }
        """.data(using: .utf8)!
        
        let userCamel = try JSONDecoder().decode(User.self, from: jsonCamelCase)
        XCTAssertEqual(userCamel.discordId, "987654321098765432")
    }
    
    func testGodPackAccessResponseDecoding() throws {
        let jsonBundle = """
        {
            "hasGodPack": true,
            "hasAutoRenew": false
        }
        """.data(using: .utf8)!
        
        let bundleStatus = try JSONDecoder().decode(BundleStatusResponse.self, from: jsonBundle)
        XCTAssertEqual(bundleStatus.hasGodPack, true)
        XCTAssertEqual(bundleStatus.hasAutoRenew, false)
        
        let jsonUpdater = """
        {
            "discordId": "123456789",
            "hasGodPack": true
        }
        """.data(using: .utf8)!
        
        let updaterStatus = try JSONDecoder().decode(UpdaterGodPackCheckResponse.self, from: jsonUpdater)
        XCTAssertEqual(updaterStatus.hasGodPack, true)
        XCTAssertEqual(updaterStatus.discordId, "123456789")
    }
    
    @MainActor
    func testGodPackActiveTranslations() async {
        let loc = LocalizationManager.shared
        
        loc.setLanguage(.french)
        XCTAssertEqual(loc.string("godpack_title"), "Personnalisation Overnode")
        XCTAssertEqual(loc.string("godpack_badge_active"), "Pack God Actif 👑")
        XCTAssertEqual(loc.string("godpack_tab_presets"), "Thèmes Préconçus")
        XCTAssertEqual(loc.string("godpack_sidebar_left"), "Gauche (Défaut)")
        XCTAssertEqual(loc.string("bundle_god_f4"), "Personnalisation intégrale de l'application (Thèmes & Fond)")
        XCTAssertEqual(SidebarPosition.left.localizedDisplayName(loc: loc), "Gauche (Défaut)")
        
        loc.setLanguage(.english)
        XCTAssertEqual(loc.string("godpack_title"), "Overnode Customization")
        XCTAssertEqual(loc.string("godpack_badge_active"), "God Pack Active 👑")
        XCTAssertEqual(loc.string("godpack_tab_presets"), "Preset Themes")
        XCTAssertEqual(loc.string("godpack_sidebar_left"), "Left (Default)")
        XCTAssertEqual(loc.string("bundle_god_f4"), "Full application customization (Themes & Backgrounds)")
        XCTAssertEqual(SidebarPosition.left.localizedDisplayName(loc: loc), "Left (Default)")
        
        loc.setLanguage(.french)
    }
    
    @MainActor
    func testVIPDiscordStorageAndTranslation() {
        let service = GodPackService.shared
        let loc = LocalizationManager.shared
        
        service.saveDiscordId("966633645144158209")
        XCTAssertEqual(service.savedDiscordId, "966633645144158209")
        XCTAssertEqual(UserDefaults.standard.string(forKey: GodPackService.discordIdStorageKey), "966633645144158209")
        
        service.clearSavedDiscordId()
        XCTAssertNil(service.savedDiscordId)
        XCTAssertNil(UserDefaults.standard.string(forKey: GodPackService.discordIdStorageKey))
        XCTAssertFalse(service.hasGodPack)
        
        loc.setLanguage(.french)
        XCTAssertEqual(loc.string("godpack_vip_section_title"), "Activation VIP Discord (Updater)")
        XCTAssertEqual(loc.string("godpack_vip_modal_title"), "Activation VIP Discord")
        XCTAssertEqual(loc.string("godpack_vip_btn_verify"), "Vérifier & Activer")
        XCTAssertEqual(loc.string("godpack_vip_unlink_btn"), "Dissocier")
        
        loc.setLanguage(.english)
        XCTAssertEqual(loc.string("godpack_vip_section_title"), "Discord VIP Activation (Updater)")
        XCTAssertEqual(loc.string("godpack_vip_modal_title"), "Discord VIP Activation")
        XCTAssertEqual(loc.string("godpack_vip_btn_verify"), "Verify & Activate")
        XCTAssertEqual(loc.string("godpack_vip_unlink_btn"), "Unlink")
        
        loc.setLanguage(.french)
    }
}
