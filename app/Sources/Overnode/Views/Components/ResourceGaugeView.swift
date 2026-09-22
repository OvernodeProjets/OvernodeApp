import SwiftUI

public struct ResourceGaugeView: View {
    @ObservedObject var loc = LocalizationManager.shared
    
    let title: String
    let iconName: String
    let usedFormatted: String
    let totalFormatted: String
    let unit: String
    let percentage: Double
    let isBoosted: Bool
    
    public init(
        title: String,
        iconName: String,
        usedFormatted: String,
        totalFormatted: String,
        unit: String,
        percentage: Double,
        isBoosted: Bool = false
    ) {
        self.title = title
        self.iconName = iconName
        self.usedFormatted = usedFormatted
        self.totalFormatted = totalFormatted
        self.unit = unit
        self.percentage = percentage
        self.isBoosted = isBoosted
    }
    
    // Exact Toledo color hierarchy
    private var progressColor: Color {
        if percentage > 100 && !isBoosted {
            return Color(red: 0.937, green: 0.267, blue: 0.267) // red-500
        } else if percentage > 90 && !isBoosted {
            return Color(red: 0.937, green: 0.267, blue: 0.267) // red-500
        } else if percentage > 70 {
            return Color(red: 0.961, green: 0.620, blue: 0.106) // amber-500
        } else {
            return Color(red: 0.824, green: 0.835, blue: 0.855) // neutral-300
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Title + Used/Total
            HStack(alignment: .center) {
                HStack(spacing: 7) {
                    Image(systemName: iconName)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(isBoosted ? OvernodeTheme.accentGold : OvernodeTheme.textSecondary)
                    
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isBoosted ? OvernodeTheme.accentGold : OvernodeTheme.textPrimary)
                    
                    if isBoosted {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundColor(OvernodeTheme.accentGold)
                    }
                }
                
                Spacer()
                
                Text("(usedFormatted)(unit) / (totalFormatted)(unit)")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(red: 0.584, green: 0.631, blue: 0.678)) // #95a1ad
            }
            .padding(.bottom, 12)
            
            // Toledo exact track: h-1 bg-[#202229] rounded-full
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(red: 0.125, green: 0.133, blue: 0.161)) // #202229
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(
                            isBoosted
                                ? LinearGradient(
                                    colors: [Color(red: 0.85, green: 0.45, blue: 0.05), Color(red: 0.96, green: 0.62, blue: 0.11)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  )
                                : LinearGradient(
                                    colors: [progressColor, progressColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  )
                        )
                        .frame(width: max(0, geo.size.width * CGFloat(min(percentage / 100.0, 1.0))), height: 4)
                }
            }
            .frame(height: 4)
            
            // Footer: percentage utilized + ACTIVE BOOST tag
            HStack {
                Text(String(format: "%.1f%% %@", percentage, loc.string("resource_utilization")))
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(red: 0.584, green: 0.631, blue: 0.678)) // #95a1ad
                
                Spacer()
                
                if isBoosted {
                    Text("ACTIVE BOOST")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(0.8)
                        .foregroundColor(OvernodeTheme.accentGold.opacity(0.85))
                }
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(
            isBoosted
                ? Color.amberGoldBackground
                : Color.clear
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isBoosted
                        ? OvernodeTheme.accentGold.opacity(0.3)
                        : Color(red: 0.180, green: 0.200, blue: 0.216).opacity(0.5), // #2e3337/50
                    lineWidth: 1
                )
        )
    }
}

private extension Color {
    static let amberGoldBackground = Color(red: 0.961, green: 0.620, blue: 0.106).opacity(0.05)
}
