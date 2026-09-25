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
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? OvernodeTheme.accentGold.opacity(0.15) : Color(red: 0.125, green: 0.133, blue: 0.161))
                        .frame(width: 36, height: 36)
                    Image(systemName: egg.iconName)
                        .font(.system(size: 15))
                        .foregroundColor(isSelected ? OvernodeTheme.accentGold : Color(red: 0.584, green: 0.631, blue: 0.678))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(egg.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(OvernodeTheme.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(OvernodeTheme.accentGold)
                        }
                    }
                    
                    if !egg.description.isEmpty {
                        Text(egg.description)
                            .font(.system(size: 11))
                            .foregroundColor(OvernodeTheme.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    HStack(spacing: 8) {
                        Label(String(format: "%.0f MB", egg.minimum.ram), systemImage: "chart.pie")
                        Label(String(format: "%.0f%%", egg.minimum.cpu), systemImage: "cpu")
                        Label(String(format: "%.0f MB", egg.minimum.disk), systemImage: "archivebox")
                    }
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(red: 0.584, green: 0.631, blue: 0.678))
                    .padding(.top, 2)
                }
            }
            .padding(12)
            .background(isSelected ? Color.white.opacity(0.06) : OvernodeTheme.cardBackground)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? OvernodeTheme.accentGold : OvernodeTheme.borderSubtle, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

