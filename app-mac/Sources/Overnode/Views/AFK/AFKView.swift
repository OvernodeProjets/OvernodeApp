import SwiftUI
import AppKit

public struct AFKView: View {
    @ObservedObject var loc = LocalizationManager.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc.string("afk_title"))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    Text(loc.string("afk_subtitle"))
                        .font(.system(size: 13))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                .padding(.top, 4)
                
                // AFK Card
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.125, green: 0.133, blue: 0.161))
                                .frame(width: 44, height: 44)
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 20))
                                .foregroundColor(OvernodeTheme.accentGold)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(loc.string("afk_card_title"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(OvernodeTheme.textPrimary)
                            Text(loc.string("afk_card_rate"))
                                .font(.system(size: 12))
                                .foregroundColor(OvernodeTheme.textSecondary)
                        }
                        Spacer()
                    }
                    
                    Text(loc.string("afk_card_desc"))
                        .font(.system(size: 13))
                        .foregroundColor(OvernodeTheme.textSecondary)
                        .lineSpacing(4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        featureRow(loc.string("afk_feature_1"))
                        featureRow(loc.string("afk_feature_2"))
                        featureRow(loc.string("afk_feature_3"))
                    }
                    .padding(.vertical, 4)
                    
                    // Button to open AFK
                    Button(action: openAFKInBrowser) {
                        HStack(spacing: 8) {
                            Image(systemName: "safari")
                                .font(.system(size: 14))
                            Text(loc.string("afk_btn_open"))
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .foregroundColor(Color.black)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    Text(loc.string("afk_footnote"))
                        .font(.system(size: 11))
                        .foregroundColor(OvernodeTheme.textMuted)
                }
                .padding(24)
                .background(Color(red: 0.125, green: 0.133, blue: 0.161).opacity(0.4))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
                
                Spacer()
            }
            .padding(24)
        }
        .background(OvernodeTheme.background)
    }
    
    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.133, green: 0.773, blue: 0.365))
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(OvernodeTheme.textSecondary)
        }
    }
    
    private func openAFKInBrowser() {
        if let url = URL(string: "https://console.overnode.fr/coins/afk") {
            NSWorkspace.shared.open(url)
        }
    }
}
