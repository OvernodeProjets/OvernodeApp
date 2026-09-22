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
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let intId = try? container.decode(Int.self, forKey: .id) {
            self.id = intId
        } else if let strId = try? container.decode(String.self, forKey: .id) {
            self.id = Int(strId) ?? abs(strId.hashValue)
        } else {
            self.id = 1
        }
        
        self.username = (try? container.decode(String.self, forKey: .username)) ?? "User"
        self.email = (try? container.decode(String.self, forKey: .email)) ?? ""
        self.globalName = try? container.decode(String.self, forKey: .globalName)
        self.role = try? container.decode(String.self, forKey: .role)
        self.avatarUrl = try? container.decode(String.self, forKey: .avatarUrl)
        self.coins = (try? container.decode(Int.self, forKey: .coins)) ?? 0
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
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let intId = try? container.decode(Int.self, forKey: .id) {
                self.id = intId
            } else if let strId = try? container.decode(String.self, forKey: .id) {
                self.id = Int(strId) ?? abs(strId.hashValue)
            } else {
                self.id = 1
            }
            self.username = (try? container.decode(String.self, forKey: .username)) ?? "User"
            self.email = (try? container.decode(String.self, forKey: .email)) ?? ""
            self.globalName = try? container.decode(String.self, forKey: .globalName)
            self.pterodactylEmail = try? container.decode(String.self, forKey: .pterodactylEmail)
        }
    }
    
    public struct RoleItem: Codable {
        public let id: String?
        public let name: String?
    }
    
    public let user: UserPayload?
    public let coins: Int?
    public let admin: Bool?
    public let permissions: [String]?
    public let roles: [String]?
    public let servers: [PteroServerWrapper]?
    
    enum CodingKeys: String, CodingKey {
        case user, coins, admin, permissions, roles, servers
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.user = try? container.decode(UserPayload.self, forKey: .user)
        self.coins = try? container.decode(Int.self, forKey: .coins)
        self.admin = try? container.decode(Bool.self, forKey: .admin)
        self.permissions = try? container.decode([String].self, forKey: .permissions)
        self.servers = try? container.decode([PteroServerWrapper].self, forKey: .servers)
        
        if let strRoles = try? container.decode([String].self, forKey: .roles) {
            self.roles = strRoles
        } else if let objRoles = try? container.decode([RoleItem].self, forKey: .roles) {
            self.roles = objRoles.compactMap { $0.name ?? $0.id }
        } else {
            self.roles = nil
        }
    }
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
