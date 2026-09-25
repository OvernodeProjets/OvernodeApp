import WidgetKit
import SwiftUI

// MARK: - Server Renewal Timeline Entry
public struct ServerRenewalWidgetEntry: TimelineEntry {
    public let date: Date
    public let data: DailyRewardWidgetData
    
    public init(date: Date, data: DailyRewardWidgetData) {
        self.date = date
        self.data = data
    }
}

// MARK: - Server Renewal Timeline Provider
public struct ServerRenewalTimelineProvider: TimelineProvider {
    public typealias Entry = ServerRenewalWidgetEntry
    
    public init() {}
    
    private static var sampleServers: [ServerWidgetRenewalInfo] {
        [
            ServerWidgetRenewalInfo(
                identifier: "srv-mc-prod",
                name: "Production MC",
                nextRenewalAt: "2026-09-27T12:00:00Z",
                remainingSeconds: 144000,
                formattedRemainingTime: "1d 16h",
                canRenew: false,
                isExpired: false,
                availableIn: "23h 58m",
                availableInSeconds: 86280,
                formattedAvailableIn: "23h 58m"
            ),
            ServerWidgetRenewalInfo(
                identifier: "srv-bungee",
                name: "Bungee Proxy",
                nextRenewalAt: "2026-09-26T08:00:00Z",
                remainingSeconds: 43200,
                formattedRemainingTime: "12h left",
                canRenew: true,
                isExpired: false,
                availableIn: nil,
                availableInSeconds: 0,
                formattedAvailableIn: "Ready now"
            ),
            ServerWidgetRenewalInfo(
                identifier: "srv-bot",
                name: "Discord Bot Node",
                nextRenewalAt: "2026-10-12T00:00:00Z",
                remainingSeconds: 1036800,
                formattedRemainingTime: "12d left",
                canRenew: false,
                isExpired: false,
                availableIn: "11d",
                availableInSeconds: 950400,
                formattedAvailableIn: "11d"
            )
        ]
    }
    
    public func placeholder(in context: Context) -> ServerRenewalWidgetEntry {
        ServerRenewalWidgetEntry(
            date: Date(),
            data: DailyRewardWidgetData(
                isAuthenticated: true,
                servers: Self.sampleServers
            )
        )
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (ServerRenewalWidgetEntry) -> Void) {
        var data = DailyRewardStorage.shared.loadWidgetData()
        if context.isPreview && data.servers.isEmpty {
            data = DailyRewardWidgetData(
                isAuthenticated: true,
                canClaim: data.canClaim,
                currentStreak: data.currentStreak,
                longestStreak: data.longestStreak,
                lastClaimTimestamp: data.lastClaimTimestamp,
                nextRewardAmount: data.nextRewardAmount,
                coins: data.coins,
                totalClaimed: data.totalClaimed,
                streakProtection: data.streakProtection,
                lastUpdated: Date(),
                servers: Self.sampleServers
            )
        }
        let entry = ServerRenewalWidgetEntry(date: Date(), data: data)
        completion(entry)
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<ServerRenewalWidgetEntry>) -> Void) {
        let currentData = DailyRewardStorage.shared.loadWidgetData()
        let now = Date()
        let entry = ServerRenewalWidgetEntry(date: now, data: currentData)
        
        // Refresh every 15 minutes
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }
}

// MARK: - Server Renewal Widget Entry View
public struct ServerRenewalWidgetEntryView: View {
    @Environment(\.widgetFamily) var envFamily
    public let entry: ServerRenewalWidgetEntry
    public let explicitFamily: WidgetFamily?
    
    public var family: WidgetFamily {
        explicitFamily ?? envFamily
    }
    
