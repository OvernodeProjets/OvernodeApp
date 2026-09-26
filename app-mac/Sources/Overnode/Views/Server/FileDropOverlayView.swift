import SwiftUI

public struct FileDropOverlayView: View {
    @ObservedObject var loc = LocalizationManager.shared
    
    public init() {}
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.043, green: 0.051, blue: 0.075).opacity(0.88))
            
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    OvernodeTheme.accentGold,
                    style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                )
                .padding(2)
            
            VStack(spacing: 12) {
                Image(systemName: "tray.and.arrow.down.fill")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundColor(OvernodeTheme.accentGold)
                
                VStack(spacing: 4) {
                    Text(loc.string("files_drop_zone_title"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    
                    Text(loc.string("files_drop_zone_subtitle"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
            }
            .padding(24)
        }
        .allowsHitTesting(false)
        .transition(.opacity)
    }
}
