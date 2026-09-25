import Foundation
import AppKit

public final class BillingService: @unchecked Sendable {
    public static let shared = BillingService()
    private let client = APIClient.shared
    
    private init() {}
    
    public func fetchBillingInfo() async throws -> BillingInfo {
        return try await client.request(endpoint: "/api/v5/billing/info")
    }
    
    public func fetchLeaderboard() async throws -> LeaderboardResponse {
        return try await client.request(endpoint: "/api/v5/billing/leaderboard")
    }
    
    public func fetchTransactions() async throws -> [BillingTransaction] {
        do {
            let res: TransactionsResponse = try await client.request(endpoint: "/api/v5/billing/transactions")
            return res.transactions
        } catch {
            return []
        }
    }
    
    public func openAddFundsWeb() {
        if let url = URL(string: "https://console.overnode.fr/wallet") {
            NSWorkspace.shared.open(url)
        }
    }
    
    public func openPurchaseCoinsWeb() {
        if let url = URL(string: "https://console.overnode.fr/wallet") {
            NSWorkspace.shared.open(url)
        }
    }
}

