import Foundation
import SwiftUI
import Combine

public enum DailyRewardTab: String, CaseIterable, Identifiable {
    case claim = "claim"
    case leaderboard = "leaderboard"
    case history = "history"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .claim: return "gift.fill"
        case .leaderboard: return "trophy.fill"
        case .history: return "clock.arrow.circlepath"
        }
    }
}

@MainActor
public final class DailyRewardViewModel: ObservableObject {
    @Published public var status: DailyRewardStatus?
    @Published public var leaderboard: [DailyLeaderboardEntry] = []
    @Published public var history: [DailyRewardHistoryItem] = []
    @Published public var selectedTab: DailyRewardTab = .claim
    @Published public var isLoading: Bool = false
    @Published public var isClaiming: Bool = false
    @Published public var isPurchasingProtection: Bool = false
    @Published public var errorMessage: String?
    @Published public var successMessage: String?
    @Published public var lastClaimResult: DailyRewardClaimResponse?
    
    private let service = DailyRewardService.shared
    
    public init() {}
    
    public func loadData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            async let statusTask = try? service.fetchStatus()
            async let boardTask = try? service.fetchLeaderboard(limit: 20)
            async let histTask = try? service.fetchHistory(limit: 25)
            
            let (statusRes, boardRes, histRes) = await (statusTask, boardTask, histTask)
            
            self.status = statusRes
            self.leaderboard = boardRes ?? []
            self.history = histRes ?? []
            self.isLoading = false
            
            if let st = statusRes {
                let widgetData = DailyRewardWidgetData(
                    isAuthenticated: true,
                    canClaim: st.canClaim,
                    currentStreak: st.currentStreak,
                    longestStreak: st.longestStreak,
                    lastClaimTimestamp: st.lastClaimTimestamp,
                    nextRewardAmount: st.nextReward?.amount ?? 25,
                    coins: st.totalCoinsEarned,
                    totalClaimed: st.totalClaimed,
                    streakProtection: st.streakProtection,
                    lastUpdated: Date()
                )
                DailyRewardStorage.shared.saveWidgetData(widgetData)
            }
        }
    }
    
    public func claim(onSuccess: @escaping (Int) -> Void) {
        guard !isClaiming else { return }
        isClaiming = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                let res = try await service.claimDailyReward()
                if res.success == true || res.reward != nil {
                    self.lastClaimResult = res
                    let rewardAmount = res.reward ?? 0
                    let bonusMsg = res.milestoneMessage != nil ? " (\(res.milestoneMessage!))" : ""
                    self.successMessage = "+\(rewardAmount) coins\(bonusMsg)"
                    
                    if let newBal = res.newBalance {
                        onSuccess(newBal)
                    }
                    
                    // Reload status & history to show updated streak & logs
                    self.loadData()
                } else if let err = res.error {
                    self.errorMessage = err
                } else {
                    self.errorMessage = "Une erreur est survenue lors de la réclamation."
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isClaiming = false
        }
    }
    
    public func purchaseProtection(level: String, onSuccess: @escaping (Int) -> Void) {
        guard !isPurchasingProtection else { return }
        isPurchasingProtection = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                let res = try await service.purchaseStreakProtection(level: level)
                if res.success == true {
                    self.successMessage = "Protection \(level.uppercased()) activée avec succès !"
                    if let newBal = res.newBalance {
                        onSuccess(newBal)
                    }
                    self.loadData()
                } else if let err = res.error {
                    self.errorMessage = err
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isPurchasingProtection = false
        }
    }
}
