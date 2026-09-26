import Foundation
import AppKit
import UniformTypeIdentifiers

public final class FileDownloadManager: @unchecked Sendable {
    public static let shared = FileDownloadManager()
    private let filesService = ServerFilesService.shared
    
    public var downloadDirectoryURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("OvernodeDragDownloads", isDirectory: true)
    }
    
    private init() {}
    
    public func createDragItemProvider(serverId: String, currentDirectory: String, item: ServerFileItem) -> NSItemProvider {
        let baseDir = downloadDirectoryURL
            .appendingPathComponent(serverId, isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
        
        let destinationURL = baseDir.appendingPathComponent(item.name)
        let remotePath = currentDirectory == "/" ? "/\(item.name)" : "\(currentDirectory)/\(item.name)"
        
        let provider = NSItemProvider(contentsOf: destinationURL) ?? NSItemProvider()
        provider.suggestedName = item.name
        
        if item.isFile {
            let utType = UTType(filenameExtension: (item.name as NSString).pathExtension) ?? .data
            // Kick off background download immediately so file is ready when dropped
            Task {
                try? await self.filesService.downloadFile(serverId: serverId, filePath: remotePath, destinationURL: destinationURL)
            }
            
            provider.registerFileRepresentation(forTypeIdentifier: utType.identifier, fileOptions: .openInPlace, visibility: .all) { [weak self] completion in
                Task {
                    guard let self = self else {
                        completion(destinationURL, false, nil)
                        return
                    }
                    if !FileManager.default.fileExists(atPath: destinationURL.path) {
                        try? await self.filesService.downloadFile(serverId: serverId, filePath: remotePath, destinationURL: destinationURL)
                    }
                    completion(destinationURL, false, nil)
                }
                return nil
            }
        } else {
            // Folder: create local directory immediately
            try? FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
            
            // Kick off background folder recursive download
            Task {
                await self.stageFolder(serverId: serverId, remotePath: remotePath, localDirURL: destinationURL)
            }
            
            provider.registerFileRepresentation(forTypeIdentifier: UTType.folder.identifier, fileOptions: [], visibility: .all) { [weak self] completion in
                Task {
                    guard let self = self else {
                        completion(destinationURL, false, nil)
                        return
                    }
                    await self.stageFolder(serverId: serverId, remotePath: remotePath, localDirURL: destinationURL)
                    completion(destinationURL, false, nil)
                }
                return nil
            }
        }
        
        return provider
    }
    
    public func stageFolder(serverId: String, remotePath: String, localDirURL: URL) async {
        try? FileManager.default.createDirectory(at: localDirURL, withIntermediateDirectories: true)
        
        if ProcessInfo.processInfo.environment["OVERNODE_DEMO"] != nil {
            let sampleFile = localDirURL.appendingPathComponent("info.txt")
            try? "Exported folder from Overnode demo\n".data(using: .utf8)?.write(to: sampleFile)
            return
        }
        
        do {
            let items = try await filesService.listFiles(serverId: serverId, directory: remotePath)
            for child in items {
                let childRemote = remotePath == "/" ? "/\(child.name)" : "\(remotePath)/\(child.name)"
                let childLocal = localDirURL.appendingPathComponent(child.name)
                if child.isFile {
                    try? await filesService.downloadFile(serverId: serverId, filePath: childRemote, destinationURL: childLocal)
                } else {
                    await stageFolder(serverId: serverId, remotePath: childRemote, localDirURL: childLocal)
                }
            }
        } catch {
            print("[FileDownloadManager] Failed to stage folder: \(error.localizedDescription)")
        }
    }
    
    public func purgeAllTemporaryFiles() {
        let dir = downloadDirectoryURL
        if FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.removeItem(at: dir)
            print("[FileDownloadManager] Purged temporary drag download files.")
        }
    }
    
    public func cleanupStaleTemporaryFiles(maxAgeSeconds: TimeInterval = 3600) {
        let dir = downloadDirectoryURL
        guard FileManager.default.fileExists(atPath: dir.path) else { return }
        let thresholdDate = Date().addingTimeInterval(-maxAgeSeconds)
        let fm = FileManager.default
        guard let serverDirs = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles) else { return }
        
        for serverDir in serverDirs {
            guard let sessionDirs = try? fm.contentsOfDirectory(at: serverDir, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles) else { continue }
            for sessionDir in sessionDirs {
                let attrs = try? fm.attributesOfItem(atPath: sessionDir.path)
                if let modDate = attrs?[.modificationDate] as? Date, modDate < thresholdDate {
                    try? fm.removeItem(at: sessionDir)
                }
            }
            if let remaining = try? fm.contentsOfDirectory(atPath: serverDir.path), remaining.isEmpty {
                try? fm.removeItem(at: serverDir)
            }
        }
    }
}
