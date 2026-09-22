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
}

