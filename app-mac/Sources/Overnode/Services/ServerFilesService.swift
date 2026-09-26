import Foundation

public final class ServerFilesService: @unchecked Sendable {
    public static let shared = ServerFilesService()
    private let client = APIClient.shared
    
    private init() {}
    
    public func listFiles(serverId: String, directory: String = "/") async throws -> [ServerFileItem] {
        let encodedDir = directory.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "/"
        let endpoint = "/api/server/\(serverId)/files/list?directory=\(encodedDir)"
        
        let response: PteroFileListResponse = try await client.request(endpoint: endpoint)
        return response.data.map { item in
            let attr = item.attributes
            return ServerFileItem(
                name: attr.name,
                mode: attr.mode,
                size: attr.size ?? 0,
                isFile: attr.isFile ?? true,
                isSymlink: attr.isSymlink ?? false,
                isEditable: attr.isEditable ?? true,
                mimetype: attr.mimetype,
                modifiedAt: attr.modifiedAt
            )
        }.sorted { (a, b) in
            // Folders first, then alphabetically
            if a.isFile != b.isFile {
                return !a.isFile
            }
            return a.name.lowercased() < b.name.lowercased()
        }
    }
    
    public func readFile(serverId: String, filePath: String) async throws -> String {
        let encodedPath = filePath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? filePath
        let endpoint = "/api/server/\(serverId)/files/contents?file=\(encodedPath)"
        return try await client.requestString(endpoint: endpoint)
    }
    
    public func writeFile(serverId: String, filePath: String, content: String) async throws {
        let encodedPath = filePath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? filePath
        let endpoint = "/api/server/\(serverId)/files/write?file=\(encodedPath)"
        let data = content.data(using: .utf8) ?? Data()
        _ = try await client.requestData(
            endpoint: endpoint,
            method: "POST",
            body: data,
            contentType: "text/plain"
        )
    }
    
    public func createFolder(serverId: String, root: String, name: String) async throws {
        struct FolderPayload: Encodable {
            let root: String
            let name: String
        }
        let data = try JSONEncoder().encode(FolderPayload(root: root, name: name))
        try await client.requestEmpty(
            endpoint: "/api/server/\(serverId)/files/create-folder",
            method: "POST",
            body: data
        )
    }
    
    public func deleteFiles(serverId: String, root: String, files: [String]) async throws {
        struct DeletePayload: Encodable {
            let root: String
            let files: [String]
        }
        let data = try JSONEncoder().encode(DeletePayload(root: root, files: files))
        try await client.requestEmpty(
            endpoint: "/api/server/\(serverId)/files/delete",
            method: "POST",
            body: data
        )
    }
    
    public func renameFile(serverId: String, root: String, from: String, to: String) async throws {
        struct FileRenameItem: Encodable {
            let from: String
            let to: String
        }
        struct RenamePayload: Encodable {
            let root: String
            let files: [FileRenameItem]
        }
        let payload = RenamePayload(root: root, files: [FileRenameItem(from: from, to: to)])
        let data = try JSONEncoder().encode(payload)
        try await client.requestEmpty(
            endpoint: "/api/server/\(serverId)/files/rename",
            method: "PUT",
            body: data
        )
    }
    
    // MARK: - Upload
    
    public func getUploadURL(serverId: String, directory: String = "/") async throws -> String {
        let encodedDir = directory.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "/"
        struct Resp: Codable {
            struct Attr: Codable { let url: String }
            let attributes: Attr?
            let url: String?
        }
        let response: Resp = try await client.request(endpoint: "/api/server/\(serverId)/files/upload?directory=\(encodedDir)")
        guard let url = response.attributes?.url ?? response.url, !url.isEmpty else {
            throw NSError(domain: "ServerFilesService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid upload URL"])
        }
        return url
    }
    
    public func uploadFile(
        uploadURL: String,
        directory: String,
        fileName: String,
        fileData: Data
    ) async throws {
        var targetURLString = uploadURL
        if !targetURLString.contains("directory=") {
            let separator = targetURLString.contains("?") ? "&" : "?"
            let encodedDir = directory.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? directory
            targetURLString += "\(separator)directory=\(encodedDir)"
        }
        
        guard let url = URL(string: targetURLString) else {
            throw URLError(.badURL)
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        guard let boundaryHeader = "--\(boundary)\r\n".data(using: .utf8),
              let disposition = "Content-Disposition: form-data; name=\"files\"; filename=\"\(fileName)\"\r\n".data(using: .utf8),
              let contentType = "Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8),
              let boundaryFooter = "\r\n--\(boundary)--\r\n".data(using: .utf8) else {
            throw URLError(.cannotCreateFile)
        }
        
        body.append(boundaryHeader)
        body.append(disposition)
        body.append(contentType)
        body.append(fileData)
        body.append(boundaryFooter)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        request.setValue("Overnode-macOS-Native/1.0", forHTTPHeaderField: "User-Agent")
        request.httpBody = body
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "ServerFilesService", code: code, userInfo: [NSLocalizedDescriptionKey: "Upload failed with status \(code)"])
        }
    }
    
    // MARK: - Download
    
    public func getDownloadURL(serverId: String, filePath: String) async throws -> String {
        let encodedPath = filePath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? filePath
        struct Resp: Codable {
            struct Attr: Codable { let url: String }
            let attributes: Attr?
            let url: String?
        }
        let response: Resp = try await client.request(endpoint: "/api/server/\(serverId)/files/download?file=\(encodedPath)")
        guard let url = response.attributes?.url ?? response.url, !url.isEmpty else {
            throw NSError(domain: "ServerFilesService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid download URL"])
        }
        return url
    }
    
    public func downloadFile(serverId: String, filePath: String, destinationURL: URL) async throws {
        if ProcessInfo.processInfo.environment["OVERNODE_DEMO"] != nil {
            let sample = "Content of \(filePath) downloaded from Overnode server.\n"
            try sample.data(using: .utf8)?.write(to: destinationURL)
            return
        }
        
        do {
            let downloadURLString = try await getDownloadURL(serverId: serverId, filePath: filePath)
            guard let downloadURL = URL(string: downloadURLString) else {
                throw URLError(.badURL)
            }
            let (tempDownloadedURL, _) = try await URLSession.shared.download(from: downloadURL)
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: tempDownloadedURL, to: destinationURL)
        } catch {
            let content = try await readFile(serverId: serverId, filePath: filePath)
            try content.data(using: .utf8)?.write(to: destinationURL)
        }
    }
}

