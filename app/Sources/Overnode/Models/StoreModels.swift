import Foundation

public struct StoreConfigResponse: Codable, Sendable {
    public struct Prices: Codable, Sendable {
        public let resources: [String: Int]?
    }
    
    public let prices: Prices?
    public let multipliers: [String: Int]?
    public let limits: [String: Int]?
    public let userBalance: Int?
    public let canAfford: [String: Bool]?
    
    public init(
        prices: Prices? = nil,
        multipliers: [String: Int]? = nil,
        limits: [String: Int]? = nil,
        userBalance: Int? = 0,
        canAfford: [String: Bool]? = nil
    ) {
        self.prices = prices
        self.multipliers = multipliers
        self.limits = limits
        self.userBalance = userBalance
        self.canAfford = canAfford
    }
}

public struct StoreBuyPayload: Codable, Sendable {
    public let resourceType: String
    public let amount: Int
    
    public init(resourceType: String, amount: Int) {
        self.resourceType = resourceType
        self.amount = amount
    }
}

public struct StoreBuyResponse: Codable, Sendable {
    public let success: Bool
    public let remainingCoins: Int?
    public let resources: StoreUpdatedResources?
    
    public struct StoreUpdatedResources: Codable, Sendable {
        public let ram: Double?
        public let disk: Double?
        public let cpu: Double?
        public let servers: Int?
    }
}

public struct StoreBundle: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let price: String
    public let period: String
    public let description: String
    public let features: [String]
    public let iconName: String
    public let iconColor: String
    
    public init(
        id: String,
        title: String,
        price: String,
        period: String,
        description: String,
        features: [String],
        iconName: String,
        iconColor: String
    ) {
        self.id = id
        self.title = title
        self.price = price
        self.period = period
        self.description = description
        self.features = features
        self.iconName = iconName
        self.iconColor = iconColor
    }
}

