import SwiftUI
import WidgetKit

// MARK: - Overnode macOS Native Apple Liquid Glass Design System
// 100% Apple HIG: UltraThinMaterial, Apple System Colors, Refined Typography, Desktop Blending
public enum AppleWidgetTheme {
    // Apple HIG System Accents
    public static let yellow = Color.yellow
    public static let orange = Color.orange
    public static let green = Color.green
    public static let blue = Color.blue
    public static let red = Color.red
    
    // Apple Typography & Vibrancy
    public static let primary = Color.primary
    public static let secondary = Color.secondary
    public static let tertiary = Color.secondary.opacity(0.6)
}

// MARK: - Native Apple Liquid Glass Widget Frame
public struct AppleWidgetCanvas<Content: View>: View {
    public let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        ZStack {
            // 1. Authentic Apple Frosted Liquid Glass Backing
            Rectangle()
                .fill(.ultraThinMaterial)
            
            // 2. Subtle specular inner highlight (Apple Glass Light Sheen)
            VStack {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.18),
                        Color.white.opacity(0.02),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 50)
                Spacer()
            }
            
            // 3. Apple Widget Specular Hairline Edge
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.08),
                            Color.clear,
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.75
                )
            
            // 4. Content
            content
                .padding(13)
        }
    }
}

// MARK: - Apple Frosted Tile Card
public struct AppleFrostedTile<Content: View>: View {
    public let cornerRadius: CGFloat
    public let isEmphasized: Bool
    public let tintColor: Color?
    public let content: Content
    
    public init(
        cornerRadius: CGFloat = 10,
        isEmphasized: Bool = false,
        tintColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.isEmphasized = isEmphasized
        self.tintColor = tintColor
        self.content = content()
    }
    
    public var body: some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    if let tint = tintColor, isEmphasized {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint.opacity(0.10))
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                isEmphasized ? (tintColor ?? Color.white).opacity(0.35) : Color.white.opacity(0.15),
                                isEmphasized ? (tintColor ?? Color.white).opacity(0.10) : Color.white.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.65
                    )
            }
    }
}

// MARK: - Apple Header
public struct AppleWidgetHeader: View {
    public let title: String
    public let subtitle: String?
    public let systemImage: String
    public let tint: Color
    
    public init(
        title: String = "Overnode",
        subtitle: String? = nil,
        systemImage: String,
        tint: Color
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
    }
    
    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(tint)
            
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            
            if let sub = subtitle, !sub.isEmpty {
                Text("•")
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
                
                Text(sub)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
    }
}

// MARK: - Apple Pill Button
public struct ApplePillButton: View {
    public let title: String
    public let systemImage: String?
    public let backgroundGradient: LinearGradient?
    public let solidColor: Color?
    
    public init(
        title: String,
        systemImage: String? = nil,
        backgroundGradient: LinearGradient? = nil,
        solidColor: Color? = nil
    ) {
        self.title = title
        self.systemImage = systemImage
        self.backgroundGradient = backgroundGradient
        self.solidColor = solidColor
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            if let img = systemImage {
                Image(systemName: img)
                    .font(.system(size: 9.5, weight: .bold))
            }
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background {
            if let gradient = backgroundGradient {
                Capsule().fill(gradient)
            } else if let color = solidColor {
                Capsule().fill(color)
            } else {
                Capsule().fill(Color.accentColor)
            }
        }
        .shadow(color: (solidColor ?? .orange).opacity(0.3), radius: 4, y: 2)
    }
}
