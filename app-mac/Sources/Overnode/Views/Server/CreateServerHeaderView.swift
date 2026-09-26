import SwiftUI

public struct CreateServerHeaderView: View {
    @ObservedObject var loc = LocalizationManager.shared
    let onDismiss: () -> Void
    
    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(OvernodeTheme.accentGold.opacity(0.16))
                    .frame(width: 38, height: 38)
                Image(systemName: "server.rack")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(OvernodeTheme.accentGold)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(loc.string("create_server_title"))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(OvernodeTheme.textPrimary)
                Text(loc.string("create_server_subtitle"))
                    .font(.system(size: 12))
                    .foregroundColor(OvernodeTheme.textSecondary)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(OvernodeTheme.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(OvernodeTheme.cardBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(OvernodeTheme.borderSubtle),
            alignment: .bottom
        )
    }
}
