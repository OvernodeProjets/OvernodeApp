import SwiftUI

public struct CreateServerHeaderView: View {
    @ObservedObject var loc = LocalizationManager.shared
    let onDismiss: () -> Void
    
    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(OvernodeTheme.accentGold.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: "server.rack.badge.plus")
                    .font(.system(size: 14))
                    .foregroundColor(OvernodeTheme.accentGold)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(loc.string("create_server_title"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(OvernodeTheme.textPrimary)
                Text(loc.string("create_server_subtitle"))
                    .font(.system(size: 11))
                    .foregroundColor(OvernodeTheme.textSecondary)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(OvernodeTheme.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(OvernodeTheme.cardBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(OvernodeTheme.borderSubtle),
            alignment: .bottom
        )
    }
}

