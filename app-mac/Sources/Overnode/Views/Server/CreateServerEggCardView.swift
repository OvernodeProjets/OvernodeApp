import SwiftUI

public struct CreateServerEggCardView: View {
    let egg: ServerEgg
    let isSelected: Bool
    let onSelect: () -> Void
    
    public init(egg: ServerEgg, isSelected: Bool, onSelect: @escaping () -> Void) {
        self.egg = egg
        self.isSelected = isSelected
        self.onSelect = onSelect
    }
    
    public var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 14) {
                iconView
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .center) {
                        Text(egg.name)
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundColor(OvernodeTheme.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if isSelected {
                            ZStack {
                                Circle()
                                    .fill(OvernodeTheme.accentGold)
                                    .frame(width: 18, height: 18)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color.black)
                            }
                        }
                    }
                    
                    if !egg.description.isEmpty {
                        Text(egg.description)
                            .font(.system(size: 11.5))
                            .foregroundColor(OvernodeTheme.textSecondary)
                            .lineLimit(2)
                            .lineSpacing(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    specPills
                }
            }
            .padding(14)
            .background(isSelected ? OvernodeTheme.accentGold.opacity(0.12) : OvernodeTheme.secondaryCardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? OvernodeTheme.accentGold : OvernodeTheme.borderSubtle,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? OvernodeTheme.accentGold.opacity(0.20) : Color.white.opacity(0.06))
                .frame(width: 42, height: 42)
            Image(systemName: egg.iconName)
                .font(.system(size: 18))
                .foregroundColor(isSelected ? OvernodeTheme.accentGold : Color(red: 0.70, green: 0.75, blue: 0.82))
        }
    }
    
    private var specPills: some View {
        HStack(spacing: 8) {
            HStack(spacing: 3) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 9))
                Text(String(format: "%.0f MB", egg.minimum.ram))
            }
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(Color.white.opacity(0.05))
            .foregroundColor(Color(red: 0.65, green: 0.72, blue: 0.80))
            .cornerRadius(4)
            
            HStack(spacing: 3) {
                Image(systemName: "cpu")
                    .font(.system(size: 9))
                Text(String(format: "%.0f%%", egg.minimum.cpu))
            }
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(Color.white.opacity(0.05))
            .foregroundColor(Color(red: 0.65, green: 0.72, blue: 0.80))
            .cornerRadius(4)
            
            HStack(spacing: 3) {
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 9))
                Text(String(format: "%.0f MB", egg.minimum.disk))
            }
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(Color.white.opacity(0.05))
            .foregroundColor(Color(red: 0.65, green: 0.72, blue: 0.80))
            .cornerRadius(4)
        }
        .padding(.top, 3)
    }
}
