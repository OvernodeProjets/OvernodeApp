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
    
    // Files
    @Published public var currentDirectory: String = "/"
    @Published public var files: [ServerFileItem] = []
    @Published public var selectedFile: ServerFileItem?
    @Published public var fileEditorContent: String = ""
    @Published public var isFileLoading: Bool = false
    @Published public var isFileSaving: Bool = false
    
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
    
    private let serverService = ServerService.shared
    private let filesService = ServerFilesService.shared
    private let configService = ServerConfigService.shared
    
    public init(server: ServerInstance) {
        self.server = server
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
    public func loadRenewal() async {
        isLoading = true
        renewalStatus = await serverService.fetchRenewalStatus(serverId: server.identifier)
        isLoading = false
    }
    
    public func renewServer() {
        isRenewing = true
        errorMessage = nil
        successMessage = nil
        
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
                    successMessage = res.message ?? "Server renewed successfully"
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
    public func loadFiles(directory: String? = nil) async {
        if let dir = directory {
            currentDirectory = dir
        }
        isFileLoading = true
        errorMessage = nil
        do {
            files = try await filesService.listFiles(serverId: server.identifier, directory: currentDirectory)
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
    
    public func saveCurrentFile() {
        guard let item = selectedFile else { return }
        isFileSaving = true
        let fullPath = currentDirectory == "/" ? "/\(item.name)" : "\(currentDirectory)/\(item.name)"
        Task {
            do {
                try await filesService.writeFile(serverId: server.identifier, filePath: fullPath, content: fileEditorContent)
                successMessage = "File saved successfully"
            } catch {
                errorMessage = error.localizedDescription
            }
            isFileSaving = false
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
    
    // MARK: - Subdomains & Subusers
    public func loadSubdomains() async {
        isLoading = true
        do {
            subdomains = try await configService.fetchSubdomains(serverId: server.identifier)
            availableDomains = try await configService.fetchAvailableDomains()
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
    
    public func loadSubusers() async {
        isLoading = true
        do {
            subusers = try await configService.fetchSubusers(serverId: server.identifier)
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
    public func loadPlugins() async {
        isLoading = true
        do {
            installedPlugins = try await configService.fetchInstalledPlugins(serverId: server.identifier)
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
    public func loadLogs() async {
        isLoading = true
        do {
            activityLogs = try await configService.fetchLogs(serverId: server.identifier)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    public func loadSettings() async {
        isLoading = true
        do {
            startupVariables = try await configService.fetchVariables(serverId: server.identifier)
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
