import Foundation

public struct User: Codable, Identifiable, Equatable {
    public let id: Int
    public let username: String
    public let email: String
    public let role: String?
    public let avatarUrl: String?
    
    public init(id: Int, username: String, email: String, role: String? = nil, avatarUrl: String? = nil) {
        self.id = id
        self.username = username
        self.email = email
        self.role = role
        self.avatarUrl = avatarUrl
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
