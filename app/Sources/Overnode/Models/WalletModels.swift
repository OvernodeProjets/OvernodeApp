import Foundation

public struct BillingInfo: Codable, Sendable {
    public struct Balances: Codable, Sendable {
        public let creditEur: Double
        public let coins: Int
        
        enum CodingKeys: String, CodingKey {
            case creditEur = "credit_eur"
            case coins
        }
        
        public init(creditEur: Double = 0, coins: Int = 0) {
            self.creditEur = creditEur
            self.coins = coins
        }
    }
    
    public struct CoinPackage: Codable, Identifiable, Sendable {
        public var id: Int { amount }
        public let amount: Int
        public let priceEur: Double
        
        enum CodingKeys: String, CodingKey {
            case amount
            case priceEur = "price_eur"
        }
        
        public init(amount: Int, priceEur: Double) {
            self.amount = amount
            self.priceEur = priceEur
        }
    }
    
    public let balances: Balances?
    public let currency: String?
    public let coinPackages: [CoinPackage]?
    
    enum CodingKeys: String, CodingKey {
        case balances
        case currency
        case coinPackages = "coin_packages"
    }
}

public struct LeaderboardResponse: Codable, Sendable {
    public struct UserEntry: Codable, Identifiable, Sendable {
        public var id: String { "\(rank)-\(username)" }
        public let rank: Int
        public let username: String
        public let coins: Int
        
        public init(rank: Int, username: String, coins: Int) {
            self.rank = rank
            self.username = username
            self.coins = coins
        }
    }
    
    public struct UserRank: Codable, Sendable {
        public let rank: Int
        public let username: String
        public let coins: Int
        public let inTop: Bool?
        
        public init(rank: Int, username: String, coins: Int, inTop: Bool? = nil) {
            self.rank = rank
            self.username = username
            self.coins = coins
            self.inTop = inTop
        }
    }
    
    public let leaderboard: [UserEntry]
    public let userRank: UserRank?
    
    public init(leaderboard: [UserEntry] = [], userRank: UserRank? = nil) {
        self.leaderboard = leaderboard
        self.userRank = userRank
    }
}

public struct BillingTransaction: Codable, Identifiable, Sendable {
    public let id: String
    public let type: String
    public let amount: Double
    public let timestamp: String?
    
    public init(id: String, type: String, amount: Double, timestamp: String? = nil) {
        self.id = id
        self.type = type
        self.amount = amount
        self.timestamp = timestamp
    }
}

public struct TransactionsResponse: Codable, Sendable {
    public let transactions: [BillingTransaction]
}

