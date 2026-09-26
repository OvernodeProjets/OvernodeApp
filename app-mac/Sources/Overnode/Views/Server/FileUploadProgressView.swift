import SwiftUI

public struct FileUploadProgressView: View {
    let progress: Double
    let statusText: String
    
    public init(progress: Double, statusText: String) {
        self.progress = progress
        self.statusText = statusText
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 14, height: 14)
                
                Text(statusText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(OvernodeTheme.textPrimary)
                
                Spacer()
                
                Text("\(Int(max(0, min(1, progress)) * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(OvernodeTheme.accentGold)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 5)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(OvernodeTheme.accentGold)
                        .frame(width: max(4, geo.size.width * CGFloat(max(0, min(1, progress)))), height: 5)
                        .animation(.linear(duration: 0.2), value: progress)
                }
            }
            .frame(height: 5)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(OvernodeTheme.cardBackground)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(OvernodeTheme.accentGold.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 4)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}
