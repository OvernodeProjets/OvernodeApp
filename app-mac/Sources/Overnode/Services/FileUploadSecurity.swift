import Foundation

public struct FileUploadItem: Sendable {
    public let localURL: URL
    public let relativePath: String
    public let fileName: String
    public let isDirectory: Bool
    public let size: Int64
}

public struct FileUploadPlan: Sendable {
    public let directoriesToCreate: [String]
    public let filesToUpload: [FileUploadItem]
    public let totalByteSize: Int64
}

public enum FileUploadError: LocalizedError, Equatable {
    case emptySelection
    case tooManyFiles(count: Int, maxAllowed: Int)
    case singleFileSizeExceeded(fileName: String, maxMB: Int)
    case insufficientDiskQuota(availableMB: Double, requiredMB: Double)
    case securityViolation(reason: String)
    case uploadFailed(message: String)
    
    public var errorDescription: String? {
        switch self {
        case .emptySelection:
            return "Aucun fichier valide sélectionné pour l'envoi."
        case .tooManyFiles(let c, let max):
            return "Nombre maximal d'éléments dépassé (\(c), max: \(max))."
        case .singleFileSizeExceeded(let n, let max):
            return "Le fichier « \(n) » dépasse la taille maximale autorisée (\(max) Mo)."
        case .insufficientDiskQuota(let a, let r):
            return String(format: "Quota disque insuffisant : %.1f Mo requis, %.1f Mo disponibles.", r, a)
        case .securityViolation(let r):
            return "Sécurité : \(r)"
        case .uploadFailed(let m):
            return "Échec du téléversement : \(m)"
        }
    }
    
    @MainActor
    public var localizedMessage: String {
        let loc = LocalizationManager.shared
        switch self {
        case .emptySelection: return loc.string("files_upload_error_empty")
        case .tooManyFiles(let c, let max): return loc.string("files_upload_error_maxcount", c, max)
        case .singleFileSizeExceeded(let n, let max): return loc.string("files_upload_error_filesize", n, max)
        case .insufficientDiskQuota(let a, let r): return loc.string("files_upload_error_quota", a, r)
        case .securityViolation(let r): return loc.string("files_upload_error_security", r)
        case .uploadFailed(let m): return loc.string("files_upload_error_generic", m)
        }
    }
}

public final class FileUploadSecurity: @unchecked Sendable {
    public static let shared = FileUploadSecurity()
    public static let maxBatchFileCount = 500
    public static let maxSingleFileSize: Int64 = 100 * 1024 * 1024
    
    private static let ignoredFileNames: Set<String> = [
        ".ds_store", ".localized", "__macosx", ".trashes",
        ".fseventsd", ".spotlight-v100", ".temporaryitems"
    ]
    
    private init() {}
    
    public func shouldIgnore(fileName: String) -> Bool {
        let lower = fileName.lowercased()
        return lower.hasPrefix("._") || Self.ignoredFileNames.contains(lower)
    }
    
    public func validatePathSecurity(_ path: String) throws {
        if path.contains("..") || path.contains("\0") || path.contains("\\") || path.contains("//") {
            throw FileUploadError.securityViolation(reason: "Tentative de traversée de chemin non autorisée")
        }
        for comp in path.split(separator: "/", omittingEmptySubsequences: false) where comp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw FileUploadError.securityViolation(reason: "Nom de dossier ou fichier vide")
        }
    }
    
    private func checkFileSize(name: String, size: Int64) throws {
        if size > Self.maxSingleFileSize {
            throw FileUploadError.singleFileSizeExceeded(fileName: name, maxMB: Int(Self.maxSingleFileSize / (1024 * 1024)))
        }
    }
    
    public func buildPlan(from urls: [URL], diskLimitMB: Double = 0, diskUsedMB: Double = 0) throws -> FileUploadPlan {
        guard !urls.isEmpty else { throw FileUploadError.emptySelection }
        
        var directories = Set<String>()
        var files: [FileUploadItem] = []
        var totalBytes: Int64 = 0
        let fm = FileManager.default
        
        for url in urls {
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { continue }
            let rootName = url.lastPathComponent
            if shouldIgnore(fileName: rootName) { continue }
            try validatePathSecurity(rootName)
            
            if isDir.boolValue {
                directories.insert(rootName)
                try scanDirectory(rootURL: url, baseRelPath: rootName, directories: &directories, files: &files, totalBytes: &totalBytes)
            } else {
                let size = ((try? fm.attributesOfItem(atPath: url.path))?[.size] as? NSNumber)?.int64Value ?? 0
                try checkFileSize(name: rootName, size: size)
                totalBytes += size
                files.append(FileUploadItem(localURL: url, relativePath: rootName, fileName: rootName, isDirectory: false, size: size))
            }
            if files.count + directories.count > Self.maxBatchFileCount {
                throw FileUploadError.tooManyFiles(count: files.count + directories.count, maxAllowed: Self.maxBatchFileCount)
            }
        }
        
        if diskLimitMB > 0 {
            let availableMB = max(0, diskLimitMB - diskUsedMB)
            let requiredMB = Double(totalBytes) / (1024 * 1024)
            if requiredMB > availableMB {
                throw FileUploadError.insufficientDiskQuota(availableMB: availableMB, requiredMB: requiredMB)
            }
        }
        
        let sortedDirs = directories.sorted { $0.split(separator: "/").count < $1.split(separator: "/").count }
        return FileUploadPlan(directoriesToCreate: sortedDirs, filesToUpload: files, totalByteSize: totalBytes)
    }
    
    private func scanDirectory(
        rootURL: URL,
        baseRelPath: String,
        directories: inout Set<String>,
        files: inout [FileUploadItem],
        totalBytes: inout Int64
    ) throws {
        let fm = FileManager.default
        let enumerator = fm.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles, .producesRelativePathURLs]
        )
        
        while let itemURL = enumerator?.nextObject() as? URL {
            let rel = itemURL.relativePath
            if rel.isEmpty || rel == "." { continue }
            let fullRel = "\(baseRelPath)/\(rel)"
            try validatePathSecurity(fullRel)
            let fileName = itemURL.lastPathComponent
            if shouldIgnore(fileName: fileName) { continue }
            
            let res = try? itemURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .isSymbolicLinkKey])
            if res?.isSymbolicLink == true { continue }
            
            if res?.isDirectory ?? false {
                directories.insert(fullRel)
            } else {
                let size = Int64(res?.fileSize ?? 0)
                try checkFileSize(name: fileName, size: size)
                totalBytes += size
                files.append(FileUploadItem(localURL: itemURL, relativePath: fullRel, fileName: fileName, isDirectory: false, size: size))
            }
            if files.count + directories.count > Self.maxBatchFileCount {
                throw FileUploadError.tooManyFiles(count: files.count + directories.count, maxAllowed: Self.maxBatchFileCount)
            }
        }
    }
}
