import SwiftUI
import AppKit

public struct NewFolderSheetView: View {
    @ObservedObject var vm: ServerDetailViewModel
    @ObservedObject var loc = LocalizationManager.shared
    @Binding var isPresented: Bool
    @Binding var folderName: String
    
    @State private var isSyncEnabled = false
    @State private var selectedLocalURL: URL?
    @State private var initialPull = true
    
    public init(vm: ServerDetailViewModel, isPresented: Binding<Bool>, folderName: Binding<String>) {
        self.vm = vm
        self._isPresented = isPresented
        self._folderName = folderName
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: isSyncEnabled ? "folder.badge.gearshape" : "folder.badge.plus")
                    .font(.system(size: 16))
                    .foregroundColor(OvernodeTheme.accentGold)
                
                Text(loc.string("files_new_folder_title"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(OvernodeTheme.textPrimary)
            }
            
            // Remote Folder Name Input
            VStack(alignment: .leading, spacing: 6) {
                Text(loc.string("files_folder_placeholder"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(OvernodeTheme.textSecondary)
                
                TextField(loc.string("files_folder_placeholder"), text: $folderName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13))
            }
            
            // Sync Option Toggle
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $isSyncEnabled) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12))
                            .foregroundColor(isSyncEnabled ? Color(red: 0.25, green: 0.78, blue: 0.50) : OvernodeTheme.textSecondary)
                        Text(loc.string("files_sync_folder_enable"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(OvernodeTheme.textPrimary)
                    }
                }
                .toggleStyle(.checkbox)
                
                if isSyncEnabled {
                    syncSettingsSection
                }
            }
            .padding(12)
            .background(Color(red: 0.10, green: 0.11, blue: 0.14))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSyncEnabled ? OvernodeTheme.accentGold.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 1)
            )
            
            // Action Buttons
            HStack {
                Spacer()
                Button(loc.string("generic_cancel")) {
                    isPresented = false
                }
                .buttonStyle(.plain)
                .foregroundColor(OvernodeTheme.textSecondary)
                
                Button(loc.string("generic_create")) {
                    submitCreation()
                }
                .buttonStyle(.borderedProminent)
                .tint(OvernodeTheme.accentGold)
                .disabled(folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 440)
        .background(OvernodeTheme.cardBackground)
    }
    
    @ViewBuilder
    private var syncSettingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(loc.string("files_sync_local_location"))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(OvernodeTheme.textSecondary)
            
            HStack {
                Image(systemName: "laptopcomputer")
                    .font(.system(size: 13))
                    .foregroundColor(OvernodeTheme.accentGold)
                
                Text(selectedLocalURL?.path ?? defaultLocalPath)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(OvernodeTheme.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                Button(loc.string("files_sync_choose_location")) {
                    chooseLocalFolder()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(OvernodeTheme.accentGold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.06))
                .cornerRadius(4)
            }
            .padding(8)
            .background(Color.black.opacity(0.2))
            .cornerRadius(6)
            
            Toggle(isOn: $initialPull) {
                Text(loc.string("files_sync_initial_download"))
                    .font(.system(size: 12))
                    .foregroundColor(OvernodeTheme.textSecondary)
            }
            .toggleStyle(.checkbox)
        }
    }
    
    private var defaultLocalPath: String {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? "~"
        let cleanName = folderName.trimmingCharacters(in: .whitespacesAndNewlines)
        let sub = cleanName.isEmpty ? "sync-folder" : cleanName
        return "\(docs)/Overnode/\(vm.server.name)/\(sub)"
    }
    
    private func chooseLocalFolder() {
        let panel = NSOpenPanel()
        panel.title = loc.string("files_sync_choose_location")
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            selectedLocalURL = url
        }
    }
    
    private func submitCreation() {
        let name = folderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        isPresented = false
        
        if isSyncEnabled {
            let localURL = selectedLocalURL ?? URL(fileURLWithPath: (defaultLocalPath as NSString).expandingTildeInPath)
            Task {
                await vm.createSyncedFolder(name: name, localURL: localURL, initialPull: initialPull)
            }
        } else {
            Task {
                await vm.createFolder(name: name)
            }
        }
    }
}
