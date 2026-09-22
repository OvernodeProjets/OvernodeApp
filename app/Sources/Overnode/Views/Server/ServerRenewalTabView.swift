import SwiftUI

public struct ServerRenewalTabView: View {
    @ObservedObject var vm: ServerDetailViewModel
    @ObservedObject var loc = LocalizationManager.shared
    
    public init(vm: ServerDetailViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 20))
                        .foregroundColor(OvernodeTheme.accentGold)
                    
                    Text(loc.string("renewal_title"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    
                    Spacer()
                    
                    if vm.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                Text(loc.string("renewal_subtitle"))
                    .font(.system(size: 13))
                    .foregroundColor(OvernodeTheme.textSecondary)
            }
            .padding(18)
            .background(OvernodeTheme.cardBackground)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            
            // Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                RenewalStatCard(
                    title: loc.string("renewal_next_date"),
                    value: formatDate(vm.renewalStatus?.nextRenewalAt) ?? loc.string("renewal_not_configured"),
                    icon: "calendar",
                    color: OvernodeTheme.accentBlue
                )
                
                RenewalStatCard(
                    title: loc.string("renewal_remaining_time"),
                    value: vm.renewalStatus?.timeRemaining ?? "—",
                    icon: "clock.arrow.circlepath",
                    color: (vm.renewalStatus?.isExpired == true) ? Color.red : OvernodeTheme.accentGold
                )
                
                RenewalStatCard(
                    title: loc.string("renewal_count"),
                    value: "\(vm.renewalStatus?.renewalCount ?? 0)",
                    icon: "arrow.triangle.2.circlepath",
                    color: Color(red: 0.25, green: 0.78, blue: 0.50)
                )
            }
            
            // Action Card: Renew Now
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(loc.string("renewal_action_title"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(OvernodeTheme.textPrimary)
                        
                        Text(loc.string("renewal_action_desc"))
                            .font(.system(size: 12))
                            .foregroundColor(OvernodeTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    let canRenew = vm.renewalStatus?.canRenew ?? false
                    Button(action: {
                        vm.renewServer()
                    }) {
                        HStack(spacing: 8) {
                            if vm.isRenewing {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 12))
                            }
                            Text(loc.string("renewal_button_now"))
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(canRenew ? Color.white : Color.white.opacity(0.4))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(canRenew ? OvernodeTheme.accentGold : Color(red: 0.18, green: 0.20, blue: 0.24))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isRenewing || !canRenew)
                }
                
                if let msg = vm.successMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(red: 0.25, green: 0.78, blue: 0.50))
                        Text(msg)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 0.25, green: 0.78, blue: 0.50))
                    }
                    .padding(10)
                    .background(Color(red: 0.25, green: 0.78, blue: 0.50).opacity(0.1))
                    .cornerRadius(6)
                }
                
                if let err = vm.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color(red: 0.95, green: 0.35, blue: 0.35))
                        Text(err)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 0.95, green: 0.35, blue: 0.35))
                    }
                    .padding(10)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                } else if vm.renewalStatus?.canRenew == false, let avail = vm.renewalStatus?.availableIn {
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .foregroundColor(OvernodeTheme.accentGold)
                        Text("\(loc.string("renewal_not_available_yet")) \(loc.string("renewal_available_in")) \(avail)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(OvernodeTheme.textSecondary)
                    }
                    .padding(10)
                    .background(OvernodeTheme.accentGold.opacity(0.08))
                    .cornerRadius(6)
                }
            }
            .padding(18)
            .background(OvernodeTheme.cardBackground)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            
            Spacer()
        }
        .onAppear {
            Task { await vm.loadRenewal() }
        }
    }
    
    private func formatDate(_ isoString: String?) -> String? {
        guard let iso = isoString, !iso.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: iso)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: iso)
        }
        guard let d = date else { return iso }
        let out = DateFormatter()
        out.dateStyle = .medium
        out.timeStyle = .short
        return out.string(from: d)
    }
}

private struct RenewalStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(OvernodeTheme.textSecondary)
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(OvernodeTheme.textPrimary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(14)
        .background(OvernodeTheme.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

