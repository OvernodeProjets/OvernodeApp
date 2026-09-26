import Foundation
import SwiftUI
import Combine

public enum ServerTab: String, CaseIterable, Identifiable {
    case console = "console"
    case renewal = "renewal"
    case files = "files"
    case subdomains = "subdomains"
    case subusers = "subusers"
    case package = "package"
    case plugins = "plugins"
    case logs = "logs"
    case settings = "settings"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .console: return "terminal"
        case .renewal: return "calendar.badge.clock"
        case .files: return "folder"
        case .subdomains: return "network"
        case .subusers: return "person.2"
        case .package: return "shippingbox"
        case .plugins: return "puzzlepiece.extension"
        case .logs: return "list.bullet.rectangle"
        case .settings: return "slider.horizontal.3"
        }
    }
}

@MainActor
public final class ServerDetailViewModel: ObservableObject {
    @Published public var server: ServerInstance
    @Published public var selectedTab: ServerTab = .console
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var successMessage: String?
    
    // Console & Power
    @Published public var consoleLines: [String] = []
    @Published public var commandInput: String = ""
    @Published public var isPowerLoading: Bool = false
    
    // Renewal
    @Published public var renewalStatus: ServerRenewalStatus?
    @Published public var isRenewing: Bool = false
    @Published public var renewalSuccessMessage: String?
    
    // Files
    @Published public var currentDirectory: String = "/"
    @Published public var files: [ServerFileItem] = []
    @Published public var selectedFile: ServerFileItem?
    @Published public var fileEditorContent: String = ""
    @Published public var isFileLoading: Bool = false
    @Published public var isFileSaving: Bool = false
    @Published public var fileSuccessMessage: String?
    @Published public var fileErrorMessage: String?
    @Published public var isUploadingFiles: Bool = false
    @Published public var uploadProgress: Double = 0.0
    @Published public var uploadProgressText: String = ""
    
    // Subdomains & Subusers
    @Published public var subdomains: [ServerSubdomain] = []
    @Published public var availableDomains: [String] = []
    @Published public var subusers: [ServerSubuser] = []
    
    // Package & Resources
    @Published public var packageRamMB: Double = 0
    @Published public var packageDiskMB: Double = 0
    @Published public var packageCpuPercent: Double = 0
    @Published public var maxAvailableRamMB: Double = 32768
    @Published public var maxAvailableDiskMB: Double = 65536
    @Published public var maxAvailableCpuPercent: Double = 800
    @Published public var isSavingPackage: Bool = false
    
    // Plugins
    @Published public var installedPlugins: [ServerPluginItem] = []
    @Published public var pluginSearchResults: [ServerPluginItem] = []
    @Published public var pluginSearchQuery: String = ""
    @Published public var isSearchingPlugins: Bool = false
    
    // Logs & Settings
    @Published public var activityLogs: [ServerActivityLog] = []
    @Published public var startupVariables: [ServerStartupVariable] = []
    @Published public var serverRenameText: String = ""
    @Published public var isDeleting: Bool = false
    
    private let serverService = ServerService.shared
    private let filesService = ServerFilesService.shared
    private let configService = ServerConfigService.shared
    
