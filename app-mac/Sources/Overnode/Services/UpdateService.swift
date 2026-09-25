import Foundation
import AppKit
import CryptoKit

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
        expectedSHA256: String? = nil,
        onProgress: @Sendable @escaping (Double) -> Void
    ) async throws -> URL {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let ext = url.pathExtension.lowercased()
        let filename = (ext == "dmg" || ext == "zip") ? "Overnode-Update.\(ext)" : "Overnode-Update.dmg"
        let destinationFile = tempDir.appendingPathComponent(filename)
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 60
        request.setValue("Overnode-Updater-Client/\(currentAppVersion)", forHTTPHeaderField: "User-Agent")
        
        let (bytes, response) = try await session.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(
                domain: "OvernodeUpdater",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Erreur HTTP \(httpResponse.statusCode) lors du téléchargement de la mise à jour."]
            )
        }
        
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
        
        guard fileData.count > 100_000 else {
            throw NSError(
                domain: "OvernodeUpdater",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Fichier de mise à jour incomplet ou corrompu (taille: \(fileData.count) octets)."]
            )
        }
        
        onProgress(1.0)
        try fileData.write(to: destinationFile)
        
        // SECURITY: Verify SHA-256 integrity if server provided a hash
        if let expectedHash = expectedSHA256, !expectedHash.isEmpty {
            let computedHash = SHA256.hash(data: fileData)
            let computedHex = computedHash.compactMap { String(format: "%02x", $0) }.joined()
            let normalizedExpected = expectedHash.lowercased().trimmingCharacters(in: .whitespaces)
            if computedHex != normalizedExpected {
                try? FileManager.default.removeItem(at: destinationFile)
                throw NSError(
                    domain: "OvernodeUpdater",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "Vérification d'intégrité échouée. Le hash SHA-256 du fichier ne correspond pas (attendu: \(normalizedExpected.prefix(16))…, obtenu: \(computedHex.prefix(16))…)."]
                )
            }
        }
        
        return destinationFile
    }
    
    /// Shell-escape a path for safe inclusion inside single-quoted bash strings
    private func shellEscape(_ path: String) -> String {
        return path.replacingOccurrences(of: "'", with: "'\''")
    }
    
    public func launchInstallerAndRestart(archiveURL: URL) throws {
        let appBundlePath = shellEscape(Bundle.main.bundlePath)
        let archivePath = shellEscape(archiveURL.path)
        let pid = ProcessInfo.processInfo.processIdentifier
        
        let logPath = "/tmp/overnode_updater.log"
        let scriptPath = FileManager.default.temporaryDirectory.appendingPathComponent("overnode_updater_\(pid).sh")
        // SECURITY: Paths are injected via single-quoted shell variables to prevent injection
        let script = """
        #!/bin/bash
        exec >> "\(logPath)" 2>&1
        
        APP_BUNDLE='\(appBundlePath)'
        ARCHIVE_PATH='\(archivePath)'
        APP_PID=\(pid)
        
        echo "================================================="
        echo "🚀 Overnode Updater started at $(date)"
        echo "Target App Bundle: $APP_BUNDLE"
        echo "Parent App PID: $APP_PID"
        echo "Archive: $ARCHIVE_PATH"
        echo "================================================="

        # 1. Wait for old app process to terminate
        echo "Waiting for PID $APP_PID to terminate..."
        for i in {1..50}; do
            if ! kill -0 $APP_PID 2>/dev/null; then
                echo "✓ Old application terminated."
                break
            fi
            sleep 0.2
        done
        sleep 0.5

        # 2. Extract archive (DMG or ZIP)
        TMP_EXTRACT=$(mktemp -d /tmp/overnode_unpack.XXXXXX)
        ARCHIVE="$ARCHIVE_PATH"
        FILE_TYPE=$(file -b "$ARCHIVE" 2>/dev/null || true)
        echo "Unpacking into: $TMP_EXTRACT"
        echo "Archive file type: $FILE_TYPE"

        if [[ "$ARCHIVE" == *.dmg ]] || [[ "$FILE_TYPE" == *"disk image"* ]] || [[ "$FILE_TYPE" == *"zlib"* ]] || [[ "$FILE_TYPE" == *"Apple"* ]] || [[ "$FILE_TYPE" == *"UDIF"* ]]; then
            echo "Mounting disk image: $ARCHIVE"
            TMP_MOUNT=$(mktemp -d /tmp/overnode_mount.XXXXXX)
            hdiutil attach -nobrowse -readonly "$ARCHIVE" -mountpoint "$TMP_MOUNT"
            
            FOUND_APP=$(find "$TMP_MOUNT" -maxdepth 2 -name "Overnode.app" -type d | head -n 1)
            if [ -n "$FOUND_APP" ] && [ -d "$FOUND_APP" ]; then
                echo "Found app in mount: $FOUND_APP"
                cp -R "$FOUND_APP" "$TMP_EXTRACT/Overnode.app"
            else
                echo "ERROR: Overnode.app not found inside DMG mount!"
            fi
            hdiutil detach "$TMP_MOUNT" -force 2>/dev/null || true
            rmdir "$TMP_MOUNT" 2>/dev/null || true
        else
            echo "Extracting zip archive with ditto..."
            ditto -x -k "$ARCHIVE" "$TMP_EXTRACT"
        fi

        # 3. Locate and validate new app
        NEW_APP="$TMP_EXTRACT/Overnode.app"
        if [ ! -d "$NEW_APP" ]; then
            NEW_APP=$(find "$TMP_EXTRACT" -name "Overnode.app" -type d | head -n 1)
        fi

        if [ -z "$NEW_APP" ] || [ ! -d "$NEW_APP" ]; then
            echo "ERROR: Overnode.app was not found in $TMP_EXTRACT. Aborting."
            rm -rf "$TMP_EXTRACT" "$ARCHIVE_PATH"
            exit 1
        fi

        EXEC_BIN=$(find "$NEW_APP/Contents/MacOS" -type f 2>/dev/null | head -n 1)
        if [ -z "$EXEC_BIN" ] || [ ! -f "$EXEC_BIN" ]; then
            echo "ERROR: No executable found inside $NEW_APP/Contents/MacOS. Aborting."
            rm -rf "$TMP_EXTRACT" "$ARCHIVE_PATH"
            exit 1
        fi

        chmod +x "$EXEC_BIN"
        xattr -cr "$NEW_APP" 2>/dev/null || true
        echo "✓ New app validated: $NEW_APP (binary: $EXEC_BIN)"

        # 4. Safely swap old app bundle with new app bundle
        BACKUP_APP="/tmp/Overnode_Backup_$APP_PID"
        rm -rf "$BACKUP_APP"
        if [ -d "$APP_BUNDLE" ]; then
            echo "Backing up current app to $BACKUP_APP"
            mv "$APP_BUNDLE" "$BACKUP_APP"
        fi

        mkdir -p "$(dirname "$APP_BUNDLE")"
        echo "Installing new app to $APP_BUNDLE..."
        if cp -R "$NEW_APP" "$APP_BUNDLE"; then
            echo "✓ Installation successful. Cleaning backup..."
            dot_clean "$APP_BUNDLE" 2>/dev/null || true
            xattr -cr "$APP_BUNDLE" 2>/dev/null || true
            rm -rf "$BACKUP_APP"
        else
            echo "ERROR: Failed to copy new app. Restoring previous version..."
            if [ -d "$BACKUP_APP" ]; then
                mv "$BACKUP_APP" "$APP_BUNDLE"
            fi
            exit 1
        fi

        # Clean extraction files
        rm -rf "$TMP_EXTRACT" "$ARCHIVE_PATH"

        # 5. Refresh LaunchServices and relaunch app
        touch "$APP_BUNDLE"
        echo "Relaunching application at: $APP_BUNDLE..."
        open -n "$APP_BUNDLE"
        echo "✓ Application relaunched successfully!"
        rm -f "$0"
        """
        
        try script.write(to: scriptPath, atomically: true, encoding: .utf8)
        
        let chmodTask = Process()
        chmodTask.launchPath = "/bin/chmod"
        chmodTask.arguments = ["+x", scriptPath.path]
        try chmodTask.run()
        chmodTask.waitUntilExit()
        
        let updateTask = Process()
        updateTask.launchPath = "/usr/bin/nohup"
        updateTask.arguments = ["/bin/bash", scriptPath.path]
        updateTask.standardInput = FileHandle.nullDevice
        updateTask.standardOutput = FileHandle.nullDevice
        updateTask.standardError = FileHandle.nullDevice
        try updateTask.run()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NSApplication.shared.terminate(nil)
        }
    }
}
