import SwiftUI
import AppKit
import Combine

public struct DynamicThemeColors: Sendable {
    public let background: Color
    public let cardBackground: Color
    public let secondaryCardBackground: Color
    public let border: Color
    public let borderSubtle: Color
    public let textPrimary: Color
    public let textSecondary: Color
    public let textMuted: Color
    public let accentGold: Color
    public let accentCyan: Color
    public let accentBlue: Color
    public let accentDanger: Color
    public let accentWarning: Color
    public let accentSuccess: Color
    public let accentDiscord: Color
    public let goldGradient: LinearGradient
    public let cardGradient: LinearGradient
}

public final class ThemeColorsStorage: @unchecked Sendable {
    public static let shared = ThemeColorsStorage()
    private let lock = NSLock()
    private var _colors: DynamicThemeColors
    private var _config: AppThemeConfig
    private var _hasCustomBackground: Bool
    
    private init() {
        let initialConfig = ThemeManager.loadStoredConfig() ?? PresetThemes.overnodeOriginal
        self._config = initialConfig
        self._colors = ThemeManager.buildColors(from: initialConfig.colors)
        self._hasCustomBackground = (initialConfig.backgroundImageUrl != nil || initialConfig.backgroundLocalPath != nil) && initialConfig.backgroundOpacity > 0.01
    }
    
    public var hasActiveCustomBackground: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _hasCustomBackground
    }
    
    public var currentColors: DynamicThemeColors {
        lock.lock()
        defer { lock.unlock() }
        return _colors
    }
    
    public var currentConfig: AppThemeConfig {
        lock.lock()
        defer { lock.unlock() }
        return _config
    }
    
    public func update(config: AppThemeConfig, colors: DynamicThemeColors, hasCustomBackground: Bool? = nil) {
        lock.lock()
        self._config = config
        self._colors = colors
        if let hasCustom = hasCustomBackground {
            self._hasCustomBackground = hasCustom
        } else {
            self._hasCustomBackground = (config.backgroundImageUrl != nil || config.backgroundLocalPath != nil) && config.backgroundOpacity > 0.01
        }
        lock.unlock()
    }
}

