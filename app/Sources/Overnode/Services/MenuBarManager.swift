import AppKit
import Foundation
import Combine

@MainActor
public final class MenuBarManager: NSObject {
    public static let shared = MenuBarManager()
    
    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()
    private var autoRefreshTask: Task<Void, Never>?
    
    private var cachedServers: [ServerInstance] = []
    private var activeServer: ServerInstance?
    private var isPerformingAction: Bool = false
    
    private override init() {
        super.init()
    }
    
    public func setup() {
        if statusItem != nil { return }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = createMenuBarIcon()
            button.imagePosition = .imageOnly
            button.toolTip = "Overnode Quick Actions"
        }
        
        rebuildMenu()
        
        NotificationCenter.default.publisher(for: QuickActionServerStorage.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshSelectedServer()
            }
            .store(in: &cancellables)
            
        loadServersFromCache()
        refreshSelectedServer()
        startPeriodicRefresh()
    }
    
    public func updateServers(_ servers: [ServerInstance]) {
        self.cachedServers = servers
        refreshSelectedServer()
    }
    
    private func createMenuBarIcon() -> NSImage? {
        if let iconURL = Bundle.appResourceURL(named: "overnode_icon", withExtension: "png"),
           let originalImage = NSImage(contentsOf: iconURL) {
            let targetSize = NSSize(width: 18, height: 13)
            let resized = NSImage(size: targetSize)
            resized.lockFocus()
            originalImage.draw(
                in: NSRect(origin: .zero, size: targetSize),
                from: NSRect(origin: .zero, size: originalImage.size),
                operation: .copy,
                fraction: 1.0
            )
            resized.unlockFocus()
            resized.isTemplate = true
            return resized
        }
        
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        let sfImage = NSImage(systemSymbolName: "cloud.fill", accessibilityDescription: "Overnode")?
            .withSymbolConfiguration(config)
        sfImage?.isTemplate = true
        return sfImage
    }
    
    private func loadServersFromCache() {
        if let data = UserDefaults.standard.data(forKey: "overnode_cached_servers"),
           let list = try? JSONDecoder().decode([ServerInstance].self, from: data) {
            self.cachedServers = list
        }
    }
    
    private func refreshSelectedServer() {
        let selectedId = QuickActionServerStorage.shared.getSelectedServerIdentifier()
        if let id = selectedId, !id.isEmpty {
            self.activeServer = cachedServers.first { $0.identifier == id || String($0.id) == id }
        } else {
            self.activeServer = nil
        }
        rebuildMenu()
    }
    
    private func startPeriodicRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                if Task.isCancelled { break }
                await self?.fetchActiveServerState()
            }
        }
    }
    
    private func fetchActiveServerState() async {
        guard let srv = activeServer else { return }
        do {
            let live = try await ServerService.shared.fetchLiveResources(identifier: srv.identifier)
            await MainActor.run {
                if var cur = self.activeServer {
                    cur.state = live.state
                    cur.memoryUsedMB = live.memoryMB
                    cur.cpuUsedPercent = live.cpuPercent
                    cur.diskUsedMB = live.diskMB
                    self.activeServer = cur
                    self.rebuildMenu()
                }
            }
        } catch {
            // Keep current status if fetch fails
        }
    }
    
    public func rebuildMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false
        let loc = LocalizationManager.shared
        
        // Header / App Title
        let titleItem = NSMenuItem(title: "Overnode", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        if let font = NSFont.boldSystemFont(ofSize: 13) as NSFont? {
            titleItem.attributedTitle = NSAttributedString(
                string: "Overnode",
                attributes: [.font: font, .foregroundColor: NSColor.labelColor]
            )
        }
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())
        
        if let server = activeServer {
            // Server Info Item
            let serverTitle = "\(server.name)"
            let statusText = localizedServerState(server.state)
            let srvItem = NSMenuItem(title: "\(serverTitle) (\(statusText))", action: nil, keyEquivalent: "")
            srvItem.isEnabled = false
            menu.addItem(srvItem)
            
            // Server Resource Preview (RAM & CPU)
            let memUsed = String(format: "%.1f", server.memoryUsedMB)
            let memLimit = String(format: "%.0f", server.memoryLimitMB)
            let cpuUsed = String(format: "%.0f", server.cpuUsedPercent)
            let statsItem = NSMenuItem(
                title: "CPU: \(cpuUsed)%  •  RAM: \(memUsed)/\(memLimit) MB",
                action: nil,
                keyEquivalent: ""
            )
            statsItem.isEnabled = false
            menu.addItem(statsItem)
            
            menu.addItem(NSMenuItem.separator())
            
            // Power Actions
            let startItem = NSMenuItem(
                title: "▶  " + loc.string("menubar_action_start"),
                action: #selector(handleStartAction),
                keyEquivalent: ""
            )
            startItem.target = self
            startItem.isEnabled = !isPerformingAction && server.state.lowercased() != "running"
            menu.addItem(startItem)
            
            let restartItem = NSMenuItem(
                title: "↺  " + loc.string("menubar_action_restart"),
                action: #selector(handleRestartAction),
                keyEquivalent: ""
            )
            restartItem.target = self
            restartItem.isEnabled = !isPerformingAction
            menu.addItem(restartItem)
            
            let killItem = NSMenuItem(
                title: "⚡ " + loc.string("menubar_action_kill"),
                action: #selector(handleKillAction),
                keyEquivalent: ""
            )
            killItem.target = self
            killItem.isEnabled = !isPerformingAction
            menu.addItem(killItem)
        } else {
            let noSrvItem = NSMenuItem(
                title: loc.string("menubar_no_server_configured"),
                action: nil,
                keyEquivalent: ""
            )
            noSrvItem.isEnabled = false
            menu.addItem(noSrvItem)
            
            let configItem = NSMenuItem(
                title: loc.string("menubar_open_settings"),
                action: #selector(handleOpenSettingsAction),
                keyEquivalent: ","
            )
            configItem.target = self
            menu.addItem(configItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Open Main App
        let openAppItem = NSMenuItem(
            title: loc.string("menubar_open_app"),
            action: #selector(handleOpenAppAction),
            keyEquivalent: "o"
        )
        openAppItem.target = self
        menu.addItem(openAppItem)
        
        // Quit App
        let quitItem = NSMenuItem(
            title: loc.string("menubar_quit"),
            action: #selector(handleQuitAction),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    private func localizedServerState(_ state: String) -> String {
        let loc = LocalizationManager.shared
        switch state.lowercased() {
        case "running": return loc.string("menubar_server_running")
        case "starting": return loc.string("menubar_server_starting")
        case "stopping": return loc.string("menubar_server_stopping")
        case "suspended": return loc.string("menubar_server_suspended")
        default: return loc.string("menubar_server_offline")
        }
    }
    
    @objc private func handleStartAction() {
        triggerPowerSignal(.start)
    }
    
    @objc private func handleRestartAction() {
        triggerPowerSignal(.restart)
    }
    
    @objc private func handleKillAction() {
        let loc = LocalizationManager.shared
        let alert = NSAlert()
        alert.messageText = loc.string("power_kill_confirm_title")
        alert.informativeText = loc.string("menubar_action_kill_confirm")
        alert.alertStyle = .critical
        alert.addButton(withTitle: loc.string("power_kill"))
        alert.addButton(withTitle: loc.string("update_later"))
        
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            triggerPowerSignal(.kill)
        }
    }
    
    private func triggerPowerSignal(_ signal: ServerPowerSignal) {
        guard let srv = activeServer else { return }
        isPerformingAction = true
        rebuildMenu()
        
        Task {
            do {
                try await ServerService.shared.sendPowerSignal(serverId: srv.identifier, signal: signal)
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await self.fetchActiveServerState()
            } catch {
                // Ignore or log error
            }
            await MainActor.run {
                self.isPerformingAction = false
                self.rebuildMenu()
            }
        }
    }
    
    @objc private func handleOpenAppAction() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { !($0 is NSPanel) && $0.canBecomeKey }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc private func handleOpenSettingsAction() {
        handleOpenAppAction()
        NotificationCenter.default.post(name: Notification.Name("overnode_navigate_to_settings"), object: nil)
    }
    
    @objc private func handleQuitAction() {
        NSApplication.shared.terminate(nil)
    }
}
