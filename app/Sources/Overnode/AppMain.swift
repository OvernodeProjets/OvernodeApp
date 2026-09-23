import SwiftUI
import AppKit

@main
public struct OvernodeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            RootContentView()
                .preferredColorScheme(.dark)
                .frame(width: 1100, height: 740)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("À propos d'Overnode") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.applicationName: "Overnode",
                            NSApplication.AboutPanelOptionKey.version: "1.0.0",
                            NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "© 2026 Overnode Network"
                        ]
                    )
                }
            }
        }
    }
}

public class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Set application icon for Dock & AppKit
        if let iconURL = Bundle.appResourceURL(named: "AppIcon", withExtension: "icns") ?? Bundle.appResourceURL(named: "app_icon", withExtension: "png"),
           let iconImage = NSImage(contentsOf: iconURL) {
            NSApplication.shared.applicationIconImage = iconImage
        }

        if CommandLine.arguments.contains("--snapshot") {
            performSnapshot()
            return
        }
        
        // Window styling on launch
        if let window = NSApplication.shared.windows.first {
            window.title = "Overnode"
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            window.backgroundColor = NSColor(red: 0.063, green: 0.071, blue: 0.094, alpha: 1.0)
            window.center()
        }
    }
    
    @MainActor
    private func performSnapshot() {
        let args = CommandLine.arguments
        guard let idx = args.firstIndex(of: "--snapshot") else { return }
        let path = args.count > idx + 1 ? args[idx + 1] : "/tmp/overnode_server_detail.png"
        
        let isReal = args.contains("--real")
        if !isReal {
            setenv("OVERNODE_DEMO", "1", 1)
        }
        let server = ServerInstance(
            id: 1,
            identifier: "7f4c9a12",
            name: "Minecraft Survival",
            node: "Node FR-01",
            suspended: false,
            state: "running",
            memoryUsedMB: 2840,
            memoryLimitMB: 4096,
            cpuUsedPercent: 32.5,
            cpuLimitPercent: 200,
            diskUsedMB: 8120,
            diskLimitMB: 15360
        )
        let vm = ServerDetailViewModel(server: server)
        if let tabIdx = args.firstIndex(of: "--snapshot-tab"), args.count > tabIdx + 1 {
            let tabName = args[tabIdx + 1]
            if let tab = ServerTab(rawValue: tabName) {
                vm.selectedTab = tab
            }
        } else {
            vm.selectedTab = .console
        }
        
        let user = User(id: "1", username: "OvernodeUser", email: "user@overnode.fr", globalName: "Overnode User", role: "Client", avatarUrl: nil, coins: 350)
        let view = HStack(spacing: 0) {
            SidebarView(
                selectedTab: .constant(.servers),
                selectedServer: .constant(server),
                selectedServerTab: .constant(vm.selectedTab),
                user: user,
                onLogout: {}
            )
            ServerDetailView(vm: vm, selectedTab: .constant(vm.selectedTab), onBack: {})
        }
            .preferredColorScheme(.dark)
            .frame(width: 1100, height: 740)
        
        let finalView: AnyView
        if args.contains("--snapshot-update") {
            let updateVM = UpdateViewModel.shared
            updateVM.state = .available(
                UpdateCheckResponse(
                    updateAvailable: true,
                    clientVersion: "1.0.0",
                    latestVersion: "1.1.0",
                    downloadUrl: "https://zBvoGzjDABxGuLuKux59LtECbKIpNPcp.overnode.fr/downloads/Overnode-v1.1.0.zip",
                    releaseNotes: "• Système d'auto-mise à jour en temps réel\n• Compatibilité complète Apple Silicon\n• Optimisations et fluidité améliorée",
                    mandatory: false
                )
            )
            updateVM.showModal = true
            finalView = AnyView(RootContentView().preferredColorScheme(.dark).frame(width: 1100, height: 740))
        } else if args.contains("--snapshot-settings") {
            let authVM = AuthViewModel()
            finalView = AnyView(DashboardView(authVM: authVM, initialTab: .settings).preferredColorScheme(.dark).frame(width: 1100, height: 740))
        } else if args.contains("--snapshot-dashboard") {
            let authVM = AuthViewModel()
            finalView = AnyView(DashboardView(authVM: authVM).preferredColorScheme(.dark).frame(width: 1100, height: 740))
        } else {
            finalView = AnyView(view)
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1100, height: 740),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Overnode"
        window.titlebarAppearsTransparent = true
        window.backgroundColor = NSColor(red: 0.063, green: 0.071, blue: 0.094, alpha: 1.0)
        let hosting = NSHostingView(rootView: finalView)
        hosting.frame = NSRect(x: 0, y: 0, width: 1100, height: 740)
        window.contentView = hosting
        window.makeKeyAndOrderFront(nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            hosting.layoutSubtreeIfNeeded()
            if let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) {
                hosting.cacheDisplay(in: hosting.bounds, to: rep)
                if let pngData = rep.representation(using: .png, properties: [:]) {
                    try? pngData.write(to: URL(fileURLWithPath: path))
                    print("SNAPSHOT_SAVED:\(path)")
                    exit(0)
                }
            }
            
            let wid = window.windowNumber
            let task = Process()
            task.launchPath = "/usr/sbin/screencapture"
            task.arguments = ["-l\(wid)", "-o", path]
            task.launch()
            task.waitUntilExit()
            
            print("SNAPSHOT_SAVED:\(path)")
            exit(0)
        }
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