@MainActor
public final class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()
    
    nonisolated private static let userDefaultsKey = "overnode_theme_configuration_v1"
    
    nonisolated private static var cacheDirectory: URL {
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("fr.overnode.OvernodeApp", isDirectory: true)
            .appendingPathComponent("ThemeBackgrounds", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    
    nonisolated private static func cacheFileURL(for key: String) -> URL {
        let safeName = key.data(using: .utf8)?.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .prefix(64) ?? "bg_cache"
        return cacheDirectory.appendingPathComponent(String(safeName) + ".dat")
    }
    
    @Published public var currentConfig: AppThemeConfig {
        didSet {
            saveConfig()
            updateComputedColors()
            loadBackgroundImageIfNeeded()
        }
    }
    
    @Published public private(set) var currentColors: DynamicThemeColors
    @Published public var backgroundNSImage: NSImage? = nil {
        didSet {
            ThemeColorsStorage.shared.update(
                config: currentConfig,
                colors: currentColors,
                hasCustomBackground: hasActiveCustomBackground
            )
        }
    }
    @Published public var isDownloadingBackground: Bool = false
    @Published public var backgroundLoadError: String? = nil
    
    public var presets: [AppThemeConfig] {
        PresetThemes.all
    }
    
    public var resolvedLandingTab: NavigationTab {
        switch currentConfig.landingTab {
        case "servers": return .servers
        case "wallet": return .wallet
        case "daily_reward": return .dailyReward
        case "store": return .store
        case "support": return .support
        case "afk": return .afk
        case "settings": return .settings
        default: return .dashboard
        }
    }
    
    private init() {
        var loaded = Self.loadStoredConfig() ?? PresetThemes.overnodeOriginal
        if (loaded.backgroundImageUrl != nil || loaded.backgroundLocalPath != nil) && loaded.backgroundOpacity <= 0.25 {
            loaded.backgroundOpacity = 0.85
            if loaded.backgroundOverlayDarkness >= 0.65 {
                loaded.backgroundOverlayDarkness = 0.30
            }
        }
        self.currentConfig = loaded
        let colors = Self.buildColors(from: loaded.colors)
        self.currentColors = colors
        ThemeColorsStorage.shared.update(
            config: loaded,
            colors: colors,
            hasCustomBackground: (loaded.backgroundImageUrl != nil || loaded.backgroundLocalPath != nil) && loaded.backgroundOpacity > 0.01
        )
        loadBackgroundImageIfNeeded()
    }
    
    private func updateComputedColors() {
        let colors = Self.buildColors(from: currentConfig.colors)
        self.currentColors = colors
        ThemeColorsStorage.shared.update(
            config: currentConfig,
            colors: colors,
            hasCustomBackground: hasActiveCustomBackground
        )
    }
    
    nonisolated public static func buildColors(from c: ThemeColorsConfig) -> DynamicThemeColors {
        let bg = ColorHexHelper.color(from: c.backgroundHex, defaultColor: Color(red: 0.063, green: 0.071, blue: 0.094))
        let card = ColorHexHelper.color(from: c.cardBackgroundHex, defaultColor: Color(red: 0.094, green: 0.106, blue: 0.133))
        let secCard = ColorHexHelper.color(from: c.secondaryCardBackgroundHex, defaultColor: Color(red: 0.125, green: 0.133, blue: 0.161))
        let brd = ColorHexHelper.color(from: c.borderHex, defaultColor: Color(red: 0.180, green: 0.200, blue: 0.216))
        let brdSubtle = Color.white.opacity(c.borderSubtleOpacity)
        let txtPrim = ColorHexHelper.color(from: c.textPrimaryHex, defaultColor: .white)
        let txtSec = ColorHexHelper.color(from: c.textSecondaryHex, defaultColor: Color(red: 0.584, green: 0.631, blue: 0.678))
        let txtMuted = ColorHexHelper.color(from: c.textMutedHex, defaultColor: Color(red: 0.400, green: 0.440, blue: 0.490))
        let gold = ColorHexHelper.color(from: c.accentGoldHex, defaultColor: Color(red: 0.961, green: 0.620, blue: 0.106))
        let cyan = ColorHexHelper.color(from: c.accentCyanHex, defaultColor: Color(red: 0.024, green: 0.714, blue: 0.831))
        let blue = ColorHexHelper.color(from: c.accentBlueHex, defaultColor: Color(red: 0.350, green: 0.550, blue: 0.950))
        let danger = ColorHexHelper.color(from: c.accentDangerHex, defaultColor: Color(red: 0.937, green: 0.267, blue: 0.267))
        let warning = ColorHexHelper.color(from: c.accentWarningHex, defaultColor: Color(red: 0.961, green: 0.620, blue: 0.106))
        let success = ColorHexHelper.color(from: c.accentSuccessHex, defaultColor: Color(red: 0.133, green: 0.773, blue: 0.365))
        let discord = ColorHexHelper.color(from: c.accentDiscordHex, defaultColor: Color(red: 0.345, green: 0.396, blue: 0.949))
        
        let goldGrad = LinearGradient(
            colors: [gold, gold.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        let cardGrad = LinearGradient(
            colors: [card, secCard],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        return DynamicThemeColors(
            background: bg,
            cardBackground: card,
            secondaryCardBackground: secCard,
            border: brd,
            borderSubtle: brdSubtle,
            textPrimary: txtPrim,
            textSecondary: txtSec,
            textMuted: txtMuted,
            accentGold: gold,
            accentCyan: cyan,
            accentBlue: blue,
            accentDanger: danger,
            accentWarning: warning,
            accentSuccess: success,
            accentDiscord: discord,
            goldGradient: goldGrad,
            cardGradient: cardGrad
        )
    }
    
    // MARK: - Actions
    public func applyPreset(_ preset: AppThemeConfig) {
        var newConfig = preset
        newConfig.backgroundImageUrl = currentConfig.backgroundImageUrl
        newConfig.backgroundLocalPath = currentConfig.backgroundLocalPath
        newConfig.landingTab = currentConfig.landingTab
        newConfig.sidebarPosition = currentConfig.sidebarPosition
        self.currentConfig = newConfig
    }
    
    public func resetToDefault() {
        self.currentConfig = PresetThemes.overnodeOriginal
        self.backgroundNSImage = nil
        ThemeColorsStorage.shared.update(
            config: PresetThemes.overnodeOriginal,
            colors: Self.buildColors(from: PresetThemes.overnodeOriginal.colors),
            hasCustomBackground: false
        )
    }
    
    public func updateColors(_ update: (inout ThemeColorsConfig) -> Void) {
        var copy = currentConfig
        copy.id = "custom"
        copy.name = "Thème Personnalisé"
        update(&copy.colors)
        self.currentConfig = copy
    }
    
    public func updateBackground(
        url: String?,
        localPath: String?,
        opacity: Double? = nil,
        blur: Double? = nil,
        darkness: Double? = nil
    ) {
        var copy = currentConfig
        copy.backgroundImageUrl = url
        copy.backgroundLocalPath = localPath
        // Si l'utilisateur applique une nouvelle image et que l'opacité est trop basse (< 0.4),
        // on l'ajuste par défaut à 0.85 et le masque sombre à 0.30 pour que l'image soit bien visible
        if (url != nil || localPath != nil) && copy.backgroundOpacity < 0.4 {
            copy.backgroundOpacity = 0.85
            if copy.backgroundOverlayDarkness > 0.4 {
                copy.backgroundOverlayDarkness = 0.30
            }
        }
        if let opacity = opacity { copy.backgroundOpacity = opacity }
        if let blur = blur { copy.backgroundBlur = blur }
        if let darkness = darkness { copy.backgroundOverlayDarkness = darkness }
        self.currentConfig = copy
    }
    
    public func updateLandingTab(_ tab: String) {
        var copy = currentConfig
        copy.landingTab = tab
        self.currentConfig = copy
    }
    
    public func updateSidebarPosition(_ pos: SidebarPosition) {
        var copy = currentConfig
        copy.sidebarPosition = pos
        self.currentConfig = copy
    }
    
    public func updateCornerRadius(_ radius: Double) {
        var copy = currentConfig
        copy.cardCornerRadius = radius
        self.currentConfig = copy
    }
    
    // MARK: - Export & Import
    public func exportConfiguration(to destinationURL: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(currentConfig)
        try data.write(to: destinationURL, options: .atomic)
    }
    
    public func importConfiguration(from sourceURL: URL) throws {
        let data = try Data(contentsOf: sourceURL)
        let decoder = JSONDecoder()
        let imported = try decoder.decode(AppThemeConfig.self, from: data)
        self.currentConfig = imported
    }
    
    // MARK: - Persistence
    nonisolated public static func loadStoredConfig() -> AppThemeConfig? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return nil
        }
        return try? JSONDecoder().decode(AppThemeConfig.self, from: data)
    }
    
    private func saveConfig() {
        if let data = try? JSONEncoder().encode(currentConfig) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }
    
    // MARK: - Image Loader
    public func loadBackgroundImageIfNeeded() {
        if let path = currentConfig.backgroundLocalPath, !path.isEmpty {
            if FileManager.default.fileExists(atPath: path), let img = NSImage(contentsOfFile: path) {
                self.backgroundNSImage = img
                self.backgroundLoadError = nil
                ThemeColorsStorage.shared.update(
                    config: currentConfig,
                    colors: currentColors,
                    hasCustomBackground: hasActiveCustomBackground
                )
                return
            }
        }
        
        guard let urlStr = currentConfig.backgroundImageUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
              !urlStr.isEmpty else {
            self.backgroundNSImage = nil
            self.backgroundLoadError = nil
            ThemeColorsStorage.shared.update(
                config: currentConfig,
                colors: currentColors,
                hasCustomBackground: false
            )
            return
        }
        
        // 1. Essayer d'abord de charger depuis le cache disque local (affichage immédiat sans latence réseau)
        let cacheFile = Self.cacheFileURL(for: urlStr)
        if FileManager.default.fileExists(atPath: cacheFile.path),
           let cachedImg = NSImage(contentsOf: cacheFile) {
            self.backgroundNSImage = cachedImg
            self.backgroundLoadError = nil
            ThemeColorsStorage.shared.update(
                config: currentConfig,
                colors: currentColors,
                hasCustomBackground: hasActiveCustomBackground
            )
        }
        
        guard let url = URL(string: urlStr) else {
            self.backgroundLoadError = "URL d'image invalide"
            self.isDownloadingBackground = false
            return
        }
        
        isDownloadingBackground = true
        backgroundLoadError = nil
        
        Task {
            do {
                var request = URLRequest(url: url)
                request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko)", forHTTPHeaderField: "User-Agent")
                request.setValue("image/jpeg,image/png,image/webp,image/*;q=0.8", forHTTPHeaderField: "Accept")
                request.timeoutInterval = 15.0
                
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                    self.backgroundLoadError = "Erreur HTTP \(code)"
                    self.isDownloadingBackground = false
                    return
                }
                
                guard let image = NSImage(data: data) else {
                    self.backgroundLoadError = "Format d'image non supporté"
                    self.isDownloadingBackground = false
                    return
                }
                
                // Mettre en cache disque de façon atomique
                try? data.write(to: cacheFile, options: .atomic)
                
                self.backgroundNSImage = image
                self.backgroundLoadError = nil
                self.isDownloadingBackground = false
                ThemeColorsStorage.shared.update(
                    config: currentConfig,
                    colors: currentColors,
                    hasCustomBackground: hasActiveCustomBackground
                )
            } catch {
                if self.backgroundNSImage == nil {
                    self.backgroundLoadError = error.localizedDescription
                }
                self.isDownloadingBackground = false
            }
        }
    }
    
    public var hasActiveCustomBackground: Bool {
        return backgroundNSImage != nil && currentConfig.backgroundOpacity > 0.01
    }
}
