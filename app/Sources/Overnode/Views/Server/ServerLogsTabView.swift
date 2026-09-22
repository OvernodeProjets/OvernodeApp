import SwiftUI

public struct ServerLogsTabView: View {
    @ObservedObject var vm: ServerDetailViewModel
    @ObservedObject var loc = LocalizationManager.shared
    
    public init(vm: ServerDetailViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc.string("logs_title"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    Text(loc.string("logs_subtitle"))
                        .font(.system(size: 12))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    Task { await vm.loadLogs() }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(OvernodeTheme.textSecondary)
                        .padding(7)
                        .background(Color(red: 0.125, green: 0.133, blue: 0.161))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            
            // Logs List
            if vm.isLoading && vm.activityLogs.isEmpty {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else if vm.activityLogs.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 32))
                        .foregroundColor(OvernodeTheme.textMuted)
                    Text(loc.string("logs_empty"))
                        .font(.system(size: 13))
                        .foregroundColor(OvernodeTheme.textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .background(OvernodeTheme.cardBackground)
                .cornerRadius(8)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(vm.activityLogs) { log in
                            HStack(spacing: 12) {
                                Image(systemName: "bolt.horizontal.circle.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(actionColor(log.action))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(log.action)
                                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                        .foregroundColor(OvernodeTheme.textPrimary)
                                    
                                    if let user = log.username {
                                        Text(loc.string("logs_by_user") + " " + user)
                                            .font(.system(size: 11))
                                            .foregroundColor(OvernodeTheme.textSecondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Text(formatTimestamp(log.timestamp))
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(OvernodeTheme.textSecondary)
                            }
                            .padding(12)
                            .background(OvernodeTheme.cardBackground)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            
            Spacer()
        }
        .onAppear {
            Task { await vm.loadLogs() }
        }
    }
    
    private func actionColor(_ action: String) -> Color {
        if action.contains("delete") || action.contains("kill") {
            return Color(red: 0.95, green: 0.40, blue: 0.40)
        }
        if action.contains("start") || action.contains("renew") {
            return Color(red: 0.25, green: 0.78, blue: 0.50)
        }
        if action.contains("stop") || action.contains("restart") {
            return Color(red: 0.95, green: 0.75, blue: 0.25)
        }
        return OvernodeTheme.accentBlue
    }
    
    private func formatTimestamp(_ ts: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var d = formatter.date(from: ts)
        if d == nil {
            formatter.formatOptions = [.withInternetDateTime]
            d = formatter.date(from: ts)
        }
        guard let date = d else { return ts }
        let out = DateFormatter()
        out.dateStyle = .short
        out.timeStyle = .short
        return out.string(from: date)
    }
}

