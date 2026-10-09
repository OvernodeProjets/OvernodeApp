import SwiftUI

public enum SidebarPosition: String, Codable, CaseIterable, Identifiable, Sendable {
    case left = "left"
    case right = "right"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .left: return "Gauche (Défaut)"
        case .right: return "Droite (Inversée)"
        }
    }
    
    @MainActor
    public func localizedDisplayName(loc: LocalizationManager) -> String {
        switch self {
        case .left: return loc.string("godpack_sidebar_left")
        case .right: return loc.string("godpack_sidebar_right")
        }
    }
}

public struct ThemeColorsConfig: Codable, Equatable, Sendable {
    public var backgroundHex: String
    public var cardBackgroundHex: String
    public var secondaryCardBackgroundHex: String
    public var borderHex: String
    public var borderSubtleOpacity: Double
    public var textPrimaryHex: String
    public var textSecondaryHex: String
    public var textMutedHex: String
    public var accentGoldHex: String
    public var accentCyanHex: String
    public var accentBlueHex: String
    public var accentDangerHex: String
    public var accentWarningHex: String
    public var accentSuccessHex: String
    public var accentDiscordHex: String
    
    public init(
        backgroundHex: String = "#101218",
        cardBackgroundHex: String = "#181B22",
        secondaryCardBackgroundHex: String = "#202229",
        borderHex: String = "#2E3337",
        borderSubtleOpacity: Double = 0.08,
        textPrimaryHex: String = "#FFFFFF",
        textSecondaryHex: String = "#95A1AD",
        textMutedHex: String = "#66707D",
        accentGoldHex: String = "#F59E0B",
        accentCyanHex: String = "#06B6D4",
        accentBlueHex: String = "#598CF2",
        accentDangerHex: String = "#EF4444",
        accentWarningHex: String = "#F59E0B",
        accentSuccessHex: String = "#22C55E",
        accentDiscordHex: String = "#5865F2"
    ) {
        self.backgroundHex = backgroundHex
        self.cardBackgroundHex = cardBackgroundHex
        self.secondaryCardBackgroundHex = secondaryCardBackgroundHex
        self.borderHex = borderHex
        self.borderSubtleOpacity = borderSubtleOpacity
        self.textPrimaryHex = textPrimaryHex
        self.textSecondaryHex = textSecondaryHex
        self.textMutedHex = textMutedHex
        self.accentGoldHex = accentGoldHex
        self.accentCyanHex = accentCyanHex
        self.accentBlueHex = accentBlueHex
        self.accentDangerHex = accentDangerHex
        self.accentWarningHex = accentWarningHex
        self.accentSuccessHex = accentSuccessHex
        self.accentDiscordHex = accentDiscordHex
    }
}

public struct AppThemeConfig: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var author: String
    public var version: String
    public var colors: ThemeColorsConfig
    public var backgroundImageUrl: String?
    public var backgroundLocalPath: String?
    public var backgroundOpacity: Double
    public var backgroundBlur: Double
    public var backgroundOverlayDarkness: Double
    public var landingTab: String
    public var sidebarPosition: SidebarPosition
    public var cardCornerRadius: Double
    
    public init(
        id: String = "custom",
        name: String = "Mon Thème Overnode",
        author: String = "Overnode User",
        version: String = "1.0.0",
        colors: ThemeColorsConfig = ThemeColorsConfig(),
        backgroundImageUrl: String? = nil,
        backgroundLocalPath: String? = nil,
        backgroundOpacity: Double = 0.25,
        backgroundBlur: Double = 0.0,
        backgroundOverlayDarkness: Double = 0.65,
        landingTab: String = "dashboard",
        sidebarPosition: SidebarPosition = .left,
        cardCornerRadius: Double = 10.0
    ) {
        self.id = id
        self.name = name
        self.author = author
        self.version = version
        self.colors = colors
        self.backgroundImageUrl = backgroundImageUrl
        self.backgroundLocalPath = backgroundLocalPath
        self.backgroundOpacity = backgroundOpacity
        self.backgroundBlur = backgroundBlur
        self.backgroundOverlayDarkness = backgroundOverlayDarkness
        self.landingTab = landingTab
        self.sidebarPosition = sidebarPosition
        self.cardCornerRadius = cardCornerRadius
    }
}

