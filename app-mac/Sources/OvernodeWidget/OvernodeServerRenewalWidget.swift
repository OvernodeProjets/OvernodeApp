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
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

// MARK: - Server Renewal Widget Entry View (High-Contrast Apple Liquid Glass)
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
    
    // High-contrast accessible forest emerald (WCAG AA compliant)
    private var accessibleGreen: Color {
        Color(red: 0.08, green: 0.55, blue: 0.25)
    }
    
    public var body: some View {
        AppleWidgetCanvas {
            switch family {
            case .systemSmall:
                smallView
            case .systemMedium:
                mediumView
            default:
                smallView
            }
        }
        .containerBackground(.ultraThinMaterial, for: .widget)
    }
    
    // MARK: - Small View
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .center) {
                AppleWidgetHeader(
                    title: "Overnode",
                    subtitle: nil,
                    systemImage: "server.rack",
                    tint: .blue
                )
                
                Spacer()
                
                if !entry.data.servers.isEmpty {
                    Text("\(entry.data.servers.count) SRV")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                        )
                }
            }
            
            Spacer()
            
            // Hero
            if !entry.data.isAuthenticated {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Image(systemName: "server.rack")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Text("Overnode Cloud")
                            .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    Text("Sign In")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Connect to monitor servers")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } else if let nextServer = entry.data.nextRenewalServer {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4.5) {
                        Circle()
                            .fill(nextServer.canRenew ? Color.green : Color.orange)
                            .frame(width: 5.5, height: 5.5)
                        Text(nextServer.canRenew ? "Ready to Renew" : "Renewal Opens In")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    Text(nextServer.name)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Text(nextServer.canRenew ? "Ready now" : nextServer.formattedAvailableIn)
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundColor(nextServer.canRenew ? accessibleGreen : .primary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    
                    Text(nextServer.canRenew ? "Expires in \(nextServer.formattedRemainingTime)" : "Expires in \(nextServer.formattedRemainingTime)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Image(systemName: "server.rack")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Text("Cloud Servers")
                            .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    Text("No Servers")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Deploy your first server")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Footer Action
            if !entry.data.isAuthenticated {
                HStack {
                    Spacer()
                    Text("Open App")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.vertical, 5)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                )
            } else if let nextServer = entry.data.nextRenewalServer, nextServer.canRenew {
                HStack {
                    Spacer()
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 9.5, weight: .bold))
                    Text("Renew Now")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.vertical, 6)
                .background(.green)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: .green.opacity(0.35), radius: 4, y: 2)
            } else if let nextServer = entry.data.nextRenewalServer {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 8.5))
                        .foregroundStyle(.orange)
                    Text("Opens in \(nextServer.formattedAvailableIn)")
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                )
            } else {
                HStack {
                    Spacer()
                    Text("Deploy Server")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.vertical, 5)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
    
    // MARK: - Medium View
    private var mediumView: some View {
        HStack(spacing: 14) {
            // Left Column
            VStack(alignment: .leading, spacing: 0) {
                AppleWidgetHeader(
                    title: "Overnode",
                    subtitle: "Renewals",
                    systemImage: "server.rack",
                    tint: .blue
                )
                
                Spacer()
                
                if !entry.data.isAuthenticated {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Sign In Required")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Log in to Overnode to track cloud server renewal windows.")
                            .font(.system(size: 10.5, weight: .regular))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                } else if let nextServer = entry.data.nextRenewalServer {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4.5) {
                            Circle()
                                .fill(nextServer.canRenew ? Color.green : Color.orange)
                                .frame(width: 5.5, height: 5.5)
                            Text(nextServer.canRenew ? "Ready to Renew" : "Next Renewal")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        
                        Text(nextServer.name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(nextServer.canRenew ? "Expires in \(nextServer.formattedRemainingTime). Ready for 30-day extension." : "Renewal opens in \(nextServer.formattedAvailableIn).")
                            .font(.system(size: 10.5, weight: .regular))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Cloud Servers")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("No active servers requiring renewal at this time.")
                            .font(.system(size: 10.5, weight: .regular))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                if !entry.data.isAuthenticated {
                    HStack(spacing: 4) {
                        Text("Open Overnode")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                        Image(systemName: "arrow.up.forward.app")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5))
                } else if let nextServer = entry.data.nextRenewalServer, nextServer.canRenew {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 9.5, weight: .bold))
                        Text("Renew Server")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.green)
                    .clipShape(Capsule())
                    .shadow(color: .green.opacity(0.35), radius: 4, y: 2)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "server.rack")
                            .font(.system(size: 9))
                            .foregroundStyle(.blue)
                        Text("\(entry.data.servers.count) active cloud server\(entry.data.servers.count > 1 ? "s" : "")")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Divider
            Rectangle()
                .fill(Color.primary.opacity(0.10))
                .frame(width: 0.75)
                .padding(.vertical, 2)
            
            // Right Timeline
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("SERVER TIMELINE")
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(entry.data.servers.count)")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                
                if entry.data.servers.isEmpty {
                    VStack(alignment: .center, spacing: 4) {
                        Spacer()
                        Image(systemName: "server.rack")
                            .font(.system(size: 16))
                            .foregroundStyle(.tertiary)
                        Text("No servers active")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 6) {
                        ForEach(entry.data.servers.prefix(2)) { server in
                            AppleFrostedTile(
                                cornerRadius: 8,
                                isEmphasized: server.canRenew,
                                tintColor: .green
                            ) {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(server.name)
                                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        Spacer()
                                        Circle()
                                            .fill(server.canRenew ? Color.green : (server.availableInSeconds ?? 0 <= 86400 ? Color.orange : Color.secondary))
                                            .frame(width: 4.5, height: 4.5)
                                    }
                                    
                                    HStack {
                                        if server.canRenew {
                                            Text("Ready now")
                                                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                                .foregroundColor(accessibleGreen)
                                            Spacer()
                                            Text("Renew")
                                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                                .foregroundColor(.green)
                                                .padding(.horizontal, 4.5)
                                                .padding(.vertical, 1.5)
                                                .background(Color.green.opacity(0.15))
                                                .clipShape(Capsule())
                                        } else {
                                            Text("In \(server.formattedAvailableIn)")
                                                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                                                .foregroundColor(.primary)
                                                .monospacedDigit()
                                            Spacer()
                                            Text(server.formattedRemainingTime)
                                                .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    
                    if entry.data.servers.count > 2 {
                        Text("+\(entry.data.servers.count - 2) more server\(entry.data.servers.count - 2 > 1 ? "s" : "")")
                            .font(.system(size: 7.5, weight: .medium))
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .frame(width: 135)
        }
    }
}

// MARK: - Widget Declaration
public struct OvernodeServerRenewalWidget: Widget {
    public let kind: String = "OvernodeServerRenewalWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ServerRenewalTimelineProvider()) { entry in
            ServerRenewalWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Server Renewals")
        .description("Track when your Overnode servers become renewable with countdowns in days, hours, and minutes.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
