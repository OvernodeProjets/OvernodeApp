import SwiftUI

public struct UpdateModalView: View {
    @ObservedObject var vm: UpdateViewModel
    @ObservedObject var loc = LocalizationManager.shared
    
    public init(vm: UpdateViewModel = .shared) {
        self.vm = vm
    }
    
    public var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Header badge & title
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(OvernodeTheme.accentGold)
                        Text(loc.string("update_badge").uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(OvernodeTheme.accentGold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(OvernodeTheme.accentGold.opacity(0.12))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(OvernodeTheme.accentGold.opacity(0.3), lineWidth: 1)
                    )
                    
                    Text(loc.string("update_title"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    
                    if let update = vm.availableUpdate {
                        HStack(spacing: 8) {
                            Text("v\(update.clientVersion)")
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundColor(OvernodeTheme.textSecondary)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(OvernodeTheme.accentGold)
                            Text("v\(update.latestVersion)")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(OvernodeTheme.accentGold)
                        }
                    }
                }
                
                // Release notes box
                VStack(alignment: .leading, spacing: 8) {
                    Text(loc.string("update_notes_title"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(OvernodeTheme.textSecondary)
                    
                    ScrollView {
                        Text(vm.availableUpdate?.releaseNotes ?? loc.string("update_default_notes"))
                            .font(.system(size: 13))
                            .foregroundColor(OvernodeTheme.textPrimary)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 120)
                    .padding(12)
                    .background(Color(red: 0.08, green: 0.09, blue: 0.12))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(OvernodeTheme.borderSubtle, lineWidth: 1)
                    )
                }
                
                // Download progress bar
                if case let .downloading(progress) = vm.state {
                    VStack(spacing: 8) {
                        HStack {
                            Text(loc.string("update_downloading"))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(OvernodeTheme.textSecondary)
                            Spacer()
                            Text(String(format: "%.0f%%", progress * 100))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(OvernodeTheme.accentGold)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, OvernodeTheme.accentGold],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(progress))), height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                } else if case .readyToRestart = vm.state {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text(loc.string("update_restarting"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(OvernodeTheme.accentGold)
                    }
                    .padding(.vertical, 4)
                }
                
                // Action Buttons
                HStack(spacing: 12) {
                    if let update = vm.availableUpdate, !update.mandatory && vm.state != .readyToRestart {
                        Button(action: { vm.dismiss() }) {
                            Text(loc.string("update_later"))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(OvernodeTheme.textSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 9)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button(action: {
                        Task {
                            await vm.startDownloadAndInstall()
                        }
                    }) {
                        HStack(spacing: 6) {
                            if vm.isDownloading {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 13))
                            }
                            Text(loc.string("update_now_button"))
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 9)
                        .background(OvernodeTheme.accentGold)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.state == .readyToRestart || vm.isDownloading)
                }
            }
            .padding(28)
            .frame(width: 460)
            .background(OvernodeTheme.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(OvernodeTheme.borderSubtle, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.6), radius: 30, x: 0, y: 15)
        }
    }
}

