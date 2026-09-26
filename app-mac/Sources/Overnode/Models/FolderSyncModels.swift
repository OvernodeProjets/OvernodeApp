import Foundation

/// Configuration representing a synced folder pairing between a remote server path and local Mac folder.
public struct SyncedFolderConfig: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let serverId: String
    public let remotePath: String
    public let localPath: String
    public var isEnabled: Bool
    public var lastSyncDate: Date?
    
    public init(
        id: String = UUID().uuidString,
        serverId: String,
        remotePath: String,
        localPath: String,
        isEnabled: Bool = true,
        lastSyncDate: Date? = nil
    ) {
        self.id = id
        self.serverId = serverId
        self.remotePath = remotePath
        self.localPath = localPath
        self.isEnabled = isEnabled
        self.lastSyncDate = lastSyncDate
    }
    
    public var folderName: String {
        (remotePath as NSString).lastPathComponent
    }
    
    public var localURL: URL {
        URL(fileURLWithPath: localPath)
    }
}

/// In-memory snapshot of a local file or directory used for efficient diffing.
public struct LocalFileRecord: Codable, Equatable, Sendable {
    public let relativePath: String
    public let modificationDate: Date
    public let size: Int64
    public let isDirectory: Bool
    
    public init(relativePath: String, modificationDate: Date, size: Int64, isDirectory: Bool) {
        self.relativePath = relativePath
        self.modificationDate = modificationDate
        self.size = size
        self.isDirectory = isDirectory
    }
}

/// Status of the folder synchronization process.
public enum FolderSyncStatus: Equatable, Sendable {
    case idle
    case syncing(message: String)
    case success(count: Int)
    case error(message: String)
}