    public init(server: ServerInstance, initialTab: ServerTab = .console) {
        self.server = server
        self.selectedTab = initialTab
        self.packageRamMB = server.memoryLimitMB
        self.packageDiskMB = server.diskLimitMB
        self.packageCpuPercent = server.cpuLimitPercent
        self.serverRenameText = server.name
        
        appendConsoleLine("[System] Session connected to \(server.name) (\(server.identifier))")
        appendConsoleLine("[System] Current state: \(server.state.uppercased())")
        
        setupWebSocket()
        
        if ProcessInfo.processInfo.environment["OVERNODE_DEMO"] == "1" {
            appendConsoleLine("[Server] Loading properties from server.properties")
            appendConsoleLine("[Server] Starting Minecraft server on port 25565")
            appendConsoleLine("[Server] Done (3.421s)! For help, type \"help\"")
            
            self.renewalStatus = ServerRenewalStatus(
                isActive: true,
                nextRenewalAt: "2026-10-15T12:00:00Z",
                lastRenewedAt: "2026-09-15T12:00:00Z",
                canRenew: true,
                requiresRenewal: false,
                isExpired: false,
                timeRemaining: "23d 4h",
                renewalCount: 3
            )
            self.files = [
                ServerFileItem(name: "plugins", size: 0, isFile: false),
                ServerFileItem(name: "world", size: 0, isFile: false),
                ServerFileItem(name: "world_nether", size: 0, isFile: false),
                ServerFileItem(name: "server.properties", size: 1024, isFile: true),
                ServerFileItem(name: "spigot.yml", size: 3450, isFile: true),
                ServerFileItem(name: "bukkit.yml", size: 2100, isFile: true),
                ServerFileItem(name: "paper.jar", size: 45 * 1024 * 1024, isFile: true)
            ]
            self.subdomains = [
                ServerSubdomain(id: "1", serverId: server.identifier, subdomain: "play", domainName: "overnode.fr", createdAt: nil)
            ]
            self.availableDomains = ["overnode.fr", "overnode.cloud", "play.overnode.fr"]
            self.subusers = [
                ServerSubuser(id: "1", email: "admin@overnode.fr", twoFactorEnabled: true, permissions: ["*"])
            ]
            self.installedPlugins = [
                ServerPluginItem(id: "1", name: "EssentialsX", description: "Essential server commands and utilities", iconUrl: nil, version: "2.20.1", author: "EssentialsX Team", platform: "spigot", downloads: 450000, isInstalled: true),
                ServerPluginItem(id: "2", name: "WorldEdit", description: "Fast in-game world manipulation", iconUrl: nil, version: "7.3.0", author: "EngineHub", platform: "modrinth", downloads: 820000, isInstalled: true)
            ]
            self.activityLogs = [
                ServerActivityLog(id: "1", timestamp: "2026-09-22T17:45:00Z", action: "server.start", username: "OvernodeUser", details: nil),
                ServerActivityLog(id: "2", timestamp: "2026-09-22T12:30:00Z", action: "server.renewal", username: "OvernodeUser", details: nil),
                ServerActivityLog(id: "3", timestamp: "2026-09-21T09:15:00Z", action: "file.update", username: "OvernodeUser", details: nil)
            ]
            self.startupVariables = [
                ServerStartupVariable(name: "Server JAR File", envVariable: "SERVER_JARFILE", defaultValue: "server.jar", serverValue: "paper.jar", isEditable: true),
                ServerStartupVariable(name: "Java Version", envVariable: "JAVA_VERSION", defaultValue: "21", serverValue: "21", isEditable: true)
            ]
        }
        
        loadCurrentTabData()
    }
    
    deinit {
        ServerWebSocketManager.shared.disconnect()
    }
    
    public func updateServer(_ updated: ServerInstance) {
        var copy = updated
        copy.memoryUsedMB = self.server.memoryUsedMB
        copy.cpuUsedPercent = self.server.cpuUsedPercent
        copy.diskUsedMB = self.server.diskUsedMB
        if !self.server.state.isEmpty {
            copy.state = self.server.state
        }
        self.server = copy
    }
    
    public func appendConsoleLine(_ line: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        consoleLines.append("[\(timestamp)] \(line)")
        if consoleLines.count > 500 {
            consoleLines.removeFirst(consoleLines.count - 500)
        }
    }
    
    public func appendRawConsoleLine(_ line: String) {
        let clean = line.trimmingCharacters(in: .newlines)
        guard !clean.isEmpty else { return }
        consoleLines.append(clean)
        if consoleLines.count > 1000 {
            consoleLines.removeFirst(consoleLines.count - 1000)
        }
    }
    
    private func setupWebSocket() {
        if ProcessInfo.processInfo.environment["OVERNODE_DEMO"] == "1" { return }
        
        let ws = ServerWebSocketManager.shared
        ws.onConsoleOutput = { [weak self] line in
            Task { @MainActor in
                self?.appendRawConsoleLine(line)
            }
        }
        ws.onStatusChange = { [weak self] status in
            Task { @MainActor in
                self?.server.state = status
            }
        }
        ws.onStatsUpdate = { [weak self] stats in
            Task { @MainActor in
                guard let self = self else { return }
                if let cpu = stats.cpuAbsolute {
                    self.server.cpuUsedPercent = round(cpu * 10) / 10
                }
                if let mem = stats.memoryBytes {
                    self.server.memoryUsedMB = round(mem / 1024.0 / 1024.0)
                }
                if let disk = stats.diskBytes {
                    self.server.diskUsedMB = round(disk / 1024.0 / 1024.0)
                }
                if let st = stats.state {
                    self.server.state = st
                }
            }
        }
        ws.connect(serverId: server.identifier)
    }
    
