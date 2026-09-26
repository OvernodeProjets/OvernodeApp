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
                    
                    if vm.isLoading && vm.renewalStatus == nil {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    
                    Button(action: {
                        Task { await vm.loadRenewal(force: true) }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundColor(OvernodeTheme.textSecondary)
                            .padding(7)
                            .background(Color(red: 0.125, green: 0.133, blue: 0.161))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isLoading)
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
            
            if !vm.server.isOwner {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color(red: 0.961, green: 0.620, blue: 0.106))
                    Text(loc.string("server_renewal_owner_only"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(OvernodeTheme.textPrimary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.961, green: 0.620, blue: 0.106).opacity(0.12))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 0.961, green: 0.620, blue: 0.106).opacity(0.3), lineWidth: 1)
                )
            }
            
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
                    value: vm.renewalStatus?.calculatedTimeRemaining ?? vm.renewalStatus?.timeRemaining ?? "—",
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
                    
                    let canRenew = (vm.renewalStatus?.canRenew ?? false) && vm.server.canRenew
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
                
                if let msg = vm.renewalSuccessMessage {
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
                } else if vm.renewalStatus?.canRenew == false, let avail = vm.renewalStatus?.calculatedAvailableIn ?? vm.renewalStatus?.availableIn {
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
    
    private func formatDate(_ rawString: String?) -> String? {
        guard let raw = rawString?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        
        // 1. Try ISO8601 with fractional seconds
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var parsedDate = isoFormatter.date(from: raw)
        
        // 2. Try ISO8601 standard
        if parsedDate == nil {
            isoFormatter.formatOptions = [.withInternetDateTime]
            parsedDate = isoFormatter.date(from: raw)
        }
        
        // 3. Try standard SQL / custom date formats
        if parsedDate == nil {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd HH:mm:ss",
                "yyyy-MM-dd HH:mm:ss.SSS",
                "yyyy-MM-dd"
            ]
            for fmt in formats {
                df.dateFormat = fmt
                if let d = df.date(from: raw) {
                    parsedDate = d
                    break
                }
            }
        }
        
        // 4. Try Unix timestamp
        if parsedDate == nil, let timestamp = Double(raw) {
            let timeInterval = timestamp > 10_000_000_000 ? timestamp / 1000.0 : timestamp
            parsedDate = Date(timeIntervalSince1970: timeInterval)
        }
        
        guard let d = parsedDate else { return raw }
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
