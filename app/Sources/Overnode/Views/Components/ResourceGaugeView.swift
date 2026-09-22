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
            // Header: Icon + Title + Value
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(accentColor)
                        .frame(width: 28, height: 28)
                        .background(accentColor.opacity(0.12))
                        .cornerRadius(6)
                    
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                }
                
                Spacer()
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(usedFormatted)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    
                    Text("/ \(totalFormatted) \(unit)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(OvernodeTheme.secondaryCardBackground)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [accentColor.opacity(0.8), accentColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * CGFloat(min(percentage / 100.0, 1.0))), height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: percentage)
                }
            }
            .frame(height: 8)
            
            // Footer: Percentage
            HStack {
                Text(String(format: "%.1f%% %@", percentage, loc.string("resource_utilization")))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(OvernodeTheme.textSecondary)
                
                Spacer()
                
                if percentage > 90 {
                    Text("LIMITE ATTEINTE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(OvernodeTheme.accentDanger)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(OvernodeTheme.accentDanger.opacity(0.15))
                        .cornerRadius(4)
                }
            }
        }
        .padding(16)
        .background(OvernodeTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(OvernodeTheme.border, lineWidth: 1)
        )
    }
}
