import SwiftUI

public struct ResourceGaugeView: View {
    @ObservedObject var loc = LocalizationManager.shared
    
    let title: String
    let iconName: String
    let usedFormatted: String
    let totalFormatted: String
    let unit: String
    let percentage: Double
    let accentColor: Color
    
    public init(
        title: String,
        iconName: String,
        usedFormatted: String,
        totalFormatted: String,
        unit: String,
        percentage: Double,
        accentColor: Color = OvernodeTheme.accentGold
    ) {
        self.title = title
        self.iconName = iconName
        self.usedFormatted = usedFormatted
        self.totalFormatted = totalFormatted
        self.unit = unit
        self.percentage = percentage
        self.accentColor = accentColor
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: Title with discrete indicator + Value
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: iconName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(accentColor)
                    
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                
                Spacer()
                
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(usedFormatted)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    
                    if !totalFormatted.isEmpty && totalFormatted != "0" {
                        Text("/ (totalFormatted)(unit)")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(OvernodeTheme.textMuted)
                    } else if !unit.isEmpty {
                        Text(unit)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(OvernodeTheme.textMuted)
                    }
                }
            }
            
            // Subtle refined Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(
                            percentage > 95
                                ? OvernodeTheme.accentDanger
                                : (percentage > 80 ? OvernodeTheme.accentGold : accentColor)
                        )
                        .frame(width: max(4, geo.size.width * CGFloat(min(percentage / 100.0, 1.0))), height: 4)
                        .animation(.easeOut(duration: 0.3), value: percentage)
                }
            }
            .frame(height: 4)
            
            // Footer: percentage note
            HStack {
                Text(String(format: "%.1f%% %@", percentage, loc.string("resource_utilization")))
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(OvernodeTheme.textMuted)
                
                Spacer()
                
                if percentage > 90 {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(OvernodeTheme.accentDanger)
                            .frame(width: 5, height: 5)
                        Text(loc.string("resource_limit_reached"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(OvernodeTheme.accentDanger)
                    }
                }
            }
        }
        .padding(16)
        .background(OvernodeTheme.cardBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(OvernodeTheme.borderSubtle, lineWidth: 1)
        )
    }
}
