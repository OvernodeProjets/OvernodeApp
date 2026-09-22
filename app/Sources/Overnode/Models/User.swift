import Foundation

public struct User: Codable, Identifiable, Equatable {
    public let id: Int
    public let username: String
    public let email: String
    public let globalName: String?
    public let role: String?
    public let avatarUrl: String?
    public var coins: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case globalName = "global_name"
        case role
        case avatarUrl
        case coins
    }
    
    public init(
        id: Int,
        username: String,
        email: String,
        globalName: String? = nil,
        role: String? = nil,
        avatarUrl: String? = nil,
        coins: Int = 0
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.globalName = globalName
        self.role = role
        self.avatarUrl = avatarUrl
        self.coins = coins
    }
}

public struct InitResponse: Codable {
    public struct UserPayload: Codable {
        public let id: Int
        public let username: String
        public let email: String
        public let globalName: String?
        public let pterodactylEmail: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case username
            case email
            case globalName = "global_name"
            case pterodactylEmail
        }
    }
    
    public let user: UserPayload?
    public let coins: Int?
    public let admin: Bool?
    public let permissions: [String]?
    public let roles: [String]?
    public let servers: [PteroServerWrapper]?
}

public struct AuthStateResponse: Codable {
    public let authenticated: Bool
    public let twoFactorPending: Bool?
    public let twoFactorEnabled: Bool?
    public let banned: Bool?
    public let admin: Bool?
    public let user: User?
    public let siteName: String?
    
    enum CodingKeys: String, CodingKey {
        case authenticated
        case twoFactorPending
        case twoFactorEnabled
        case banned
        case admin
        case user
        case siteName = "site_name"
    }
}
