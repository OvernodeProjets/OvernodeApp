import Foundation
import AppKit

public final class UpdateService: @unchecked Sendable {
    public static let shared = UpdateService()
    
    // Hardcoded production updater URL provided by Overnode
    public static let defaultUpdaterURLString = "https://zBvoGzjDABxGuLuKux59LtECbKIpNPcp.overnode.fr"
    
    public var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    public var updaterBaseURL: URL {
        if let envUrl = ProcessInfo.processInfo.environment["OVERNODE_UPDATER_URL"],
           let url = URL(string: envUrl) {
            return url
        }
        return URL(string: Self.defaultUpdaterURLString)!
    }
    
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func checkForUpdates(version: String? = nil) async throws -> UpdateCheckResponse {
        let ver = version ?? currentAppVersion
        let platform = "darwin-arm64"
        
        var comp = URLComponents(url: updaterBaseURL.appendingPathComponent("api/v1/update/check"), resolvingAgainstBaseURL: false)
        comp?.queryItems = [
            URLQueryItem(name: "version", value: ver),
            URLQueryItem(name: "platform", value: platform)
        ]
        
        guard let finalURL = comp?.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 8
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Overnode-Updater-Client/\(ver)", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            return try JSONDecoder().decode(UpdateCheckResponse.self, from: data)
        } catch {
            // Fallback in demo/snapshot test mode
            if ProcessInfo.processInfo.environment["OVERNODE_DEMO"] != nil {
                return UpdateCheckResponse(
                    updateAvailable: true,
                    clientVersion: ver,
                    latestVersion: "1.1.0",
                    downloadUrl: "https://github.com/overnode-network/OvernodeApp/releases/download/v1.1.0/Overnode-v1.1.0-macOS-arm64.zip",
                    releaseNotes: "• Système de mise à jour automatique en temps réel\n• Optimisations des performances pour Apple Silicon\n• Corrections de bugs et améliorations de stabilité",
                    mandatory: false
                )
            }
            throw error
        }
    }
    
    public func downloadUpdate(
        from urlString: String,
        onProgress: @Sendable @escaping (Double) -> Void
    ) async throws -> URL {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let destinationFile = tempDir.appendingPathComponent("Overnode-Update.zip")
        
        let (bytes, response) = try await session.bytes(from: url)
        let totalBytes = response.expectedContentLength
        var receivedBytes: Int64 = 0
        
        var fileData = Data()
        fileData.reserveCapacity(totalBytes > 0 ? Int(totalBytes) : 10_000_000)
        
        for try await byte in bytes {
            fileData.append(byte)
            receivedBytes += 1
            if totalBytes > 0 && receivedBytes % 32768 == 0 {
                let progress = Double(receivedBytes) / Double(totalBytes)
                onProgress(progress)
            }
        }
        
        onProgress(1.0)
        try fileData.write(to: destinationFile)
        return destinationFile
    }
    
    public func launchInstallerAndRestart(archiveURL: URL) throws {
        let appBundlePath = Bundle.main.bundlePath
        let pid = ProcessInfo.processInfo.processIdentifier
        
        let scriptPath = FileManager.default.temporaryDirectory.appendingPathComponent("overnode_updater_\(pid).sh")
        let script = """
        #!/bin/bash
        set -e
        # Wait for old app process to terminate
        while kill -0 \(pid) 2>/dev/null; do
            sleep 0.3
        done
        
        TMP_EXTRACT=$(mktemp -d /tmp/overnode_unpack.XXXXXX)
        ditto -x -k "\(archiveURL.path)" "$TMP_EXTRACT"
        
        NEW_APP="$TMP_EXTRACT/Overnode.app"
        if [ ! -d "$NEW_APP" ]; then
            NEW_APP=$(find "$TMP_EXTRACT" -name "Overnode.app" -type d | head -n 1)
        fi
        
        if [ -n "$NEW_APP" ] && [ -d "$NEW_APP" ]; then
            xattr -cr "$NEW_APP" 2>/dev/null || true
            rm -rf "\(appBundlePath)"
            cp -R "$NEW_APP" "\(appBundlePath)"
            rm -rf "$TMP_EXTRACT" "\(archiveURL.path)"
            open -n -a "\(appBundlePath)"
        fi
        rm -f "$0"
        """
        
        try script.write(to: scriptPath, atomically: true, encoding: .utf8)
        
        let chmodTask = Process()
        chmodTask.launchPath = "/bin/chmod"
        chmodTask.arguments = ["+x", scriptPath.path]
        try chmodTask.run()
        chmodTask.waitUntilExit()
        
        let updateTask = Process()
        updateTask.launchPath = "/bin/bash"
        updateTask.arguments = [scriptPath.path]
        try updateTask.run()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NSApplication.shared.terminate(nil)
        }
    }
}

