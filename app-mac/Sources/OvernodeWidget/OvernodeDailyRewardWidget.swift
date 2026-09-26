import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
public struct DailyRewardWidgetEntry: TimelineEntry {
    public let date: Date
    public let data: DailyRewardWidgetData
    
    public init(date: Date, data: DailyRewardWidgetData) {
        self.date = date
        self.data = data
    }
}

// MARK: - Timeline Provider
public struct DailyRewardTimelineProvider: TimelineProvider {
    public typealias Entry = DailyRewardWidgetEntry
    
    public init() {}
    
    public func placeholder(in context: Context) -> DailyRewardWidgetEntry {
        DailyRewardWidgetEntry(
            date: Date(),
            data: DailyRewardWidgetData(
                isAuthenticated: true,
                canClaim: false,
                currentStreak: 7,
                longestStreak: 14,
                lastClaimTimestamp: Int64(Date().timeIntervalSince1970 * 1000),
                nextRewardAmount: 50,
                coins: 1450,
                totalClaimed: 24,
                streakProtection: 1,
                lastUpdated: Date()
            )
        )
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (DailyRewardWidgetEntry) -> Void) {
        var data = DailyRewardStorage.shared.loadWidgetData()
        if context.isPreview && !data.isAuthenticated {
            data = DailyRewardWidgetData(
                isAuthenticated: true,
                canClaim: false,
                currentStreak: 7,
                longestStreak: 14,
                lastClaimTimestamp: Int64(Date().timeIntervalSince1970 * 1000),
                nextRewardAmount: 50,
                coins: 1450,
                totalClaimed: 24,
                streakProtection: 1,
                lastUpdated: Date()
            )
        }
        let entry = DailyRewardWidgetEntry(date: Date(), data: data)
        completion(entry)
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<DailyRewardWidgetEntry>) -> Void) {
        let currentData = DailyRewardStorage.shared.loadWidgetData()
        let now = Date()
        let entries = [DailyRewardWidgetEntry(date: now, data: currentData)]
        
        let next15Min = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)
        let midnight = currentData.nextClaimDate
        let refreshDate = currentData.effectiveCanClaim ? next15Min : min(next15Min, midnight)
        
        completion(Timeline(entries: entries, policy: .after(refreshDate)))
    }
}

// MARK: - Widget Entry View (High-Contrast Apple Liquid Glass)
public struct DailyRewardWidgetEntryView: View {
    @Environment(\.widgetFamily) var envFamily
    public let entry: DailyRewardWidgetEntry
    public let explicitFamily: WidgetFamily?
    
    public var family: WidgetFamily {
        explicitFamily ?? envFamily
    }
    
    public init(entry: DailyRewardWidgetEntry, family: WidgetFamily? = nil) {
        self.entry = entry
        self.explicitFamily = family
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
    
    // MARK: - System Small View
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .center) {
                AppleWidgetHeader(
                    title: "Overnode",
                    subtitle: nil,
                    systemImage: "gift.fill",
                    tint: .yellow
                )
                
                Spacer()
                
                // Apple Streak Capsule
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(entry.data.currentStreak > 0 ? .orange : .secondary)
                    Text("\(entry.data.currentStreak)d")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .monospacedDigit()
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                )
            }
            
            Spacer()
            
            // Content
            if !entry.data.isAuthenticated {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Text("Overnode Cloud")
                            .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    Text("Sign In")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Connect to claim coins")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } else if entry.data.effectiveCanClaim {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.orange)
                        Text("Available Now")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("+\(entry.data.nextRewardAmount)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("COINS")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("Daily streak reward ready")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Next Reward")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    Text(entry.data.formattedRemainingTime)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .monospacedDigit()
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.green)
                        Text("Secured for today")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
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
            } else if entry.data.effectiveCanClaim {
                HStack {
                    Spacer()
                    Text("Claim Reward")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: .orange.opacity(0.3), radius: 4, y: 2)
            } else {
                HStack {
                    Image(systemName: "circle.circle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.yellow)
                    Text("\(entry.data.coins)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)
                    Spacer()
                    Text("+\(entry.data.nextRewardAmount) next")
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4.5)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                )
            }
        }
    }
    
    // MARK: - System Medium View
    private var mediumView: some View {
        HStack(spacing: 14) {
            // Left Column
            VStack(alignment: .leading, spacing: 0) {
                AppleWidgetHeader(
                    title: "Overnode",
                    subtitle: "Daily Reward",
                    systemImage: "gift.fill",
                    tint: .yellow
                )
                
                Spacer()
                
                if !entry.data.isAuthenticated {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Sign In Required")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Log in to Overnode to earn coins and track streaks.")
                            .font(.system(size: 10.5, weight: .regular))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                } else if entry.data.effectiveCanClaim {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 9.5, weight: .semibold))
                                .foregroundStyle(.orange)
                            Text("Reward Ready")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        
                        Text("Ready to Claim")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Claim +\(entry.data.nextRewardAmount) coins today.")
                            .font(.system(size: 10.5, weight: .regular))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Next Reward In")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        Text(entry.data.formattedRemainingTime)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .monospacedDigit()
                            .lineLimit(1)
                        
                        Text("Check back tomorrow for +\(entry.data.nextRewardAmount) coins.")
                            .font(.system(size: 10.5, weight: .regular))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
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
                } else if entry.data.effectiveCanClaim {
                    HStack(spacing: 4) {
                        Text("Claim in App")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                        Image(systemName: "arrow.up.forward.app")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .orange.opacity(0.3), radius: 4, y: 2)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.green)
                        Text("Streak secured today")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Subtle Divider
            Rectangle()
                .fill(Color.primary.opacity(0.10))
                .frame(width: 0.75)
                .padding(.vertical, 2)
            
            // Right Column: Metric Tiles
            VStack(spacing: 8) {
                // Streak Tile
                AppleFrostedTile(cornerRadius: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CURRENT STREAK")
                            .font(.system(size: 8, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(entry.data.currentStreak > 0 ? .orange : .secondary)
                            Text("\(entry.data.currentStreak) Days")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .monospacedDigit()
                        }
                        
                        HStack(spacing: 4) {
                            Text(entry.data.longestStreak > 0 ? "Best: \(entry.data.longestStreak)d" : "Daily check-in")
                                .font(.system(size: 9, weight: .regular))
                                .foregroundStyle(.tertiary)
                            
                            if entry.data.streakProtection > 0 {
                                Spacer()
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 7.5))
                                    .foregroundStyle(.green)
                                Text("\(entry.data.streakProtection)")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Balance Tile
                AppleFrostedTile(
                    cornerRadius: 10,
                    isEmphasized: entry.data.effectiveCanClaim,
                    tintColor: .yellow
                ) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.data.effectiveCanClaim ? "BONUS READY" : "WALLET BALANCE")
                            .font(.system(size: 8, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "circle.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.yellow)
                            Text(entry.data.effectiveCanClaim ? "+\(entry.data.nextRewardAmount)" : "\(entry.data.coins)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        
                        Text(entry.data.effectiveCanClaim ? "\(entry.data.coins) in wallet" : "+\(entry.data.nextRewardAmount) next")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(width: 125)
        }
    }
}

// MARK: - Widget Declaration
public struct OvernodeDailyRewardWidget: Widget {
    public let kind: String = "OvernodeDailyRewardWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyRewardTimelineProvider()) { entry in
            DailyRewardWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Reward")
        .description("Track your daily reward streak and countdown until your next bonus coins in hours and minutes.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
