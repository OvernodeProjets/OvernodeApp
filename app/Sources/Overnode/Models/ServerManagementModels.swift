import Foundation

// MARK: - Power Signals
public enum ServerPowerSignal: String, Codable, CaseIterable, Sendable {
    case start = "start"
    case stop = "stop"
    case restart = "restart"
    case kill = "kill"
    
    public var iconName: String {
        switch self {
        case .start: return "play.fill"
        case .stop: return "stop.fill"
        case .restart: return "arrow.clockwise"
        case .kill: return "bolt.slash.fill"
        }
    }
}

// MARK: - Renewal Models
public struct RenewalDurationObject: Codable, Equatable, Sendable {
    public let totalMs: Double?
    public let totalSeconds: Double?
    public let days: Int?
    public let hours: Int?
    public let minutes: Int?
    public let seconds: Int?
    
    public var formatted: String {
        let d = days ?? 0
        let h = hours ?? 0
        let m = minutes ?? 0
        if d > 0 { return "\(d)j \(h)h" }
        if h > 0 { return "\(h)h \(m)min" }
        if m > 0 { return "\(m) min" }
        return "Moins d'une minute"
    }
}

public struct ServerRenewalStatus: Codable, Equatable, Sendable {
    public let isActive: Bool?
    public let nextRenewalAt: String?
    public let lastRenewedAt: String?
    public let canRenew: Bool?
    public let requiresRenewal: Bool?
    public let isExpired: Bool?
    public let timeRemaining: String?
    public let renewalCount: Int?
    public let availableIn: String?
    
    enum CodingKeys: String, CodingKey {
        case isActive, nextRenewalAt, lastRenewedAt, canRenew, requiresRenewal
        case isExpired, timeRemaining, renewalCount, availableIn
    }
    
    public init(
        isActive: Bool? = true,
        nextRenewalAt: String? = nil,
        lastRenewedAt: String? = nil,
        canRenew: Bool? = true,
        requiresRenewal: Bool? = false,
        isExpired: Bool? = false,
        timeRemaining: String? = nil,
        renewalCount: Int? = 0,
        availableIn: String? = nil
    ) {
        self.isActive = isActive
        self.nextRenewalAt = nextRenewalAt
        self.lastRenewedAt = lastRenewedAt
        self.canRenew = canRenew
        self.requiresRenewal = requiresRenewal
        self.isExpired = isExpired
        self.timeRemaining = timeRemaining
        self.renewalCount = renewalCount
        self.availableIn = availableIn
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.isActive = try? c.decode(Bool.self, forKey: .isActive)
        self.nextRenewalAt = try? c.decode(String.self, forKey: .nextRenewalAt)
        self.lastRenewedAt = try? c.decode(String.self, forKey: .lastRenewedAt)
        self.canRenew = try? c.decode(Bool.self, forKey: .canRenew)
        self.requiresRenewal = try? c.decode(Bool.self, forKey: .requiresRenewal)
        self.isExpired = try? c.decode(Bool.self, forKey: .isExpired)
        self.renewalCount = try? c.decode(Int.self, forKey: .renewalCount)
        
        if let str = try? c.decode(String.self, forKey: .timeRemaining) {
            self.timeRemaining = str
        } else if let dur = try? c.decode(RenewalDurationObject.self, forKey: .timeRemaining) {
            self.timeRemaining = dur.formatted
        } else {
            self.timeRemaining = nil
        }
        
        if let str = try? c.decode(String.self, forKey: .availableIn) {
            self.availableIn = str
        } else if let dur = try? c.decode(RenewalDurationObject.self, forKey: .availableIn) {
            self.availableIn = dur.formatted
        } else {
            self.availableIn = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(isActive, forKey: .isActive)
        try c.encodeIfPresent(nextRenewalAt, forKey: .nextRenewalAt)
        try c.encodeIfPresent(lastRenewedAt, forKey: .lastRenewedAt)
        try c.encodeIfPresent(canRenew, forKey: .canRenew)
        try c.encodeIfPresent(requiresRenewal, forKey: .requiresRenewal)
        try c.encodeIfPresent(isExpired, forKey: .isExpired)
        try c.encodeIfPresent(timeRemaining, forKey: .timeRemaining)
        try c.encodeIfPresent(renewalCount, forKey: .renewalCount)
        try c.encodeIfPresent(availableIn, forKey: .availableIn)
    }
}

public struct ServerRenewalActionResponse: Codable, Sendable {
    public let message: String?
    public let restarted: Bool?
    public let renewalData: ServerRenewalStatus?
}

// MARK: - File System Models
public struct ServerFileItem: Codable, Identifiable, Equatable, Sendable {
    public var id: String { name }
    public let name: String
    public let mode: String?
    public let size: Int64
    public let isFile: Bool
    public let isSymlink: Bool
    public let isEditable: Bool
    public let mimetype: String?
    public let modifiedAt: String?
    
    public init(
        name: String,
        mode: String? = nil,
        size: Int64 = 0,
        isFile: Bool = true,
        isSymlink: Bool = false,
        isEditable: Bool = true,
        mimetype: String? = nil,
        modifiedAt: String? = nil
    ) {
        self.name = name
        self.mode = mode
        self.size = size
        self.isFile = isFile
        self.isSymlink = isSymlink
        self.isEditable = isEditable
        self.mimetype = mimetype
        self.modifiedAt = modifiedAt
    }
    
