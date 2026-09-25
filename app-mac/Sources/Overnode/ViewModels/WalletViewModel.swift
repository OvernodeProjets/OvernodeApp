import Foundation
import Combine

public enum WalletTab: String, CaseIterable, Identifiable {
    case overview = "overview"
    case leaderboard = "leaderboard"
    case activity = "activity"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .overview: return "creditcard"
        case .leaderboard: return "trophy"
        case .activity: return "clock.arrow.circlepath"
        }
    }
}

@MainActor
public final class WalletViewModel: ObservableObject {
    @Published public var billingInfo: BillingInfo?
    @Published public var leaderboard: LeaderboardResponse?
    @Published public var transactions: [BillingTransaction] = []
    @Published public var selectedTab: WalletTab = .overview
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    private let service = BillingService.shared
    
    public init() {}
    
    public func loadData() {
        Task {
            isLoading = true
            errorMessage = nil
            
            async let billingTask = try? service.fetchBillingInfo()
            async let leaderboardTask = try? service.fetchLeaderboard()
            async let txTask = try? service.fetchTransactions()
            
            let (bInfo, lBoard, txs) = await (billingTask, leaderboardTask, txTask)
            
            self.billingInfo = bInfo
            self.leaderboard = lBoard
            self.transactions = txs ?? []
            self.isLoading = false
        }
    }
    
    public func openAddFunds() {
        service.openAddFundsWeb()
    }
    
    public func purchaseCoinsPackage(_ amount: Int) {
        service.openPurchaseCoinsWeb()
    }
}

