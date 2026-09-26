import Foundation
import AppKit
import UniformTypeIdentifiers

/// Manages external text/code editor configuration, file staging, and auto-syncing of changes.
public final class ExternalEditorManager: @unchecked Sendable {
    public static let shared = ExternalEditorManager()
    
    private let keyAlwaysOpen = "overnode_always_open_external_editor"
    private let keyEditorAppPath = "overnode_external_editor_app_path"
    private let keyEditorAppName = "overnode_external_editor_app_name"
    
    public static let didChangeNotification = Notification.Name("overnode_external_editor_changed")
    public static let fileDidSyncNotification = Notification.Name("overnode_external_editor_file_synced")
    
    private let sessionQueue = DispatchQueue(label: "fr.overnode.external-editor-sessions")
    private var activeSessions: [String: ExternalEditSession] = [:]
    
    private init() {}
    
    // MARK: - Settings Properties
    
    public var alwaysOpenInExternalEditor: Bool {
        get {
            UserDefaults.standard.bool(forKey: keyAlwaysOpen)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyAlwaysOpen)
            NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
        }
    }
    
    public var selectedEditorAppPath: String? {
        get {
            let path = UserDefaults.standard.string(forKey: keyEditorAppPath)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return (path?.isEmpty ?? true) ? nil : path
        }
        set {
            if let p = newValue?.trimmingCharacters(in: .whitespacesAndNewlines), !p.isEmpty {
                UserDefaults.standard.set(p, forKey: keyEditorAppPath)
                let url = URL(fileURLWithPath: p)
                let name = Bundle(url: url)?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                    ?? Bundle(url: url)?.object(forInfoDictionaryKey: "CFBundleName") as? String
                    ?? FileManager.default.displayName(atPath: p)
                UserDefaults.standard.set(name, forKey: keyEditorAppName)
            } else {
                UserDefaults.standard.removeObject(forKey: keyEditorAppPath)
                UserDefaults.standard.removeObject(forKey: keyEditorAppName)
            }
            NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
        }
    }
    
    public var selectedEditorAppName: String? {
        UserDefaults.standard.string(forKey: keyEditorAppName)
    }
    
    public var selectedEditorAppURL: URL? {
        guard let path = selectedEditorAppPath, FileManager.default.fileExists(atPath: path) else {
            return nil
        }
        return URL(fileURLWithPath: path)
    }
    
    public var selectedEditorAppIcon: NSImage? {
        guard let path = selectedEditorAppPath else { return nil }
        return NSWorkspace.shared.icon(forFile: path)
    }
    
    public func resetEditor() {
        selectedEditorAppPath = nil
    }
    
    // MARK: - Editor Picker Dialog
    
    @MainActor
    public func promptUserToSelectEditor() -> URL? {
        let panel = NSOpenPanel()
        panel.title = LocalizationManager.shared.string("settings_external_editor_picker_title")
        panel.message = LocalizationManager.shared.string("settings_external_editor_picker_message")
        panel.prompt = LocalizationManager.shared.string("generic_select")
        panel.allowedContentTypes = [UTType.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.resolvesAliases = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        
        let response = panel.runModal()
        guard response == .OK, let appURL = panel.url else {
            return nil
        }
        
        selectedEditorAppPath = appURL.path
        return appURL
    }
    
    // MARK: - Open & Watch File
    
    public func openAndWatch(
        serverId: String,
        remotePath: String,
        fileName: String,
        initialContent: String,
        editorURL: URL? = nil,
        onSave: @escaping @Sendable (String) async throws -> Void
    ) async throws -> URL {
        // Resolve application
        let targetAppURL: URL
        if let explicit = editorURL {
            targetAppURL = explicit
        } else if let saved = selectedEditorAppURL {
            targetAppURL = saved
        } else {
            let chosen = await promptUserToSelectEditor()
            guard let chosenApp = chosen else {
                throw NSError(domain: "ExternalEditorManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "No editor selected"])
            }
            targetAppURL = chosenApp
        }
        
        // Prepare local directory
        let baseDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("OvernodeExternalEdits", isDirectory: true)
            .appendingPathComponent(serverId, isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        
        try FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
        
        let localFileURL = baseDir.appendingPathComponent(fileName)
        let data = initialContent.data(using: .utf8) ?? Data()
        try data.write(to: localFileURL, options: .atomic)
        
        // Setup monitoring session
        let sessionKey = "\(serverId):\(remotePath)"
        let session = ExternalEditSession(
            serverId: serverId,
            remotePath: remotePath,
            fileName: fileName,
            localFileURL: localFileURL,
            initialContent: initialContent,
            onSave: onSave
        )
        
        storeSession(key: sessionKey, session: session)
        session.startWatching()
        
        // Open file with selected editor
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        do {
            _ = try await NSWorkspace.shared.open([localFileURL], withApplicationAt: targetAppURL, configuration: config)
        } catch {
            print("[ExternalEditorManager] Failed to launch editor: \(error.localizedDescription)")
        }
        
        return localFileURL
    }
    
    private func storeSession(key: String, session: ExternalEditSession) {
        sessionQueue.sync {
            activeSessions[key]?.stop()
            activeSessions[key] = session
        }
    }
    
    public func stopWatching(serverId: String, remotePath: String) {
        let key = "\(serverId):\(remotePath)"
        let session = sessionQueue.sync {
            activeSessions.removeValue(forKey: key)
        }
        session?.stop()
    }
    
    // MARK: - Auto-Cleanup & Storage Security
    
    public var temporaryDirectoryURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("OvernodeExternalEdits", isDirectory: true)
    }
    
    /// Purges all staged temporary files and terminates watchers (e.g. on application exit).
    public func purgeAllTemporaryFiles() {
        sessionQueue.sync {
            for (_, session) in activeSessions {
                session.stop()
            }
            activeSessions.removeAll()
        }
        
        let dir = temporaryDirectoryURL
        if FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.removeItem(at: dir)
            print("[ExternalEditorManager] Purged temporary external edit files.")
        }
    }
    
    /// Cleans up stale edit sessions and temporary folders older than maxAgeSeconds (default 1 hour).
    public func cleanupStaleTemporaryFiles(maxAgeSeconds: TimeInterval = 3600) {
        let dir = temporaryDirectoryURL
        guard FileManager.default.fileExists(atPath: dir.path) else { return }
        
        let thresholdDate = Date().addingTimeInterval(-maxAgeSeconds)
        let fileManager = FileManager.default
        
        guard let serverDirs = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles) else {
            return
        }
        
        for serverDir in serverDirs {
            guard let editUUIDDirs = try? fileManager.contentsOfDirectory(at: serverDir, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles) else {
                continue
            }
            for editDir in editUUIDDirs {
                let attrs = try? fileManager.attributesOfItem(atPath: editDir.path)
                if let modDate = attrs?[.modificationDate] as? Date, modDate < thresholdDate {
                    try? fileManager.removeItem(at: editDir)
                    print("[ExternalEditorManager] Cleaned up stale edit directory: \(editDir.lastPathComponent)")
                }
            }
            if let remaining = try? fileManager.contentsOfDirectory(atPath: serverDir.path), remaining.isEmpty {
                try? fileManager.removeItem(at: serverDir)
            }
        }
    }
    
    /// Schedules periodic background cleanup every 15 minutes.
    public func startPeriodicCleanup(intervalSeconds: TimeInterval = 900) {
        DispatchQueue.main.async { [weak self] in
            Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { [weak self] _ in
                self?.cleanupStaleTemporaryFiles()
            }
        }
    }
}

