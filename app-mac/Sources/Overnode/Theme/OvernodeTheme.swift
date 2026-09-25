import SwiftUI

public enum OvernodeTheme {
    // Background Colors
    public static let background = Color(red: 0.063, green: 0.071, blue: 0.094) // #101218
    public static let cardBackground = Color(red: 0.094, green: 0.106, blue: 0.133) // #181B22
    public static let secondaryCardBackground = Color(red: 0.125, green: 0.133, blue: 0.161) // #202229
    
    // Border & Divider Colors
    public static let border = Color(red: 0.180, green: 0.200, blue: 0.216) // #2E3337
    public static let borderSubtle = Color.white.opacity(0.08)
    
    // Text Colors
    public static let textPrimary = Color.white
    public static let textSecondary = Color(red: 0.584, green: 0.631, blue: 0.678) // #95A1AD
    public static let textMuted = Color(red: 0.400, green: 0.440, blue: 0.490)
    
    // Accent & Brand Colors
    public static let accentGold = Color(red: 0.961, green: 0.620, blue: 0.106) // #F59E0B
    public static let accentDiscord = Color(red: 0.345, green: 0.396, blue: 0.949) // #5865F2
    public static let accentSuccess = Color(red: 0.133, green: 0.773, blue: 0.365) // #22C55E
    public static let accentWarning = Color(red: 0.961, green: 0.620, blue: 0.106) // #F59E0B
    public static let accentDanger = Color(red: 0.937, green: 0.267, blue: 0.267) // #EF4444
    public static let accentCyan = Color(red: 0.024, green: 0.714, blue: 0.831) // #06B6D4
    public static let accentBlue = Color(red: 0.350, green: 0.550, blue: 0.950) // Blue
    
    // Gradients
    public static let goldGradient = LinearGradient(
        colors: [Color(red: 0.961, green: 0.620, blue: 0.106), Color(red: 0.851, green: 0.467, blue: 0.055)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let cardGradient = LinearGradient(
        colors: [Color(red: 0.110, green: 0.125, blue: 0.155), Color(red: 0.082, green: 0.094, blue: 0.122)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
