import SwiftUI

public struct HeaderBarView: View {
    @ObservedObject var loc = LocalizationManager.shared
    @ObservedObject var updateVM = UpdateViewModel.shared
    let onRefresh: () -> Void
    
    public init(onRefresh: @escaping () -> Void) {
        self.onRefresh = onRefresh
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            // Brand Logo
            HStack(spacing: 10) {
                if let logoURL = Bundle.appResourceURL(named: "overnode_logo", withExtension: "png"),
                   let nsImage = NSImage(contentsOf: logoURL) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 24)
                } else {
                    Image(systemName: "server.rack")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(OvernodeTheme.accentGold)
                    Text("OVERNODE")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                }
            }
            
            // Available Update Badge Indicator
            if updateVM.hasUpdateAvailable {
                Button(action: {
                    updateVM.showModal = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .bold))
                        Text(loc.string("update_badge"))
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(Color.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(OvernodeTheme.accentGold)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help(loc.string("update_title"))
            }
            
            Spacer()
            
            // Language Switcher
            HStack(spacing: 4) {
                ForEach(AppLanguage.allCases) { lang in
                    Button(action: {
                        loc.setLanguage(lang)
                    }) {
                        HStack(spacing: 4) {
                            Text(lang.flag)
                                .font(.system(size: 12))
                            Text(lang.rawValue.uppercased())
                                .font(.system(size: 11, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(loc.currentLanguage == lang ? Color.white.opacity(0.15) : Color.clear)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(loc.currentLanguage == lang ? OvernodeTheme.textPrimary : OvernodeTheme.textSecondary)
                }
            }
            .padding(3)
            .background(OvernodeTheme.secondaryCardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(OvernodeTheme.borderSubtle, lineWidth: 1)
            )
            
            // Refresh Button
            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(OvernodeTheme.textSecondary)
                    .padding(8)
                    .background(OvernodeTheme.secondaryCardBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(OvernodeTheme.borderSubtle, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help(loc.string("status_refresh"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(OvernodeTheme.cardBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(OvernodeTheme.borderSubtle),
            alignment: .bottom
        )
    }
}