    public init(entry: ServerRenewalWidgetEntry, family: WidgetFamily? = nil) {
        self.entry = entry
        self.explicitFamily = family
    }
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.082, green: 0.098, blue: 0.137), // #151923
                Color(red: 0.043, green: 0.051, blue: 0.075)  // #0B0D13
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var goldGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.86, blue: 0.52),
                Color(red: 0.85, green: 0.67, blue: 0.22)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    public var body: some View {
        ZStack {
            backgroundGradient
            
            RadialGradient(
                colors: [
                    Color(red: 0.85, green: 0.67, blue: 0.22).opacity(0.10),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 180
            )
            
            switch family {
            case .systemSmall:
                smallWidgetView
            case .systemMedium:
                mediumWidgetView
            default:
                smallWidgetView
            }
        }
        .containerBackground(for: .widget) {
            backgroundGradient
        }
    }
    
    // MARK: - Small Widget View
    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .center, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(goldGradient)
                    Text("OVERNODE")
                        .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.90))
                        .tracking(0.5)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if !entry.data.servers.isEmpty {
                    Text("\(entry.data.servers.count) SRV")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.85, green: 0.67, blue: 0.22))
                        .padding(.horizontal, 4.5)
                        .padding(.vertical, 1.5)
                        .background(Color(red: 0.85, green: 0.67, blue: 0.22).opacity(0.12))
                        .cornerRadius(4)
                }
            }
            
            Spacer(minLength: 5)
            
            // Content
            if !entry.data.isAuthenticated {
                VStack(alignment: .leading, spacing: 3) {
                    Text("SIGN IN")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(red: 0.58, green: 0.63, blue: 0.72))
                        .tracking(0.8)
                    Text("Login required")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text("Open Overnode to connect")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Color(red: 0.58, green: 0.63, blue: 0.72))
                        .lineLimit(1)
                }
            } else if let nextServer = entry.data.nextRenewalServer {
                VStack(alignment: .leading, spacing: 2) {
                    // Tag indicating readiness or countdown until renewal opens
                    Text(renewalTagTitle(for: nextServer))
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .foregroundColor(renewalTagColor(for: nextServer))
                        .tracking(0.8)
                    
                    Text(nextServer.name)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    // The Big Countdown / Status Text:
                    // If not yet available: shows availableIn (e.g. "23h 58m")
                    // If available now: shows "Ready now"
                    // If expired: shows "Expired"
                    Text(mainHeroText(for: nextServer))
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(urgencyColor(for: nextServer))
                        .lineLimit(1)
                        .minimumScaleFactor(0.80)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(urgencyColor(for: nextServer))
                            .frame(width: 5, height: 5)
                        Text(statusSubLabel(for: nextServer))
                            .font(.system(size: 8.5, weight: .semibold))
                            .foregroundColor(Color(red: 0.65, green: 0.70, blue: 0.78))
                            .lineLimit(1)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    Text("SERVERS")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(red: 0.58, green: 0.63, blue: 0.72))
                        .tracking(0.8)
                    Text("No Servers")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("Deploy your first server")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Color(red: 0.58, green: 0.63, blue: 0.72))
                }
            }
            
            Spacer(minLength: 5)
            
            // Footer
            HStack(spacing: 4) {
                if !entry.data.isAuthenticated {
                    Image(systemName: "person.badge.key.fill")
                        .font(.system(size: 8.5))
                        .foregroundColor(Color(red: 0.85, green: 0.67, blue: 0.22))
                    Text("Sign in to sync")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(red: 0.85, green: 0.67, blue: 0.22))
                } else if let nextServer = entry.data.nextRenewalServer, nextServer.canRenew {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 8.5))
                        .foregroundColor(Color(red: 0.25, green: 0.82, blue: 0.50))
                    Text("Renew in Overnode")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(red: 0.25, green: 0.82, blue: 0.50))
                } else if entry.data.servers.count > 1 {
                    Image(systemName: "server.rack")
                        .font(.system(size: 8))
                        .foregroundColor(Color.white.opacity(0.60))
                    Text("+\(entry.data.servers.count - 1) other server\(entry.data.servers.count - 1 > 1 ? "s" : "")")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.65))
                } else if let nextServer = entry.data.nextRenewalServer {
                    Image(systemName: "clock")
                        .font(.system(size: 8))
                        .foregroundColor(Color(red: 0.85, green: 0.67, blue: 0.22))
                    Text("Expires in \(nextServer.formattedRemainingTime)")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.70))
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 8.5))
                        .foregroundColor(Color(red: 0.85, green: 0.67, blue: 0.22))
                    Text("Overnode Cloud")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.70))
                }
            }
            .lineLimit(1)
        }
        .padding(12)
    }
    
    // MARK: - Medium Widget View
    private var mediumWidgetView: some View {
        HStack(spacing: 12) {
            // Left Column: Next Renewable Hero
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 5) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(goldGradient)
                    Text("OVERNODE")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.85))
                        .tracking(0.8)
                    Text("•")
                        .font(.system(size: 8))
                        .foregroundColor(Color.white.opacity(0.35))
                    Text("RENEWAL")
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.85, green: 0.67, blue: 0.22))
                        .tracking(0.5)
                }
                .lineLimit(1)
                
                Spacer(minLength: 6)
                
                if !entry.data.isAuthenticated {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Sign In Required")
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("Log in to Overnode to monitor server renewal.")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(red: 0.58, green: 0.63, blue: 0.72))
                            .lineLimit(2)
                    }
                } else if let nextServer = entry.data.nextRenewalServer {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(renewalTagTitle(for: nextServer))
                            .font(.system(size: 8, weight: .heavy, design: .rounded))
                            .foregroundColor(renewalTagColor(for: nextServer))
                            .tracking(0.8)
                        
                        Text(nextServer.name)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(mainHeroText(for: nextServer))
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundColor(urgencyColor(for: nextServer))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(urgencyColor(for: nextServer))
                                .frame(width: 5, height: 5)
                            Text(statusSubLabel(for: nextServer))
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Color(red: 0.65, green: 0.70, blue: 0.78))
                                .lineLimit(1)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Cloud Servers")
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("No active servers found on your Overnode account.")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(red: 0.58, green: 0.63, blue: 0.72))
                            .lineLimit(2)
                    }
                }
                
                Spacer(minLength: 6)
                
                // Footer
                HStack(spacing: 5) {
                    if !entry.data.isAuthenticated {
                        Image(systemName: "arrow.up.forward.app.fill")
                            .font(.system(size: 9))
                        Text("Open Overnode")
                            .font(.system(size: 9.5, weight: .semibold))
                    } else if let nextServer = entry.data.nextRenewalServer, nextServer.canRenew {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Color(red: 0.25, green: 0.82, blue: 0.50))
                        Text("Action: Ready to Renew")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(red: 0.25, green: 0.82, blue: 0.50))
                    } else if entry.data.servers.isEmpty {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Color(red: 0.85, green: 0.67, blue: 0.22))
                        Text("Create a Server")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(Color(red: 0.85, green: 0.67, blue: 0.22))
                    } else {
                        Image(systemName: "server.rack")
                            .font(.system(size: 9))
                            .foregroundColor(Color(red: 0.85, green: 0.67, blue: 0.22))
                        Text("\(entry.data.servers.count) active server\(entry.data.servers.count > 1 ? "s" : "")")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.85))
                    }
                }
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.02),
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 1)
                .padding(.vertical, 4)
            
            // Right Column: Server List
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text("SERVERS TIMELINE")
                        .font(.system(size: 7.5, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(red: 0.85, green: 0.67, blue: 0.22))
                        .tracking(0.5)
                    Spacer()
                    if !entry.data.servers.isEmpty {
                        Text("\(entry.data.servers.count)")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.6))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(3)
                    }
                }
                
                if entry.data.servers.isEmpty {
                    VStack(alignment: .center, spacing: 5) {
                        Spacer()
                        Image(systemName: "server.rack")
                            .font(.system(size: 20))
                            .foregroundColor(Color.white.opacity(0.25))
                        Text("No servers to renew")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(Color(red: 0.58, green: 0.63, blue: 0.72))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 5) {
                        ForEach(entry.data.servers.prefix(2)) { server in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text(server.name)
                                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Spacer(minLength: 2)
                                    Circle()
                                        .fill(urgencyColor(for: server))
                                        .frame(width: 5, height: 5)
                                }
                                
                                HStack(spacing: 4) {
                                    Image(systemName: server.canRenew ? "checkmark.circle.fill" : "clock.fill")
                                        .font(.system(size: 7.5))
                                        .foregroundColor(urgencyColor(for: server))
                                    
                                    Text(server.canRenew ? "Ready now" : "In \(server.formattedAvailableIn)")
                                        .font(.system(size: 10.5, weight: .black, design: .rounded))
                                        .foregroundColor(urgencyColor(for: server))
                                        .lineLimit(1)
                                    
                                    Spacer(minLength: 2)
                                    
                                    if server.canRenew {
                                        Text("Renew")
                                            .font(.system(size: 7.5, weight: .bold))
                                            .foregroundColor(Color(red: 0.85, green: 0.67, blue: 0.22))
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color(red: 0.85, green: 0.67, blue: 0.22).opacity(0.12))
                                            .cornerRadius(3)
                                    } else {
                                        Text(server.formattedRemainingTime)
                                            .font(.system(size: 7.5, weight: .medium, design: .monospaced))
                                            .foregroundColor(Color.white.opacity(0.45))
                                    }
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(7)
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(
                                        urgencyColor(for: server).opacity(0.20),
                                        lineWidth: 0.7
                                    )
                            )
                        }
                    }
                    
                    if entry.data.servers.count > 2 {
                        Text("+\(entry.data.servers.count - 2) more server\(entry.data.servers.count - 2 > 1 ? "s" : "")")
                            .font(.system(size: 7.5, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.40))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .frame(width: 130)
        }
        .padding(13)
    }
    
    // MARK: - Helpers
    private func renewalTagTitle(for server: ServerWidgetRenewalInfo) -> String {
        if server.isExpired {
            return "RENEWAL EXPIRED"
        }
        if server.canRenew {
            return "READY TO RENEW"
        }
        return "RENEWABLE IN"
    }
    
    private func renewalTagColor(for server: ServerWidgetRenewalInfo) -> Color {
        if server.isExpired {
            return Color.red
        }
        if server.canRenew {
            return Color(red: 0.25, green: 0.82, blue: 0.50) // Green
        }
        return Color(red: 0.85, green: 0.67, blue: 0.22) // Gold
    }
    
    private func mainHeroText(for server: ServerWidgetRenewalInfo) -> String {
        if server.isExpired {
            return "Expired"
        }
        if server.canRenew {
            return "Ready now"
        }
        return server.formattedAvailableIn
    }
    
    private func statusSubLabel(for server: ServerWidgetRenewalInfo) -> String {
        if server.isExpired {
            return "Server suspended"
        }
        if server.canRenew {
            return "Expires in \(server.formattedRemainingTime)"
        }
        return "Expires in \(server.formattedRemainingTime)"
    }
    
    private func urgencyColor(for server: ServerWidgetRenewalInfo) -> Color {
        if server.isExpired {
            return Color.red
        }
        if server.canRenew {
            return Color(red: 0.25, green: 0.82, blue: 0.50) // Emerald / Ready
        }
        if let avail = server.availableInSeconds {
            if avail < 86400 {
                return Color(red: 1.0, green: 0.52, blue: 0.20) // Amber: available in < 24h!
            } else if avail < 86400 * 3 {
                return Color(red: 0.95, green: 0.82, blue: 0.35) // Gold
            }
        }
        return Color(red: 0.40, green: 0.70, blue: 1.0) // Soft Blue / Scheduled
    }
}

// MARK: - Main Server Renewal Widget Declaration
public struct OvernodeServerRenewalWidget: Widget {
    public let kind: String = "OvernodeServerRenewalWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ServerRenewalTimelineProvider()) { entry in
            ServerRenewalWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Server Renewals")
        .description("Track expiration dates and renewal countdowns for your Overnode cloud servers.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
