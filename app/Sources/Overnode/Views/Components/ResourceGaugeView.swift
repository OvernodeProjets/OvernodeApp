import SwiftUI

public struct ResourceGaugeView: View {
    @ObservedObject var loc = LocalizationManager.shared
    
    let title: String
    let iconName: String
    let usedFormatted: String
    let totalFormatted: String
    let unit: String
    let percentage: Double
    let solidColor: Color
    
    public init(
        title: String,
        iconName: String,
        usedFormatted: String,
        totalFormatted: String,
        unit: String,
        percentage: Double,
        solidColor: Color = Color.white.opacity(0.85)
    ) {
        self.title = title
        self.iconName = iconName
        self.usedFormatted = usedFormatted
        self.totalFormatted = totalFormatted
        self.unit = unit
        self.percentage = percentage
        self.solidColor = solidColor
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Title + Values
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: iconName)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(solidColor)
                    
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(OvernodeTheme.textPrimary)
                }
                
                Spacer()
                
                Text("(usedFormatted)(unit) / (totalFormatted)(unit)")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(red: 0.584, green: 0.631, blue: 0.678)) // #95a1ad
            }
            .padding(.bottom, 12)
            
            // Solid, crisp Progress Bar (4px height)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(red: 0.125, green: 0.133, blue: 0.161)) // #202229
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(solidColor)
                        .frame(width: max(0, geo.size.width * CGFloat(min(percentage / 100.0, 1.0))), height: 4)
                }
            }
            .frame(height: 4)
            
            // Footer: percentage utilized
            HStack {
                Text(String(format: "%.1f%% %@", percentage, loc.string("resource_utilization")))
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(red: 0.584, green: 0.631, blue: 0.678)) // #95a1ad
                
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 0.180, green: 0.200, blue: 0.216).opacity(0.5), lineWidth: 1)
        )
    }
}
