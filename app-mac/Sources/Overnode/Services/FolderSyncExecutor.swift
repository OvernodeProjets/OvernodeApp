import Foundation

/// Handles network synchronization actions (upload, delete, create remote directories) for synced folders.
public struct FolderSyncExecutor: Sendable {
    public static func joinPath(_ root: String, _ sub: String) -> String {
        let cleanRoot = root == "/" ? "" : root
        let cleanSub = sub.hasPrefix("/") ? String(sub.dropFirst()) : sub
        return "\(cleanRoot)/\(cleanSub)"
    }
    
    public static func createRemoteDirectories(serverId: String, remotePath: String, relDirs: [String]) async {
        let service = ServerFilesService.shared
        for relDir in relDirs {
            let fullPath = joinPath(remotePath, relDir)
            let parent = (fullPath as NSString).deletingLastPathComponent
            let name = (fullPath as NSString).lastPathComponent
            try? await service.createFolder(serverId: serverId, root: parent, name: name)
        }
    }
    
    public static func uploadChangedFiles(
        serverId: String,
        remotePath: String,
        localURL: URL,
        files: [LocalFileRecord]
    ) async {
        let service = ServerFilesService.shared
        for fileRecord in files {
            let fullLocal = localURL.appendingPathComponent(fileRecord.relativePath)
            let fullRemote = joinPath(remotePath, fileRecord.relativePath)
            let parent = (fullRemote as NSString).deletingLastPathComponent
            let name = (fullRemote as NSString).lastPathComponent
            
            do {
                let data = try Data(contentsOf: fullLocal)
                let uploadURL = try await service.getUploadURL(serverId: serverId, directory: parent)
                try await service.uploadFile(uploadURL: uploadURL, directory: parent, fileName: name, fileData: data)
            } catch {
                print("[FolderSyncExecutor] Upload failed for \(name): \(error.localizedDescription)")
            }
        }
    }
    
    public static func deleteRemotePaths(serverId: String, remotePath: String, paths: [String]) async {
        let service = ServerFilesService.shared
        var deletionsByParent: [String: [String]] = [:]
        for relPath in paths {
            let fullRemote = joinPath(remotePath, relPath)
            let parent = (fullRemote as NSString).deletingLastPathComponent
            let name = (fullRemote as NSString).lastPathComponent
            deletionsByParent[parent, default: []].append(name)
        }
        for (parent, names) in deletionsByParent {
            try? await service.deleteFiles(serverId: serverId, root: parent, files: names)
        }
    }
    
    public static func pullRemoteFiles(
        serverId: String,
        remotePath: String,
        localURL: URL,
        onDownloadStarted: @Sendable (String) -> Void,
        onDownloadCompleted: @Sendable (String) -> Void
    ) async {
        let service = ServerFilesService.shared
        guard let remoteFiles = try? await service.listFiles(serverId: serverId, directory: remotePath) else {
            return
        }
        for item in remoteFiles where item.isFile {
            let itemRemotePath = joinPath(remotePath, item.name)
            let destURL = localURL.appendingPathComponent(item.name)
            onDownloadStarted(destURL.path)
            try? await service.downloadFile(serverId: serverId, filePath: itemRemotePath, destinationURL: destURL)
            onDownloadCompleted(destURL.path)
        }
    }
}