    public var formattedSize: String {
        if !isFile { return "—" }
        if size < 1024 { return "\(size) B" }
        let kb = Double(size) / 1024.0
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024.0
        if mb < 1024 { return String(format: "%.1f MB", mb) }
        let gb = mb / 1024.0
        return String(format: "%.2f GB", gb)
    }
}

// Wrapper for Pterodactyl file list API
public struct PteroFileListResponse: Codable, Sendable {
    public struct FileDatum: Codable, Sendable {
        public struct FileAttributes: Codable, Sendable {
            public let name: String
            public let mode: String?
            public let size: Int64?
            public let isFile: Bool?
            public let isSymlink: Bool?
            public let isEditable: Bool?
            public let mimetype: String?
            public let modifiedAt: String?
            
            enum CodingKeys: String, CodingKey {
                case name, mode, size, mimetype
                case isFile = "is_file"
                case isSymlink = "is_symlink"
                case isEditable = "is_editable"
                case modifiedAt = "modified_at"
            }
        }
        public let attributes: FileAttributes
    }
    public let data: [FileDatum]
}

// MARK: - Subdomain Models
public struct ServerSubdomain: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let serverId: String?
    public let subdomain: String
    public let domainName: String
    public let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, serverId, name, subdomain, domain, domainName, createdAt
    }
    
    public init(id: String, serverId: String? = nil, subdomain: String, domainName: String = "overnode.fr", createdAt: String? = nil) {
        self.id = id
        self.serverId = serverId
        self.subdomain = subdomain
        self.domainName = domainName
        self.createdAt = createdAt
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.serverId = try? c.decode(String.self, forKey: .serverId)
        self.createdAt = try? c.decode(String.self, forKey: .createdAt)
        
        let sub = (try? c.decode(String.self, forKey: .name)) ?? (try? c.decode(String.self, forKey: .subdomain)) ?? ""
        let dom = (try? c.decode(String.self, forKey: .domain)) ?? (try? c.decode(String.self, forKey: .domainName)) ?? "overnode.fr"
        self.subdomain = sub
        self.domainName = dom
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(serverId, forKey: .serverId)
        try c.encode(subdomain, forKey: .subdomain)
        try c.encode(domainName, forKey: .domainName)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
    }
    
    public var fqdn: String {
        if !domainName.isEmpty {
            return "\(subdomain).\(domainName)"
        }
        return subdomain
    }
}

// MARK: - Subuser Models
public struct ServerSubuser: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let uuid: String?
    public let email: String
    public let image: String?
    public let twoFactorEnabled: Bool
    public let permissions: [String]
    
    public init(
        id: String,
        uuid: String? = nil,
        email: String,
        image: String? = nil,
        twoFactorEnabled: Bool = false,
        permissions: [String] = []
    ) {
        self.id = id
        self.uuid = uuid
        self.email = email
        self.image = image
        self.twoFactorEnabled = twoFactorEnabled
        self.permissions = permissions
    }
}

public struct PteroUsersResponse: Codable, Sendable {
    public struct UserDatum: Codable, Sendable {
        public struct Attributes: Codable, Sendable {
            public let id: String?
            public let uuid: String?
            public let email: String
            public let image: String?
            public let twoFactorEnabled: Bool?
            public let permissions: [String]?
            
            enum CodingKeys: String, CodingKey {
                case id, uuid, email, image, permissions
                case twoFactorEnabled = "2fa_enabled"
            }
        }
        public let attributes: Attributes
    }
    public let data: [UserDatum]
}

// MARK: - Activity Log Models
public struct ServerActivityLog: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let timestamp: String
    public let action: String
    public let username: String?
    public let details: String?
}

public struct ActivityLogsResponse: Codable, Sendable {
    public struct RawLog: Codable, Sendable {
        public let id: String
        public let timestamp: String
        public let action: String
        public let username: String?
    }
    public let data: [RawLog]
}

// MARK: - Plugin Models
public struct ServerPluginItem: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let description: String?
    public let iconUrl: String?
    public let version: String?
    public let author: String?
    public let platform: String
    public let downloads: Int?
    public var isInstalled: Bool
}

public struct InstalledPluginsResponse: Codable, Sendable {
    public struct PluginEntry: Codable, Sendable {
        public let id: String
        public let name: String
        public let description: String?
        public let iconUrl: String?
        public let version: String?
        public let author: String?
        public let platform: String?
    }
    public let plugins: [PluginEntry]
}

// MARK: - Startup Variable Models
public struct ServerStartupVariable: Codable, Identifiable, Equatable, Sendable {
    public var id: String { envVariable }
    public let name: String
    public let description: String?
    public let envVariable: String
    public let defaultValue: String?
    public var serverValue: String
    public let isEditable: Bool
    public let rules: String?
    
    public init(
        name: String,
        description: String? = nil,
        envVariable: String,
        defaultValue: String? = nil,
        serverValue: String = "",
        isEditable: Bool = true,
        rules: String? = nil
    ) {
        self.name = name
        self.description = description
        self.envVariable = envVariable
        self.defaultValue = defaultValue
        self.serverValue = serverValue
        self.isEditable = isEditable
        self.rules = rules
    }
}

public struct PteroStartupVariablesResponse: Codable, Sendable {
    public struct VarDatum: Codable, Sendable {
        public struct Attributes: Codable, Sendable {
            public let name: String
            public let description: String?
            public let envVariable: String
            public let defaultValue: String?
            public let serverValue: String?
            public let isEditable: Bool?
            public let rules: String?
            
            enum CodingKeys: String, CodingKey {
                case name, description, rules
                case envVariable = "env_variable"
                case defaultValue = "default_value"
                case serverValue = "server_value"
                case isEditable = "is_editable"
            }
        }
        public let attributes: Attributes
    }
    public let data: [VarDatum]
}
