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
                canClaim: false,
                currentStreak: 7,
                lastClaimTimestamp: Int64(Date().timeIntervalSince1970 * 1000),
                nextRewardAmount: 50,
                coins: 1450,
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
        
        // If claimed, schedule updates every 15 minutes and at midnight
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)
        let midnight = currentData.nextClaimDate
        
        // Pick whichever comes first or reload at midnight
        let refreshDate = currentData.canClaim ? nextUpdate : min(nextUpdate, midnight)
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
    
    public var body: some View {
        ZStack {
            // Dark Overnode Theme Background
            Color(red: 0.078, green: 0.086, blue: 0.106) // #14161B
            
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
            Color(red: 0.078, green: 0.086, blue: 0.106)
        }
    }
    
    // MARK: - System Small (Square) View
    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Brand & Streak
            HStack(alignment: .center) {
                HStack(spacing: 5) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22)) // Overnode Gold
                    Text("OVERNODE")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.85))
                }
                
                Spacer()
                
                if entry.data.currentStreak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Color.orange)
                        Text("\(entry.data.currentStreak)d")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.white)
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Center Countdown / Status
            if entry.data.canClaim {
                VStack(alignment: .leading, spacing: 3) {
                    Text("READY!")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22))
                    
                    Text("Daily Reward Available")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(red: 0.60, green: 0.64, blue: 0.70))
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("NEXT REWARD IN")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(red: 0.55, green: 0.60, blue: 0.66))
                    
                    // Formatted in hours then minutes
                    Text(entry.data.formattedRemainingTime)
                        .font(.system(size: 22, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color.white)
                }
            }
            
            Spacer()
            
            // Footer: Reward Potential
            HStack(spacing: 4) {
                Image(systemName: "circle.circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22))
                
                Text(entry.data.canClaim ? "Claim +\(entry.data.nextRewardAmount) coins" : "Up to +\(entry.data.nextRewardAmount) coins")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(entry.data.canClaim ? Color(red: 0.83, green: 0.69, blue: 0.22) : Color.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .padding(14)
    }
    
    // MARK: - System Medium (Rectangular) View
    private var mediumWidgetView: some View {
        HStack(spacing: 16) {
            // Left Column: Status & Countdown
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22))
                    Text("DAILY REWARD")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.9))
                }
                
                Spacer()
                
                if entry.data.canClaim {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ready to Claim!")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22))
                        
                        Text("Log in to Overnode to collect your coins.")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.60, green: 0.64, blue: 0.70))
                    }
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("NEXT REWARD AVAILABLE IN")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(red: 0.55, green: 0.60, blue: 0.66))
                        
                        Text(entry.data.formattedRemainingTime)
                            .font(.system(size: 26, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color.white)
                    }
                }
                
                Spacer()
                
                Text(entry.data.canClaim ? "Open Overnode App" : "Streak safely locked for today")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(red: 0.55, green: 0.60, blue: 0.66))
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.vertical, 4)
            
            // Right Column: Streak & Coin Stats
            VStack(alignment: .leading, spacing: 12) {
                // Streak Card
                VStack(alignment: .leading, spacing: 2) {
                    Text("CURRENT STREAK")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(red: 0.55, green: 0.60, blue: 0.66))
                    
                    HStack(spacing: 5) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color.orange)
                        Text("\(entry.data.currentStreak) days")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.white)
                    }
                }
                
                // Reward Card
                VStack(alignment: .leading, spacing: 2) {
                    Text("REWARD")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(red: 0.55, green: 0.60, blue: 0.66))
                    
                    HStack(spacing: 5) {
                        Image(systemName: "circle.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22))
                        Text("+\(entry.data.nextRewardAmount) coins")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22))
                    }
                }
            }
            .frame(width: 120, alignment: .leading)
        }
        .padding(16)
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
        .description("Track the time remaining until your next Overnode daily reward in hours and minutes.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
