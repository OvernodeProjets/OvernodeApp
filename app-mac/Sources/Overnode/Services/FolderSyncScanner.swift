import Foundation

/// Represents changes detected between local directory scans.
public struct FolderSyncDiff: Sendable {
    public let addedDirectories: [String]
    public let addedOrModifiedFiles: [LocalFileRecord]
    public let deletedPaths: [String]
    
    public var hasChanges: Bool {
        !addedDirectories.isEmpty || !addedOrModifiedFiles.isEmpty || !deletedPaths.isEmpty
    }
    
    public var totalCount: Int {
        addedDirectories.count + addedOrModifiedFiles.count + deletedPaths.count
    }
}

/// High-performance scanner and diffing utility for local synchronized folders.
public struct FolderSyncScanner: Sendable {
    public static func scan(rootURL: URL) -> [String: LocalFileRecord] {
        var records: [String: LocalFileRecord] = [:]
        let fm = FileManager.default
        guard fm.fileExists(atPath: rootURL.path) else { return records }
        
        let keys: [URLResourceKey] = [.contentModificationDateKey, .fileSizeKey, .isDirectoryKey]
        guard let enumerator = fm.enumerator(
            at: rootURL,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else {
            return records
        }
        
        let resolvedRoot = rootURL.resolvingSymlinksInPath().path
        for case let fileURL as URL in enumerator {
            let lastComp = fileURL.lastPathComponent
            if FileUploadSecurity.shared.shouldIgnore(fileName: lastComp) {
                continue
            }
            if lastComp.hasPrefix(".") || lastComp.hasSuffix(".tmp") || lastComp.hasSuffix(".swp") {
                continue
            }
            
            guard let values = try? fileURL.resourceValues(forKeys: Set(keys)),
                  let isDir = values.isDirectory,
                  let modDate = values.contentModificationDate else {
                continue
            }
            
            let resolvedFull = fileURL.resolvingSymlinksInPath().path
            guard resolvedFull.hasPrefix(resolvedRoot) else { continue }
            var relPath = String(resolvedFull.dropFirst(resolvedRoot.count))
            if relPath.hasPrefix("/") {
                relPath = String(relPath.dropFirst())
            }
            guard !relPath.isEmpty else { continue }
            
            let size = Int64(values.fileSize ?? 0)
            records[relPath] = LocalFileRecord(
                relativePath: relPath,
                modificationDate: modDate,
                size: size,
                isDirectory: isDir
            )
        }
        return records
    }
    
    public static func diff(oldSnapshot: [String: LocalFileRecord], newSnapshot: [String: LocalFileRecord]) -> FolderSyncDiff {
        var addedDirs: [String] = []
        var addedOrModified: [LocalFileRecord] = []
        var deleted: [String] = []
        
        for (relPath, newRec) in newSnapshot {
            if let oldRec = oldSnapshot[relPath] {
                if !newRec.isDirectory && (newRec.modificationDate > oldRec.modificationDate || newRec.size != oldRec.size) {
                    addedOrModified.append(newRec)
                }
            } else {
                if newRec.isDirectory {
                    addedDirs.append(relPath)
                } else {
                    addedOrModified.append(newRec)
                }
            }
        }
        
        for (relPath, _) in oldSnapshot {
            if newSnapshot[relPath] == nil {
                deleted.append(relPath)
            }
        }
        
        // Sort added directories by depth so parent directories are created first
        addedDirs.sort { $0.components(separatedBy: "/").count < $1.components(separatedBy: "/").count }
        
        return FolderSyncDiff(
            addedDirectories: addedDirs,
            addedOrModifiedFiles: addedOrModified,
            deletedPaths: deleted
        )
    }
}