    public func loadCurrentTabData() {
        if ProcessInfo.processInfo.environment["OVERNODE_DEMO"] == "1" {
            return
        }
        Task {
            await refreshLiveStats()
            switch selectedTab {
            case .console:
                break
            case .renewal:
                await loadRenewal()
            case .files:
                await loadFiles()
            case .subdomains:
                await loadSubdomains()
            case .subusers:
                await loadSubusers()
            case .package:
                await loadPackageResources()
            case .plugins:
                await loadPlugins()
            case .logs:
                await loadLogs()
            case .settings:
                await loadSettings()
            }
        }
    }
    
    public func refreshLiveStats() async {
        if let stats = try? await serverService.fetchLiveResources(identifier: server.identifier) {
            server.state = stats.state
            server.memoryUsedMB = stats.memoryMB
            server.cpuUsedPercent = stats.cpuPercent
            server.diskUsedMB = stats.diskMB
        }
    }
    
    // MARK: - Power Actions
    public func sendPowerSignal(_ signal: ServerPowerSignal) {
        isPowerLoading = true
        errorMessage = nil
        appendConsoleLine("[Action] Power signal: \(signal.rawValue.uppercased()) sent...")
        ServerWebSocketManager.shared.sendPowerSignal(signal)
        
        Task {
            do {
                try await serverService.sendPowerSignal(serverId: server.identifier, signal: signal)
                switch signal {
                case .start: server.state = "starting"
                case .stop, .kill: server.state = "stopping"
                case .restart: server.state = "starting"
                }
                appendConsoleLine("[Action] Power signal \(signal.rawValue.uppercased()) acknowledged.")
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await refreshLiveStats()
            } catch {
                errorMessage = error.localizedDescription
                appendConsoleLine("[Error] Failed to send signal: \(error.localizedDescription)")
            }
            isPowerLoading = false
        }
    }
    