// MARK: - External Edit Session & Watcher

private final class ExternalEditSession: @unchecked Sendable {
    let serverId: String
    let remotePath: String
    let fileName: String
    let localFileURL: URL
    private var lastKnownContent: String
    private var lastModificationDate: Date?
    private let onSave: @Sendable (String) async throws -> Void
    
    private var timer: Timer?
    private var isSaving = false
    
    init(
        serverId: String,
        remotePath: String,
        fileName: String,
        localFileURL: URL,
        initialContent: String,
        onSave: @escaping @Sendable (String) async throws -> Void
    ) {
        self.serverId = serverId
        self.remotePath = remotePath
        self.fileName = fileName
        self.localFileURL = localFileURL
        self.lastKnownContent = initialContent
        self.onSave = onSave
        self.lastModificationDate = try? FileManager.default.attributesOfItem(atPath: localFileURL.path)[.modificationDate] as? Date
    }
    
    func startWatching() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.checkForModifications()
            }
        }
    }
    
    func stop() {
        DispatchQueue.main.async { [weak self] in
            self?.timer?.invalidate()
            self?.timer = nil
        }
    }
    
    private func checkForModifications() {
        guard FileManager.default.fileExists(atPath: localFileURL.path) else { return }
        
        let attrs = try? FileManager.default.attributesOfItem(atPath: localFileURL.path)
        guard let modDate = attrs?[.modificationDate] as? Date else { return }
        
        if let lastMod = lastModificationDate, modDate <= lastMod {
            return
        }
        
        guard let rawData = try? Data(contentsOf: localFileURL),
              let currentContent = String(data: rawData, encoding: .utf8) else {
            return
        }
        
        if currentContent == lastKnownContent || isSaving {
            return
        }
        
        isSaving = true
        lastKnownContent = currentContent
        lastModificationDate = modDate
        
        Task { [weak self, fileName = self.fileName] in
            guard let self = self else { return }
            do {
                try await self.onSave(currentContent)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: ExternalEditorManager.fileDidSyncNotification,
                        object: nil,
                        userInfo: ["fileName": fileName]
                    )
                }
            } catch {
                print("[ExternalEditorManager] Failed to auto-save \(fileName): \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                self.isSaving = false
            }
        }
    }
}
