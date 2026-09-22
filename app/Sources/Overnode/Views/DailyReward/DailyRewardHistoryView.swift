import SwiftUI

public struct DailyRewardHistoryView: View {
    @ObservedObject var vm: DailyRewardViewModel
    @ObservedObject var loc = LocalizationManager.shared
    
    public init(vm: DailyRewardViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc.string("daily_history_title"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    Text(loc.string("daily_history_desc"))
                        .font(.system(size: 12))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                
                Spacer()
                
                Button(action: { vm.loadData() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(OvernodeTheme.textSecondary)
                        .padding(6)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 4)
            
            if vm.history.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 32))
                        .foregroundColor(OvernodeTheme.textMuted)
                    Text(loc.string("daily_history_empty"))
                        .font(.system(size: 13))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 180)
                .background(OvernodeTheme.cardBackground)
                .cornerRadius(10)
            } else {
                VStack(spacing: 6) {
                    // Header columns
                    HStack(spacing: 12) {
                        Text(loc.string("daily_hist_date"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(OvernodeTheme.textMuted)
                            .frame(width: 140, alignment: .leading)
                        
                        Text(loc.string("daily_hist_streak"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(OvernodeTheme.textMuted)
                            .frame(width: 80, alignment: .leading)
                        
                        Text(loc.string("daily_hist_details"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(OvernodeTheme.textMuted)
                        
                        Spacer()
                        
                        Text(loc.string("daily_hist_reward"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(OvernodeTheme.textMuted)
                            .frame(width: 100, alignment: .trailing)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    
                    Divider()
                        .background(Color.white.opacity(0.06))
                    
                    ForEach(Array(vm.history.enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 12) {
                            Text(item.formattedDate)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(OvernodeTheme.textSecondary)
                                .frame(width: 140, alignment: .leading)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.orange)
                                Text("\(item.streak)j")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(OvernodeTheme.textPrimary)
                            }
                            .frame(width: 80, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Base: \(item.baseAmount)c")
                                        .font(.system(size: 11))
                                        .foregroundColor(OvernodeTheme.textSecondary)
                                    Text("•")
                                        .foregroundColor(OvernodeTheme.textMuted)
                                    Text(String(format: "x%.1f", item.multiplier))
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(OvernodeTheme.textPrimary)
                                    
                                    if let bonus = item.milestoneBonus, bonus > 0 {
                                        Text("•")
                                            .foregroundColor(OvernodeTheme.textMuted)
                                        Text("Bonus: +\(bonus)c")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(OvernodeTheme.accentGold)
                                    }
                                }
                                
                                if let msg = item.milestoneMessage {
                                    Text(msg)
                                        .font(.system(size: 10))
                                        .foregroundColor(OvernodeTheme.accentGold)
                                }
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "circle.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(OvernodeTheme.accentGold)
                                Text("+\(item.reward)")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(OvernodeTheme.accentGold)
                            }
                            .frame(width: 100, alignment: .trailing)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(index % 2 == 0 ? Color.white.opacity(0.02) : Color.clear)
                        .cornerRadius(6)
                    }
                }
                .padding(12)
                .background(OvernodeTheme.cardBackground)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
            }
        }
    }
}