    public func sendConsoleCommand() {
        let cmd = commandInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cmd.isEmpty else { return }
        commandInput = ""
        appendConsoleLine("> \(cmd)")
        ServerWebSocketManager.shared.sendCommand(cmd)
        
        Task {
            do {
                try await serverService.sendCommand(serverId: server.identifier, command: cmd)
            } catch {
                appendConsoleLine("[Error] Command failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Renewal
    public func loadRenewal(force: Bool = false) async {
        if isLoading && !force { return }
        isLoading = true
        if let newStatus = await serverService.fetchRenewalStatus(serverId: server.identifier) {
            self.renewalStatus = newStatus
        }
        isLoading = false
    }
    
    public func renewServer() {
        isRenewing = true
        errorMessage = nil
        renewalSuccessMessage = nil
        
        Task {
            do {
                let res = try await serverService.renewServer(serverId: server.identifier)
                if let err = res.error {
                    var msg = err
                    if let avail = res.availableIn {
                        msg += " (" + LocalizationManager.shared.string("renewal_available_in") + " " + avail + ")"
                    }
                    errorMessage = msg
                    if let data = res.renewalData {
                        self.renewalStatus = data
                    }
                } else {
                    let msg = res.message ?? "Server renewed successfully"
                    renewalSuccessMessage = msg
                    successMessage = msg
                    if let data = res.renewalData {
                        self.renewalStatus = data
                    } else {
                        await loadRenewal()
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isRenewing = false
        }
    }
    
    // MARK: - Files
    public func loadFiles(directory: String? = nil, force: Bool = false) async {
        if let dir = directory {
            currentDirectory = dir
        }
        if isFileLoading && !force { return }
        isFileLoading = true
        errorMessage = nil
        do {
            let loaded = try await filesService.listFiles(serverId: server.identifier, directory: currentDirectory)
            self.files = loaded
        } catch {
            errorMessage = error.localizedDescription
        }
        isFileLoading = false
    }
    
    public func openFile(_ item: ServerFileItem) {
        if !item.isFile {
            let nextDir = currentDirectory == "/" ? "/\(item.name)" : "\(currentDirectory)/\(item.name)"
            Task { await loadFiles(directory: nextDir) }
            return
        }
        
        if ExternalEditorManager.shared.alwaysOpenInExternalEditor {
            openFileInExternalEditor(item)
        } else {
            openFileInternally(item)
        }
    }
    
    public func openFileInternally(_ item: ServerFileItem) {
        guard item.isFile else { return }
        selectedFile = item
        isFileLoading = true
        let fullPath = currentDirectory == "/" ? "/\(item.name)" : "\(currentDirectory)/\(item.name)"
        Task {
            do {
                fileEditorContent = try await filesService.readFile(serverId: server.identifier, filePath: fullPath)
            } catch {
                errorMessage = error.localizedDescription
                selectedFile = nil
            }
            isFileLoading = false
        }
    }
    
    public func openFileInExternalEditor(_ item: ServerFileItem, forceChooseEditor: Bool = false) {
        guard item.isFile else { return }
        let fullPath = currentDirectory == "/" ? "/\(item.name)" : "\(currentDirectory)/\(item.name)"
        isFileLoading = true
        errorMessage = nil
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let content = try await self.filesService.readFile(serverId: self.server.identifier, filePath: fullPath)
                let editorURL: URL?
                if forceChooseEditor {
                    editorURL = await MainActor.run {
                        ExternalEditorManager.shared.promptUserToSelectEditor()
                    }
                    guard editorURL != nil else {
                        self.isFileLoading = false
                        return
                    }
                } else {
                    editorURL = nil
                }
                
                _ = try await ExternalEditorManager.shared.openAndWatch(
                    serverId: self.server.identifier,
                    remotePath: fullPath,
                    fileName: item.name,
                    initialContent: content,
                    editorURL: editorURL
                ) { [weak self] newContent in
                    guard let self = self else { return }
                    try await self.filesService.writeFile(
                        serverId: self.server.identifier,
                        filePath: fullPath,
                        content: newContent
                    )
                    await MainActor.run {
                        let msg = LocalizationManager.shared.string("files_external_synced", item.name)
                        self.fileSuccessMessage = msg
                        Task { @MainActor [weak self] in
                            try? await Task.sleep(nanoseconds: 4_000_000_000)
                            if self?.fileSuccessMessage == msg {
                                self?.fileSuccessMessage = nil
                            }
                        }
                    }
                }
                await MainActor.run {
                    let msg = LocalizationManager.shared.string("files_external_opening", item.name)
                    self.fileSuccessMessage = msg
                    Task { @MainActor [weak self] in
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        if self?.fileSuccessMessage == msg {
                            self?.fileSuccessMessage = nil
                        }
                    }
                }
            } catch {
                self.fileErrorMessage = error.localizedDescription
            }
            self.isFileLoading = false
        }
    }
    
    public func saveCurrentFile() {
        guard let item = selectedFile else { return }
        isFileSaving = true
        fileErrorMessage = nil
        let fullPath = currentDirectory == "/" ? "/\(item.name)" : "\(currentDirectory)/\(item.name)"
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.filesService.writeFile(serverId: self.server.identifier, filePath: fullPath, content: self.fileEditorContent)
                let msg = LocalizationManager.shared.string("files_save_success")
                self.fileSuccessMessage = msg
                Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 4_000_000_000)
                    if self?.fileSuccessMessage == msg {
                        self?.fileSuccessMessage = nil
                    }
                }
            } catch {
                self.fileErrorMessage = error.localizedDescription
            }
            self.isFileSaving = false
        }
    }
    
    public func createFolder(name: String) async {
        do {
            try await filesService.createFolder(serverId: server.identifier, root: currentDirectory, name: name)
            await loadFiles()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    public func deleteFile(_ item: ServerFileItem) async {
        do {
            try await filesService.deleteFiles(serverId: server.identifier, root: currentDirectory, files: [item.name])
            await loadFiles()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Drag & Drop File Download to Finder
    
    public func itemProviderForDrag(item: ServerFileItem) -> NSItemProvider {
        FileDownloadManager.shared.createDragItemProvider(
            serverId: server.identifier,
            currentDirectory: currentDirectory,
            item: item
        )
    }
    
    // MARK: - Drag & Drop File Upload
    
    public func uploadDroppedURLs(_ urls: [URL]) async {
        guard !urls.isEmpty else { return }
        
        fileErrorMessage = nil
        fileSuccessMessage = nil
        
        let plan: FileUploadPlan
        do {
            plan = try FileUploadSecurity.shared.buildPlan(
                from: urls,
                diskLimitMB: server.diskLimitMB,
                diskUsedMB: server.diskUsedMB
            )
        } catch {
            fileErrorMessage = (error as? FileUploadError)?.localizedMessage ?? error.localizedDescription
            return
        }
        
        let totalSteps = Double(plan.directoriesToCreate.count + plan.filesToUpload.count)
        guard totalSteps > 0 else { return }
        
        isUploadingFiles = true
        uploadProgress = 0.0
        uploadProgressText = LocalizationManager.shared.string("files_uploading")
        
        var currentStep = 0.0
        let isDemo = ProcessInfo.processInfo.environment["OVERNODE_DEMO"] != nil
        
        do {
            // Create subdirectories
            for dir in plan.directoriesToCreate {
                let parent: String
                let dirName: String
                if let lastSlash = dir.lastIndex(of: "/") {
                    let relParent = String(dir[..<lastSlash])
                    parent = currentDirectory == "/" ? "/\(relParent)" : "\(currentDirectory)/\(relParent)"
                    dirName = String(dir[dir.index(after: lastSlash)...])
                } else {
                    parent = currentDirectory
                    dirName = dir
                }
                
                uploadProgressText = "\(LocalizationManager.shared.string("files_uploading")) \(dirName)"
                if !isDemo {
                    try await filesService.createFolder(serverId: server.identifier, root: parent, name: dirName)
                }
                currentStep += 1.0
                uploadProgress = currentStep / totalSteps
            }
            
            // Upload files
            for file in plan.filesToUpload {
                let targetDir: String
                if let lastSlash = file.relativePath.lastIndex(of: "/") {
                    let relParent = String(file.relativePath[..<lastSlash])
                    targetDir = currentDirectory == "/" ? "/\(relParent)" : "\(currentDirectory)/\(relParent)"
                } else {
                    targetDir = currentDirectory
                }
                
                uploadProgressText = "\(LocalizationManager.shared.string("files_uploading")) \(file.fileName)"
                
                let fileData = try Data(contentsOf: file.localURL)
                if !isDemo {
                    let uploadURL = try await filesService.getUploadURL(serverId: server.identifier, directory: targetDir)
                    try await filesService.uploadFile(
                        uploadURL: uploadURL,
                        directory: targetDir,
                        fileName: file.fileName,
                        fileData: fileData
                    )
                }
                
                currentStep += 1.0
                uploadProgress = currentStep / totalSteps
            }
            
            isUploadingFiles = false
            uploadProgress = 1.0
            
            if plan.filesToUpload.count == 1 && plan.directoriesToCreate.isEmpty {
                let singleName = plan.filesToUpload[0].fileName
                fileSuccessMessage = LocalizationManager.shared.string("files_upload_success_single", singleName)
            } else {
                let count = plan.filesToUpload.count + plan.directoriesToCreate.count
                fileSuccessMessage = LocalizationManager.shared.string("files_upload_success_multiple", count)
            }
            
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                if self?.fileSuccessMessage != nil {
                    self?.fileSuccessMessage = nil
                }
            }
            
            await loadFiles()
        } catch {
            isUploadingFiles = false
            fileErrorMessage = (error as? FileUploadError)?.localizedMessage ?? error.localizedDescription
        }
    }
    
    // MARK: - Subdomains & Subusers
    public func loadSubdomains(force: Bool = false) async {
        if isLoading && !force { return }
        isLoading = true
        do {
            let loadedSubdomains = try await configService.fetchSubdomains(serverId: server.identifier)
            let loadedDomains = try await configService.fetchAvailableDomains()
            self.subdomains = loadedSubdomains
            self.availableDomains = loadedDomains
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    public func createSubdomain(subdomain: String, domainName: String) async {
        isLoading = true
        do {
            try await configService.createSubdomain(serverId: server.identifier, subdomain: subdomain, domainName: domainName)
            await loadSubdomains()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    public func deleteSubdomain(_ id: String) async {
        do {
            try await configService.deleteSubdomain(serverId: server.identifier, subdomainId: id)
            await loadSubdomains()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    public func loadSubusers(force: Bool = false) async {
        if isLoading && !force { return }
        isLoading = true
        do {
            let loadedUsers = try await configService.fetchSubusers(serverId: server.identifier)
            self.subusers = loadedUsers
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    public func addSubuser(email: String, permissions: [String]) async {
        do {
            try await configService.createSubuser(serverId: server.identifier, email: email, permissions: permissions)
            await loadSubusers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    public func deleteSubuser(_ userId: String) async {
        do {
            try await configService.deleteSubuser(serverId: server.identifier, userId: userId)
            await loadSubusers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Package
    public func loadPackageResources() async {
        self.packageRamMB = server.memoryLimitMB
        self.packageDiskMB = server.diskLimitMB
        self.packageCpuPercent = server.cpuLimitPercent
        
        if let res = try? await AuthService.shared.fetchResources() {
            let remainingRam = res.remaining.ram
            let remainingDisk = res.remaining.disk
            let remainingCpu = res.remaining.cpu
            
            let allowedMaxRam = max(server.memoryLimitMB + remainingRam, server.memoryLimitMB)
            let allowedMaxDisk = max(server.diskLimitMB + remainingDisk, server.diskLimitMB)
            let allowedMaxCpu = max(server.cpuLimitPercent + remainingCpu, server.cpuLimitPercent)
            
            self.maxAvailableRamMB = max(allowedMaxRam, 512)
            self.maxAvailableDiskMB = max(allowedMaxDisk, 1024)
            self.maxAvailableCpuPercent = max(allowedMaxCpu, 50)
        }
    }
    
    public func setMaxPackageResources() {
        self.packageRamMB = maxAvailableRamMB
        self.packageDiskMB = maxAvailableDiskMB
        self.packageCpuPercent = maxAvailableCpuPercent
    }
    
    public func savePackageChanges() {
        isSavingPackage = true
        errorMessage = nil
        successMessage = nil
        Task {
            do {
                try await configService.modifyServerResources(
                    serverId: server.identifier,
                    ramMB: Int(packageRamMB),
                    diskMB: Int(packageDiskMB),
                    cpuPercent: Int(packageCpuPercent)
                )
                server.memoryLimitMB = packageRamMB
                server.diskLimitMB = packageDiskMB
                server.cpuLimitPercent = packageCpuPercent
                successMessage = "Server resources updated successfully"
            } catch {
                errorMessage = error.localizedDescription
            }
            isSavingPackage = false
        }
    }
    
    // MARK: - Plugins
    public func loadPlugins(force: Bool = false) async {
        if isLoading && !force { return }
        isLoading = true
        do {
            let loadedPlugins = try await configService.fetchInstalledPlugins(serverId: server.identifier)
            self.installedPlugins = loadedPlugins
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    public func searchPlugins() async {
        guard !pluginSearchQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearchingPlugins = true
        do {
            pluginSearchResults = try await configService.searchPlugins(query: pluginSearchQuery)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSearchingPlugins = false
    }
    
    public func installPlugin(_ item: ServerPluginItem) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        do {
            try await configService.installPlugin(serverId: server.identifier, pluginId: item.id, platform: item.platform)
            successMessage = "Plugin \(item.name) installed successfully"
            await loadPlugins()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    public func untrackPlugin(_ item: ServerPluginItem) async {
        do {
            try await configService.untrackPlugin(serverId: server.identifier, pluginId: item.id, platform: item.platform)
            await loadPlugins()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Logs & Settings
    public func loadLogs(force: Bool = false) async {
        if isLoading && !force { return }
        isLoading = true
        do {
            let loadedLogs = try await configService.fetchLogs(serverId: server.identifier)
            self.activityLogs = loadedLogs
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    public func loadSettings(force: Bool = false) async {
        if isLoading && !force { return }
        isLoading = true
        do {
            let loadedVars = try await configService.fetchVariables(serverId: server.identifier)
            self.startupVariables = loadedVars
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    public func renameServer(newName: String) async {
        do {
            try await configService.renameServer(serverId: server.identifier, name: newName)
            successMessage = "Server renamed successfully"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    public func deleteServer() async -> Bool {
        isDeleting = true
        errorMessage = nil
        do {
            try await serverService.deleteServer(serverId: server.identifier)
            isDeleting = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isDeleting = false
            return false
        }
    }
    
    public func reinstallServer() async {
        do {
            try await configService.reinstallServer(serverId: server.identifier)
            successMessage = "Server reinstall initiated"
            appendConsoleLine("[System] Server reinstallation initiated.")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    public func updateStartupVariable(key: String, value: String) async {
        do {
            try await configService.updateVariable(serverId: server.identifier, key: key, value: value)
            successMessage = "Variable updated"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
