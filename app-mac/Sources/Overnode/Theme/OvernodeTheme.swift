import SwiftUI

public enum OvernodeTheme {
    // Background Colors
    public static var background: Color {
        if ThemeColorsStorage.shared.hasActiveCustomBackground {
            return Color.clear
        }
        return ThemeColorsStorage.shared.currentColors.background
    }
    public static var solidBackground: Color {
        ThemeColorsStorage.shared.currentColors.background
    }
    public static var cardBackground: Color {
        ThemeColorsStorage.shared.currentColors.cardBackground
    }
    public static var secondaryCardBackground: Color {
        ThemeColorsStorage.shared.currentColors.secondaryCardBackground
    }
    
    // Border & Divider Colors
    public static var border: Color {
        ThemeColorsStorage.shared.currentColors.border
    }
    public static var borderSubtle: Color {
        ThemeColorsStorage.shared.currentColors.borderSubtle
    }
    
    // Text Colors
    public static var textPrimary: Color {
        ThemeColorsStorage.shared.currentColors.textPrimary
    }
    public static var textSecondary: Color {
        ThemeColorsStorage.shared.currentColors.textSecondary
    }
    public static var textMuted: Color {
        ThemeColorsStorage.shared.currentColors.textMuted
    }
    
    // Accent & Brand Colors
    public static var accentGold: Color {
        ThemeColorsStorage.shared.currentColors.accentGold
    }
    public static var accentDiscord: Color {
        ThemeColorsStorage.shared.currentColors.accentDiscord
    }
    public static var accentSuccess: Color {
        ThemeColorsStorage.shared.currentColors.accentSuccess
    }
    public static var accentWarning: Color {
        ThemeColorsStorage.shared.currentColors.accentWarning
    }
    public static var accentDanger: Color {
        ThemeColorsStorage.shared.currentColors.accentDanger
    }
    public static var accentCyan: Color {
        ThemeColorsStorage.shared.currentColors.accentCyan
    }
    public static var accentBlue: Color {
        ThemeColorsStorage.shared.currentColors.accentBlue
    }
    
    // Gradients
    public static var goldGradient: LinearGradient {
        ThemeColorsStorage.shared.currentColors.goldGradient
    }
    public static var cardGradient: LinearGradient {
        ThemeColorsStorage.shared.currentColors.cardGradient
    }
    
    // Corner Radius
    public static var cardCornerRadius: CGFloat {
        CGFloat(ThemeColorsStorage.shared.currentConfig.cardCornerRadius)
    }
}
