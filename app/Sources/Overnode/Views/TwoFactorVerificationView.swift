import SwiftUI

public struct TwoFactorVerificationView: View {
    @ObservedObject var authVM: AuthViewModel
    @ObservedObject var loc = LocalizationManager.shared
    @State private var code: String = ""
    @State private var isSubmitting: Bool = false
    @State private var errorText: String?
    
    public init(authVM: AuthViewModel) {
        self.authVM = authVM
    }
    
    public var body: some View {
        ZStack {
            OvernodeTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(OvernodeTheme.accentGold.opacity(0.12))
                        .frame(width: 64, height: 64)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(OvernodeTheme.accentGold.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 28))
                        .foregroundColor(OvernodeTheme.accentGold)
                }
                
                // Titles
                VStack(spacing: 6) {
                    Text(loc.string("2fa_title"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    
                    Text(loc.string("2fa_subtitle"))
                        .font(.system(size: 13))
                        .foregroundColor(OvernodeTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                }
                
                if let err = errorText {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(OvernodeTheme.accentDanger)
                        Text(err)
                            .font(.system(size: 12))
                            .foregroundColor(OvernodeTheme.accentDanger)
                    }
                    .padding(10)
                    .frame(maxWidth: 320)
                    .background(OvernodeTheme.accentDanger.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Code Input
                VStack(spacing: 16) {
                    TextField("000000", text: $code)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(OvernodeTheme.secondaryCardBackground)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(OvernodeTheme.border, lineWidth: 1)
                        )
                        .frame(width: 220)
                    
                    Button(action: submitCode) {
                        HStack(spacing: 8) {
                            if isSubmitting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isSubmitting ? loc.string("status_connecting") : loc.string("2fa_verify_button"))
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(width: 220, height: 40)
                        .background(OvernodeTheme.accentGold)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(code.count < 6 || isSubmitting)
                    
                    Button(action: {
                        authVM.cancelTwoFactor()
                    }) {
                        Text(loc.string("2fa_cancel_button"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(OvernodeTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(32)
            .background(OvernodeTheme.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(OvernodeTheme.border, lineWidth: 1)
            )
        }
    }
    
    private func submitCode() {
        guard !code.isEmpty else { return }
        isSubmitting = true
        errorText = nil
        
        Task {
            do {
                try await authVM.verifyTwoFactorCode(code.trimmingCharacters(in: .whitespacesAndNewlines))
            } catch {
                await MainActor.run {
                    self.errorText = error.localizedDescription
                    self.isSubmitting = false
                }
            }
        }
    }
}
