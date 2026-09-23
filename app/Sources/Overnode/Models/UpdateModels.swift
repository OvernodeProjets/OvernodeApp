import Foundation

public struct UpdateCheckResponse: Codable, Sendable, Equatable {
    public let updateAvailable: Bool
    public let clientVersion: String
    public let latestVersion: String
    public let downloadUrl: String
    public let releaseNotes: String
    public let mandatory: Bool
    public let sha256: String?
    public let publishedAt: String?
    
    public init(
        updateAvailable: Bool,
        clientVersion: String,
        latestVersion: String,
        downloadUrl: String,
        releaseNotes: String,
        mandatory: Bool = false,
        sha256: String? = nil,
        publishedAt: String? = nil
    ) {
        self.updateAvailable = updateAvailable
        self.clientVersion = clientVersion
        self.latestVersion = latestVersion
        self.downloadUrl = downloadUrl
        self.releaseNotes = releaseNotes
        self.mandatory = mandatory
        self.sha256 = sha256
        self.publishedAt = publishedAt
    }
}

public enum UpdateState: Equatable, Sendable {
    case idle
    case checking
    case upToDate(currentVersion: String)
    case available(UpdateCheckResponse)
    case downloading(progress: Double)
    case readyToRestart
    case failed(String)
}

