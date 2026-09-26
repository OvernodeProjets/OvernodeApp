import SwiftUI
import AppKit

public struct ExternalEditorSettingsCardView: View {
    @ObservedObject var loc = LocalizationManager.shared
    @State private var alwaysOpen: Bool = ExternalEditorManager.shared.alwaysOpenInExternalEditor
    @State private var editorAppName: String? = ExternalEditorManager.shared.selectedEditorAppName
    @State private var editorAppPath: String? = ExternalEditorManager.shared.selectedEditorAppPath
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(OvernodeTheme.accentGold.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(OvernodeTheme.accentGold)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc.string("settings_external_editor_title"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    Text(loc.string("settings_external_editor_desc"))
                        .font(.system(size: 12))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                
                Spacer()
            }
            
            Divider()
                .background(OvernodeTheme.borderSubtle)
            
            // Toggle: Always open with external editor
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(loc.string("settings_external_editor_always_toggle"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    Text(loc.string("settings_external_editor_always_desc"))
                        .font(.system(size: 11))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $alwaysOpen)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .tint(OvernodeTheme.accentGold)
                    .onChange(of: alwaysOpen) { _, newValue in
                        ExternalEditorManager.shared.alwaysOpenInExternalEditor = newValue
                    }
            }
            
            // Editor Selection Details
            VStack(alignment: .leading, spacing: 10) {
                Text(loc.string("settings_external_editor_current"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(OvernodeTheme.textSecondary)
                
                if let appPath = editorAppPath, !appPath.isEmpty {
                    HStack(spacing: 12) {
                        if let icon = ExternalEditorManager.shared.selectedEditorAppIcon {
                            Image(nsImage: icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                        } else {
                            Image(systemName: "app.fill")
                                .font(.system(size: 24))
                                .foregroundColor(OvernodeTheme.accentGold)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(editorAppName ?? (appPath as NSString).lastPathComponent)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(OvernodeTheme.textPrimary)
                            Text(appPath)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(OvernodeTheme.textMuted)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            _ = ExternalEditorManager.shared.promptUserToSelectEditor()
                            refreshState()
                        }) {
                            Text(loc.string("settings_external_editor_change_btn"))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(OvernodeTheme.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            ExternalEditorManager.shared.resetEditor()
                            refreshState()
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(OvernodeTheme.textMuted)
                                .padding(6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(OvernodeTheme.secondaryCardBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.04), lineWidth: 1)
                    )
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: "questionmark.app.dashed")
                            .font(.system(size: 22))
                            .foregroundColor(OvernodeTheme.textMuted)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(loc.string("settings_external_editor_none"))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(OvernodeTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            _ = ExternalEditorManager.shared.promptUserToSelectEditor()
                            refreshState()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "folder")
                                Text(loc.string("settings_external_editor_select_btn"))
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(OvernodeTheme.accentGold)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(OvernodeTheme.secondaryCardBackground)
                    .cornerRadius(8)
                }
            }
        }
        .padding(18)
        .background(OvernodeTheme.cardBackground)
        .cornerRadius(10)
        .onReceive(NotificationCenter.default.publisher(for: ExternalEditorManager.didChangeNotification)) { _ in
            refreshState()
        }
    }
    
    private func refreshState() {
        alwaysOpen = ExternalEditorManager.shared.alwaysOpenInExternalEditor
        editorAppName = ExternalEditorManager.shared.selectedEditorAppName
        editorAppPath = ExternalEditorManager.shared.selectedEditorAppPath
    }
}
