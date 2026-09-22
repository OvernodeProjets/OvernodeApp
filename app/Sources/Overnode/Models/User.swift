import Foundation

public struct User: Codable, Identifiable, Equatable, Sendable {
    public let id: String
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
        id: String,
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
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let idStr = try? c.decode(String.self, forKey: .id) {
            self.id = idStr
        } else if let idInt = try? c.decode(Int.self, forKey: .id) {
            self.id = String(idInt)
        } else {
            self.id = UUID().uuidString
        }
        self.username = (try? c.decode(String.self, forKey: .username)) ?? "User"
        self.email = (try? c.decode(String.self, forKey: .email)) ?? ""
        self.globalName = try? c.decode(String.self, forKey: .globalName)
        self.role = try? c.decode(String.self, forKey: .role)
        self.avatarUrl = try? c.decode(String.self, forKey: .avatarUrl)
        self.coins = (try? c.decode(Int.self, forKey: .coins)) ?? 0
    }
}

public struct InitResponse: Codable, Sendable {
    public struct UserPayload: Codable, Sendable {
        public let id: String
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
        
        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            if let idStr = try? c.decode(String.self, forKey: .id) {
                self.id = idStr
            } else if let idInt = try? c.decode(Int.self, forKey: .id) {
                self.id = String(idInt)
            } else {
                self.id = UUID().uuidString
            }
            self.username = (try? c.decode(String.self, forKey: .username)) ?? "User"
            self.email = (try? c.decode(String.self, forKey: .email)) ?? ""
            self.globalName = try? c.decode(String.self, forKey: .globalName)
            self.pterodactylEmail = try? c.decode(String.self, forKey: .pterodactylEmail)
        }
    }
    
    public struct RolePayload: Codable, Sendable {
        public let id: String?
        public let name: String?
        public let color: String?
    }
    
    public let user: UserPayload?
    public let coins: Int?
    public let admin: Bool?
    public let permissions: [String]?
    public let roles: [RolePayload]?
    public let servers: [PteroServerWrapper]?
}

public struct AuthStateResponse: Codable, Sendable {
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

