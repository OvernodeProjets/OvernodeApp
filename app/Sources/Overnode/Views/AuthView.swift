import SwiftUI

public struct AuthView: View {
    @ObservedObject var authVM: AuthViewModel
    @ObservedObject var loc = LocalizationManager.shared
    
    public init(authVM: AuthViewModel) {
        self.authVM = authVM
    }
    
    public var body: some View {
        ZStack {
            OvernodeTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                // Top Language Switcher
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(AppLanguage.allCases) { lang in
                            Button(action: { loc.setLanguage(lang) }) {
                                Text(lang.flag + " " + lang.rawValue.uppercased())
                                    .font(.system(size: 11, weight: .bold))
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
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(OvernodeTheme.border, lineWidth: 1))
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)
                
                Spacer()
                
                // Central Card
                VStack(spacing: 24) {
                    // Real Overnode Logo
                    if let logoURL = Bundle.module.url(forResource: "overnode_logo", withExtension: "png"),
                       let nsImage = NSImage(contentsOf: logoURL) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 48)
                            .padding(.bottom, 4)
                    } else {
                        // Fallback icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(OvernodeTheme.accentGold.opacity(0.12))
                                .frame(width: 64, height: 64)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(OvernodeTheme.accentGold.opacity(0.3), lineWidth: 1)
                                )
                            Image(systemName: "server.rack")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(OvernodeTheme.accentGold)
                        }
                    }
                    
                    // Titles
                    VStack(spacing: 8) {
                        Text(loc.string("auth_title"))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(OvernodeTheme.textPrimary)
                        
                        Text(loc.string("auth_subtitle"))
                            .font(.system(size: 13))
                            .foregroundColor(OvernodeTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 320)
                    }
                    
                    // Error Message
                    if let error = authVM.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(OvernodeTheme.accentDanger)
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(OvernodeTheme.accentDanger)
                                .lineLimit(2)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(OvernodeTheme.accentDanger.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Auth Buttons
                    VStack(spacing: 12) {
                        // Discord OAuth2 Button
                        Button(action: {
                            authVM.loginWithDiscord()
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 14))
                                Text(authVM.isLoading ? loc.string("auth_logging_in") : loc.string("auth_login_discord"))
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(OvernodeTheme.accentDiscord)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .disabled(authVM.isLoading)
                        
                        // Passkey Button
                        Button(action: {
                            authVM.loginWithPasskey()
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "person.badge.key.fill")
                                    .font(.system(size: 14))
                                Text(loc.string("auth_login_passkey"))
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(OvernodeTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(OvernodeTheme.secondaryCardBackground)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(OvernodeTheme.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(authVM.isLoading)
                        
                        // Passkey notice
                        Text(loc.string("auth_passkey_notice"))
                            .font(.system(size: 11))
                            .foregroundColor(OvernodeTheme.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    .frame(width: 320)
                }
                .padding(32)
                .background(OvernodeTheme.cardBackground)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(OvernodeTheme.border, lineWidth: 1)
                )
                
                Spacer()
                
                // Footer info
                Text("Overnode Cloud Architecture • Apple Silicon Native")
                    .font(.system(size: 11))
                    .foregroundColor(OvernodeTheme.textMuted)
                    .padding(.bottom, 20)
            }
        }
        .sheet(item: Binding(
            get: { authVM.activeWebAuthURL.map { IdentifiableURL(url: $0) } },
            set: { _ in authVM.activeWebAuthURL = nil }
        )) { identURL in
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: authVM.isPasskeyMode ? "person.badge.key.fill" : "lock.shield.fill")
                            .font(.system(size: 14))
                            .foregroundColor(OvernodeTheme.accentGold)
                        Text(authVM.isPasskeyMode ? loc.string("auth_login_passkey") : loc.string("auth_login_discord"))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(OvernodeTheme.textPrimary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        authVM.activeWebAuthURL = nil
                        authVM.isPasskeyMode = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(OvernodeTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(OvernodeTheme.cardBackground)
                
                WebAuthModalView(
                    initialURL: identURL.url,
                    autoTriggerPasskey: authVM.isPasskeyMode,
                    onAuthSuccess: {
                        authVM.onWebAuthCompleted()
                    },
                    onCancel: {
                        authVM.activeWebAuthURL = nil
                        authVM.isPasskeyMode = false
                    }
                )
            }
            .frame(width: 620, height: 700)
        }
    }
}

private struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}