// MARK: - Hex Color Helper
public enum ColorHexHelper {
    public static func color(from hex: String, defaultColor: Color = .white) -> Color {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: cleanHex).scanHexInt64(&int) else {
            return defaultColor
        }
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return defaultColor
        }
        return Color(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }
    
    public static func hexString(from color: Color) -> String {
        #if canImport(AppKit)
        let nsColor = NSColor(color)
        guard let rgb = nsColor.usingColorSpace(.deviceRGB) else {
            return "#FFFFFF"
        }
        let r = Int(round(rgb.redComponent * 255))
        let g = Int(round(rgb.greenComponent * 255))
        let b = Int(round(rgb.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
        #else
        return "#FFFFFF"
        #endif
    }
}

// MARK: - Thèmes Préconçus (Créations Officielles & Communauté)
public enum PresetThemes {
    public static let overnodeOriginal = AppThemeConfig(
        id: "overnode_original",
        name: "Overnode Original",
        author: "Overnode Official",
        version: "1.0",
        colors: ThemeColorsConfig(
            backgroundHex: "#101218",
            cardBackgroundHex: "#181B22",
            secondaryCardBackgroundHex: "#202229",
            borderHex: "#2E3337",
            borderSubtleOpacity: 0.08,
            textPrimaryHex: "#FFFFFF",
            textSecondaryHex: "#95A1AD",
            textMutedHex: "#66707D",
            accentGoldHex: "#F59E0B",
            accentCyanHex: "#06B6D4"
        ),
        landingTab: "dashboard",
        sidebarPosition: .left,
        cardCornerRadius: 10.0
    )
    
    public static let cyberpunkNeon = AppThemeConfig(
        id: "cyberpunk_neon",
        name: "Cyberpunk Neon",
        author: "Overnode Community",
        version: "1.0",
        colors: ThemeColorsConfig(
            backgroundHex: "#0D0F18",
            cardBackgroundHex: "#141724",
            secondaryCardBackgroundHex: "#1B2032",
            borderHex: "#2A3250",
            borderSubtleOpacity: 0.15,
            textPrimaryHex: "#FFFFFF",
            textSecondaryHex: "#9AA6BF",
            textMutedHex: "#5E6C87",
            accentGoldHex: "#00F5D4",
            accentCyanHex: "#BD00FF"
        ),
        landingTab: "dashboard",
        sidebarPosition: .left,
        cardCornerRadius: 12.0
    )
    
    public static let midnightOLED = AppThemeConfig(
        id: "midnight_oled",
        name: "Midnight OLED",
        author: "Overnode Official",
        version: "1.0",
        colors: ThemeColorsConfig(
            backgroundHex: "#000000",
            cardBackgroundHex: "#0C0D11",
            secondaryCardBackgroundHex: "#14161D",
            borderHex: "#20242D",
            borderSubtleOpacity: 0.10,
            textPrimaryHex: "#F8FAFC",
            textSecondaryHex: "#94A3B8",
            textMutedHex: "#475569",
            accentGoldHex: "#E5B842",
            accentCyanHex: "#38BDF8"
        ),
        landingTab: "dashboard",
        sidebarPosition: .left,
        cardCornerRadius: 8.0
    )
    
    public static let emeraldMatrix = AppThemeConfig(
        id: "emerald_matrix",
        name: "Emerald Matrix",
        author: "Overnode Community",
        version: "1.0",
        colors: ThemeColorsConfig(
            backgroundHex: "#06120D",
            cardBackgroundHex: "#0C1E17",
            secondaryCardBackgroundHex: "#132B21",
            borderHex: "#1D4032",
            borderSubtleOpacity: 0.12,
            textPrimaryHex: "#E6F4EA",
            textSecondaryHex: "#8CB89F",
            textMutedHex: "#4E735E",
            accentGoldHex: "#00FF88",
            accentCyanHex: "#00E5FF"
        ),
        landingTab: "dashboard",
        sidebarPosition: .left,
        cardCornerRadius: 10.0
    )
    
    public static let crimsonVelvet = AppThemeConfig(
        id: "crimson_velvet",
        name: "Crimson Velvet",
        author: "Overnode Community",
        version: "1.0",
        colors: ThemeColorsConfig(
            backgroundHex: "#140508",
            cardBackgroundHex: "#1E0C11",
            secondaryCardBackgroundHex: "#2B1219",
            borderHex: "#3E1C24",
            borderSubtleOpacity: 0.14,
            textPrimaryHex: "#FFE4E9",
            textSecondaryHex: "#C98B99",
            textMutedHex: "#7A4955",
            accentGoldHex: "#FF3366",
            accentCyanHex: "#FF7597"
        ),
        landingTab: "dashboard",
        sidebarPosition: .left,
        cardCornerRadius: 10.0
    )
    
    public static let sapphireAbyss = AppThemeConfig(
        id: "sapphire_abyss",
        name: "Sapphire Abyss",
        author: "Overnode Official",
        version: "1.0",
        colors: ThemeColorsConfig(
            backgroundHex: "#080E1E",
            cardBackgroundHex: "#0E172E",
            secondaryCardBackgroundHex: "#142040",
            borderHex: "#1F315D",
            borderSubtleOpacity: 0.12,
            textPrimaryHex: "#E2F1FF",
            textSecondaryHex: "#88A8D8",
            textMutedHex: "#4A6694",
            accentGoldHex: "#00D2FF",
            accentCyanHex: "#3A86FF"
        ),
        landingTab: "dashboard",
        sidebarPosition: .left,
        cardCornerRadius: 10.0
    )
    
    public static let nordFrost = AppThemeConfig(
        id: "nord_frost",
        name: "Nord Frost",
        author: "Overnode Community",
        version: "1.0",
        colors: ThemeColorsConfig(
            backgroundHex: "#242933",
            cardBackgroundHex: "#2E3440",
            secondaryCardBackgroundHex: "#3B4252",
            borderHex: "#4C566A",
            borderSubtleOpacity: 0.12,
            textPrimaryHex: "#ECEFF4",
            textSecondaryHex: "#D8DEE9",
            textMutedHex: "#7B88A1",
            accentGoldHex: "#88C0D0",
            accentCyanHex: "#81A1C1"
        ),
        landingTab: "dashboard",
        sidebarPosition: .left,
        cardCornerRadius: 10.0
    )
    
    public static let amethystDream = AppThemeConfig(
        id: "amethyst_dream",
        name: "Amethyst Dream",
        author: "Overnode Community",
        version: "1.0",
        colors: ThemeColorsConfig(
            backgroundHex: "#11081A",
            cardBackgroundHex: "#1B0E2B",
            secondaryCardBackgroundHex: "#281540",
            borderHex: "#3B205D",
            borderSubtleOpacity: 0.14,
            textPrimaryHex: "#F5E8FF",
            textSecondaryHex: "#B896D9",
            textMutedHex: "#6F528A",
            accentGoldHex: "#F72585",
            accentCyanHex: "#7209B7"
        ),
        landingTab: "dashboard",
        sidebarPosition: .left,
        cardCornerRadius: 12.0
    )
    
    public static let sunsetHorizon = AppThemeConfig(
        id: "sunset_horizon",
        name: "Sunset Horizon",
        author: "Overnode Community",
        version: "1.0",
        colors: ThemeColorsConfig(
            backgroundHex: "#170D0E",
            cardBackgroundHex: "#241517",
            secondaryCardBackgroundHex: "#331E20",
            borderHex: "#4A2B2E",
            borderSubtleOpacity: 0.12,
            textPrimaryHex: "#FFF0EB",
            textSecondaryHex: "#D49E94",
            textMutedHex: "#805851",
            accentGoldHex: "#FF7B00",
            accentCyanHex: "#FFB703"
        ),
        landingTab: "dashboard",
        sidebarPosition: .left,
        cardCornerRadius: 10.0
    )
    
    public static let all: [AppThemeConfig] = [
        overnodeOriginal,
        cyberpunkNeon,
        midnightOLED,
        emeraldMatrix,
        crimsonVelvet,
        sapphireAbyss,
        nordFrost,
        amethystDream,
        sunsetHorizon
    ]
}
