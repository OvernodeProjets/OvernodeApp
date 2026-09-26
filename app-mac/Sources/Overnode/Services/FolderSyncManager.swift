import Foundation
import AppKit

/// Central manager orchestrating real-time folder synchronization between local Mac directories and remote server paths.
public final class FolderSyncManager: @unchecked Sendable {
    public static let shared = FolderSyncManager()
    
    private let storageKey = "overnode_synced_folders"
    public static let didChangeNotification = Notification.Name("overnode_synced_folders_changed")
    public static let didSyncChangesNotification = Notification.Name("overnode_folder_sync_completed")
    
    private let syncQueue = DispatchQueue(label: "fr.overnode.folder-sync", qos: .utility)
    private var configs: [String: SyncedFolderConfig] = [:]
    private var watchers: [String: FolderWatcher] = [:]
    private var snapshots: [String: [String: LocalFileRecord]] = [:]
    private var debounceTasks: [String: Task<Void, Never>] = [:]
    private var activeSyncs: Set<String> = []
    private var internalDownloads: Set<String> = []
    
    private init() {
        loadConfigs()
    }
    
    public var allConfigs: [SyncedFolderConfig] {
        syncQueue.sync { Array(configs.values) }
    }
    
    public func isFolderSynced(serverId: String, remotePath: String) -> Bool {
        let norm = normalize(remotePath)
        return syncQueue.sync {
            configs.values.contains { $0.serverId == serverId && normalize($0.remotePath) == norm && $0.isEnabled }
        }
    }
    
    public func configFor(serverId: String, remotePath: String) -> SyncedFolderConfig? {
        let norm = normalize(remotePath)
        return syncQueue.sync {
            configs.values.first { $0.serverId == serverId && normalize($0.remotePath) == norm }
        }
    }
    
    public func registerSyncedFolder(
        serverId: String,
        remotePath: String,
        localURL: URL,
        initialPull: Bool = true
    ) async throws -> SyncedFolderConfig {
        let norm = normalize(remotePath)
        let config = SyncedFolderConfig(serverId: serverId, remotePath: norm, localPath: localURL.path)
        try FileManager.default.createDirectory(at: localURL, withIntermediateDirectories: true)
        
        syncQueue.sync {
            configs[config.id] = config
            saveConfigs()
        }
        
        if initialPull {
            await FolderSyncExecutor.pullRemoteFiles(
                serverId: config.serverId,
                remotePath: config.remotePath,
                localURL: config.localURL,
                onDownloadStarted: { [weak self] p in self?.syncQueue.sync { _ = self?.internalDownloads.insert(p) } },
                onDownloadCompleted: { [weak self] p in self?.syncQueue.sync { _ = self?.internalDownloads.remove(p) } }
            )
        }
        
        syncQueue.sync {
            snapshots[config.id] = FolderSyncScanner.scan(rootURL: localURL)
            startWatcher(for: config)
        }
        notifyChanged()
        return config
    }
    
    public func stopSync(configId: String) {
        syncQueue.sync {
            watchers[configId]?.stop()
            watchers.removeValue(forKey: configId)
            debounceTasks[configId]?.cancel()
            debounceTasks.removeValue(forKey: configId)
            snapshots.removeValue(forKey: configId)
            configs.removeValue(forKey: configId)
            saveConfigs()
        }
        notifyChanged()
    }
    
    public func openInFinder(config: SyncedFolderConfig) {
        if FileManager.default.fileExists(atPath: config.localURL.path) {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: config.localURL.path)
        }
    }
    
    public func processLocalChanges(configId: String) async {
        guard let config = syncQueue.sync(execute: { configs[configId] }), config.isEnabled else { return }
        let shouldRun = syncQueue.sync { () -> Bool in
            guard !activeSyncs.contains(configId) else { return false }
            activeSyncs.insert(configId)
            return true
        }
        guard shouldRun else { return }
        defer { syncQueue.sync { _ = activeSyncs.remove(configId) } }
        
        let oldSnap = syncQueue.sync { snapshots[configId] ?? [:] }
        let currentSnap = FolderSyncScanner.scan(rootURL: config.localURL)
        let diff = FolderSyncScanner.diff(oldSnapshot: oldSnap, newSnapshot: currentSnap)
        guard diff.hasChanges else { return }
        
        let filesToUpload = diff.addedOrModifiedFiles.filter { rec in
            let path = config.localURL.appendingPathComponent(rec.relativePath).path
            return !syncQueue.sync { internalDownloads.contains(path) }
        }
        
        await FolderSyncExecutor.createRemoteDirectories(serverId: config.serverId, remotePath: config.remotePath, relDirs: diff.addedDirectories)
        await FolderSyncExecutor.uploadChangedFiles(serverId: config.serverId, remotePath: config.remotePath, localURL: config.localURL, files: filesToUpload)
        await FolderSyncExecutor.deleteRemotePaths(serverId: config.serverId, remotePath: config.remotePath, paths: diff.deletedPaths)
        
        syncQueue.sync {
            snapshots[configId] = currentSnap
            configs[configId]?.lastSyncDate = Date()
            saveConfigs()
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Self.didSyncChangesNotification,
                object: nil,
                userInfo: ["configId": configId, "count": diff.totalCount, "folderName": config.folderName]
            )
        }
    }
    
    private func handleWatcherEvent(configId: String) {
        syncQueue.async { [weak self] in
            guard let self = self, let config = self.configs[configId], config.isEnabled else { return }
            self.debounceTasks[configId]?.cancel()
            self.debounceTasks[configId] = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard !Task.isCancelled else { return }
                await self?.processLocalChanges(configId: configId)
            }
        }
    }
    
    private func startWatcher(for config: SyncedFolderConfig) {
        let watcher = FolderWatcher(path: config.localPath) { [weak self] _ in
            self?.handleWatcherEvent(configId: config.id)
        }
        watcher.start()
        watchers[config.id] = watcher
    }
    
    private func normalize(_ path: String) -> String {
        var p = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if !p.hasPrefix("/") { p = "/" + p }
        while p.count > 1 && p.hasSuffix("/") { p.removeLast() }
        return p
    }
    
    private func notifyChanged() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
        }
    }
    
    private func loadConfigs() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let list = try? JSONDecoder().decode([SyncedFolderConfig].self, from: data) else { return }
        for cfg in list {
            configs[cfg.id] = cfg
            if cfg.isEnabled && FileManager.default.fileExists(atPath: cfg.localPath) {
                snapshots[cfg.id] = FolderSyncScanner.scan(rootURL: cfg.localURL)
                startWatcher(for: cfg)
            }
        }
    }
    
    private func saveConfigs() {
        if let data = try? JSONEncoder().encode(Array(configs.values)) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
