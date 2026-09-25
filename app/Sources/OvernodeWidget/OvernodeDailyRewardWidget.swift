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
        let data = DailyRewardStorage.shared.loadWidgetData()
        let entry = DailyRewardWidgetEntry(date: Date(), data: data)
        completion(entry)
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<DailyRewardWidgetEntry>) -> Void) {
        let currentData = DailyRewardStorage.shared.loadWidgetData()
        var entries: [DailyRewardWidgetEntry] = []
        
        let now = Date()
        entries.append(DailyRewardWidgetEntry(date: now, data: currentData))
        
        // Refresh every 15 minutes or at midnight when a new claim day begins
        let next15Min = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)
        let midnight = currentData.nextClaimDate
        
        let refreshDate = currentData.effectiveCanClaim ? next15Min : min(next15Min, midnight)
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }
}

// MARK: - Widget Entry View
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
            
            // Subtle radial gold glow on top-leading edge
            RadialGradient(
                colors: [
                    Color(red: 0.85, green: 0.67, blue: 0.22).opacity(0.12),
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
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .containerBackground(for: .widget) {
            backgroundGradient
        }
    }
    
    // MARK: - System Small View
    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Brand & Streak
            HStack(alignment: .center) {
                HStack(spacing: 5) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(goldGradient)
                    Text("OVERNODE")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.90))
                        .tracking(1.0)
                }
                
                Spacer()
                
                // Streak badge
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 9))
                        .foregroundColor(entry.data.currentStreak > 0 ? Color(red: 1.0, green: 0.48, blue: 0.18) : Color.white.opacity(0.4))
                    Text("\(entry.data.currentStreak)d")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(entry.data.currentStreak > 0 ? .white : Color.white.opacity(0.6))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(
                    entry.data.currentStreak > 0
                        ? Color(red: 1.0, green: 0.48, blue: 0.18).opacity(0.15)
                        : Color.white.opacity(0.06)
                )
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(
                            entry.data.currentStreak > 0
                                ? Color(red: 1.0, green: 0.48, blue: 0.18).opacity(0.3)
                                : Color.white.opacity(0.08),
                            lineWidth: 0.8
                        )
                )
            }
            
            Spacer(minLength: 6)
            
            // Center Content
            if !entry.data.isAuthenticated {
                VStack(alignment: .leading, spacing: 3) {
                    Text("NOT SIGNED IN")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(red: 0.58, green: 0.63, blue: 0.72))
                        .tracking(0.8)
                    
                    Text("Log in to Overnode")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    
                    Text("Start your streak")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(red: 0.58, green: 0.63, blue: 0.72))
                        .lineLimit(1)
                }
            } else if entry.data.effectiveCanClaim {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(red: 0.91, green: 0.74, blue: 0.28))
                            .frame(width: 5, height: 5)
                        Text("REWARD READY")
                            .font(.system(size: 8, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(red: 0.91, green: 0.74, blue: 0.28))
                            .tracking(0.8)
                    }
                    
                    Text("Ready!")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(goldGradient)
                    
                    Text("+\(entry.data.nextRewardAmount) coins available")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("NEXT REWARD IN")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(red: 0.58, green: 0.63, blue: 0.72))
                        .tracking(0.8)
                    
                    Text(entry.data.formattedRemainingTime)
                        .font(.system(size: 21, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Color(red: 0.22, green: 0.82, blue: 0.50))
                        Text("Secured today")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Color(red: 0.58, green: 0.63, blue: 0.72))
                    }
                }
            }
            
            Spacer(minLength: 6)
            
            // Footer: Action / Status
            HStack {
                if !entry.data.isAuthenticated {
                    HStack(spacing: 4) {
                        Image(systemName: "person.badge.key.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Color(red: 0.85, green: 0.67, blue: 0.22))
                        Text("Open App to Login")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(Color(red: 0.85, green: 0.67, blue: 0.22))
                            .lineLimit(1)
                    }
                } else if entry.data.effectiveCanClaim {
                    HStack(spacing: 4) {
                        Image(systemName: "circle.circle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Color(red: 0.85, green: 0.67, blue: 0.22))
                        Text("Claim +\(entry.data.nextRewardAmount) coins")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.85, green: 0.67, blue: 0.22))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Color(red: 0.85, green: 0.67, blue: 0.22).opacity(0.15))
                    .cornerRadius(6)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "circle.circle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(Color(red: 0.85, green: 0.67, blue: 0.22))
                        Text("+\(entry.data.nextRewardAmount) coins next")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.70))
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
        }
        .padding(13)
    }
    
    // MARK: - System Medium View
    private var mediumWidgetView: some View {
        HStack(spacing: 12) {
            // Left Column: Hero Status & Message
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 5) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(goldGradient)
                    Text("OVERNODE")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.85))
                        .tracking(0.8)
                    Text("•")
                        .font(.system(size: 8))
                        .foregroundColor(Color.white.opacity(0.35))
                    Text("REWARD")
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.85, green: 0.67, blue: 0.22))
                        .tracking(0.5)
                }
                .lineLimit(1)
                
                Spacer(minLength: 6)
                
                // Status Headline & Description
                if !entry.data.isAuthenticated {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Sign In Required")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text("Log in to Overnode to track streaks and claim coins.")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundColor(Color(red: 0.58, green: 0.63, blue: 0.72))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                } else if entry.data.effectiveCanClaim {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Ready to Claim!")
                            .font(.system(size: 19, weight: .black, design: .rounded))
                            .foregroundStyle(goldGradient)
                            .lineLimit(1)
                        
                        Text("Claim your daily coins now.")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundColor(Color(red: 0.60, green: 0.65, blue: 0.74))
                            .lineLimit(1)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("NEXT REWARD IN")
                            .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(red: 0.58, green: 0.63, blue: 0.72))
                            .tracking(0.8)
                        
                        Text(entry.data.formattedRemainingTime)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text("Claimed today. Return tomorrow!")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundColor(Color(red: 0.58, green: 0.63, blue: 0.72))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }
                
                Spacer(minLength: 6)
                
                // Bottom Action Pill
                HStack(spacing: 5) {
                    if !entry.data.isAuthenticated {
                        Image(systemName: "arrow.up.forward.app.fill")
                            .font(.system(size: 9))
                        Text("Open Overnode App")
                            .font(.system(size: 9.5, weight: .semibold))
                    } else if entry.data.effectiveCanClaim {
                        Image(systemName: "gift.circle.fill")
                            .font(.system(size: 9.5))
                        Text("Open App to Claim")
                            .font(.system(size: 9.5, weight: .bold))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 9.5))
                            .foregroundColor(Color(red: 0.22, green: 0.82, blue: 0.50))
                        Text("Streak secured today")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(Color(red: 0.58, green: 0.63, blue: 0.72))
                    }
                }
                .foregroundColor(entry.data.effectiveCanClaim ? Color(red: 0.95, green: 0.82, blue: 0.35) : Color.white.opacity(0.8))
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Divider with soft glow
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
            
            // Right Column: Streak & Reward Cards
            VStack(spacing: 8) {
                // Streak Card
                VStack(alignment: .leading, spacing: 2) {
                    Text("CURRENT STREAK")
                        .font(.system(size: 7.5, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(red: 0.58, green: 0.63, blue: 0.72))
                        .tracking(0.5)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11))
                            .foregroundColor(entry.data.currentStreak > 0 ? Color(red: 1.0, green: 0.48, blue: 0.18) : Color.white.opacity(0.4))
                        Text("\(entry.data.currentStreak) days")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Text(entry.data.longestStreak > 0 ? "Best: \(entry.data.longestStreak)d" : "Daily check-in")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(Color(red: 0.58, green: 0.63, blue: 0.72))
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.04))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.07), lineWidth: 0.8)
                )
                
                // Reward Card
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.data.effectiveCanClaim ? "REWARD WAITING" : "NEXT REWARD")
                        .font(.system(size: 7.5, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(red: 0.85, green: 0.67, blue: 0.22))
                        .tracking(0.5)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "circle.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 0.85, green: 0.67, blue: 0.22))
                        Text("+\(entry.data.nextRewardAmount) coins")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundColor(Color(red: 0.85, green: 0.67, blue: 0.22))
                            .lineLimit(1)
                    }
                    
                    Text(entry.data.coins > 0 ? "\(entry.data.coins) in wallet" : "Daily bonus")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(Color(red: 0.58, green: 0.63, blue: 0.72))
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.85, green: 0.67, blue: 0.22).opacity(0.08))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 0.85, green: 0.67, blue: 0.22).opacity(0.20), lineWidth: 0.8)
                )
            }
            .frame(width: 114)
        }
        .padding(13)
    }
}

// MARK: - Main Widget Declaration
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
    }
}
