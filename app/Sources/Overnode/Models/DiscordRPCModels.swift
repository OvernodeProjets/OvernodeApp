import Foundation

public enum DiscordOpcode: UInt32 {
    case handshake = 0
    case frame = 1
    case close = 2
    case ping = 3
    case pong = 4
}

public struct DiscordHandshake: Codable, Equatable {
    public let v: Int
    public let clientId: String
    
    public enum CodingKeys: String, CodingKey {
        case v
        case clientId = "client_id"
    }
    
    public init(v: Int = 1, clientId: String) {
        self.v = v
        self.clientId = clientId
    }
}

public struct DiscordButton: Codable, Equatable {
    public let label: String
    public let url: String
    
    public init(label: String, url: String) {
        self.label = label
        self.url = url
    }
}

public struct DiscordTimestamps: Codable, Equatable {
    public let start: Int?
    public let end: Int?
    
    public init(start: Int? = nil, end: Int? = nil) {
        self.start = start
        self.end = end
    }
}

public struct DiscordAssets: Codable, Equatable {
    public let largeImage: String?
    public let largeText: String?
    public let smallImage: String?
    public let smallText: String?
    
    public enum CodingKeys: String, CodingKey {
        case largeImage = "large_image"
        case largeText = "large_text"
        case smallImage = "small_image"
        case smallText = "small_text"
    }
    
    public init(largeImage: String? = nil, largeText: String? = nil, smallImage: String? = nil, smallText: String? = nil) {
        self.largeImage = largeImage
        self.largeText = largeText
        self.smallImage = smallImage
        self.smallText = smallText
    }
}

public struct DiscordActivity: Codable, Equatable {
    public let details: String?
    public let state: String?
    public let assets: DiscordAssets?
    public let timestamps: DiscordTimestamps?
    public let buttons: [DiscordButton]?
    
    public init(
        details: String? = nil,
        state: String? = nil,
        assets: DiscordAssets? = nil,
        timestamps: DiscordTimestamps? = nil,
        buttons: [DiscordButton]? = nil
    ) {
        self.details = details
        self.state = state
        self.assets = assets
        self.timestamps = timestamps
        self.buttons = buttons
    }
}

public struct DiscordActivityArgs: Codable {
    public let pid: Int
    public let activity: DiscordActivity?
    
    public init(pid: Int, activity: DiscordActivity?) {
        self.pid = pid
        self.activity = activity
    }
}

public struct DiscordSetActivityFrame: Codable {
    public let cmd: String
    public let args: DiscordActivityArgs
    public let nonce: String
    
    public init(pid: Int, activity: DiscordActivity?, nonce: String = UUID().uuidString) {
        self.cmd = "SET_ACTIVITY"
        self.args = DiscordActivityArgs(pid: pid, activity: activity)
        self.nonce = nonce
    }
}

public struct DiscordResponseFrame: Codable {
    public let cmd: String?
    public let evt: String?
    public let nonce: String?
}
