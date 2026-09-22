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
        // Window styling on launch
        if let window = NSApplication.shared.windows.first {
            window.title = "Overnode"
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            window.backgroundColor = NSColor(red: 0.063, green: 0.071, blue: 0.094, alpha: 1.0)
            window.center()
        }
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
