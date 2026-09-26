import SwiftUI
import UniformTypeIdentifiers

public struct ServerFilesTabView: View {
    @ObservedObject var vm: ServerDetailViewModel
    @ObservedObject var loc = LocalizationManager.shared
    @State private var showingNewFolderSheet = false
    @State private var newFolderName = ""
    @State private var isDropTargeted = false
    
    public init(vm: ServerDetailViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 14) {
                // Path Navigation & Action Bar
                HStack(spacing: 12) {
                    // Parent folder navigation button
                    if vm.currentDirectory != "/" {
                        Button(action: {
                            navigateToParent()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 11, weight: .bold))
                                Text(loc.string("files_parent_dir"))
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(OvernodeTheme.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(red: 0.125, green: 0.133, blue: 0.161))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Breadcrumbs
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .font(.system(size: 13))
                            .foregroundColor(OvernodeTheme.accentGold)
                        
                        Text(vm.currentDirectory)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(OvernodeTheme.textPrimary)
                    }
                    
                    Spacer()
                    
                    // Refresh button
                    Button(action: {
                        Task { await vm.loadFiles() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundColor(OvernodeTheme.textSecondary)
                            .padding(7)
                            .background(Color(red: 0.125, green: 0.133, blue: 0.161))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    // New Folder Button
                    Button(action: {
                        newFolderName = ""
                        showingNewFolderSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 12))
                            Text(loc.string("files_new_folder"))
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(Color.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.125, green: 0.133, blue: 0.161))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
                
                // Status & Feedback Banners
                if let success = vm.fileSuccessMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(red: 0.25, green: 0.78, blue: 0.50))
                        Text(success)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 0.25, green: 0.78, blue: 0.50))
                        Spacer()
                        Button(action: { vm.fileSuccessMessage = nil }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10))
                                .foregroundColor(Color(red: 0.25, green: 0.78, blue: 0.50).opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.25, green: 0.78, blue: 0.50).opacity(0.12))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(red: 0.25, green: 0.78, blue: 0.50).opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                if let err = vm.fileErrorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color(red: 0.95, green: 0.35, blue: 0.35))
                        Text(err)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 0.95, green: 0.35, blue: 0.35))
                        Spacer()
                        Button(action: { vm.fileErrorMessage = nil }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10))
                                .foregroundColor(Color(red: 0.95, green: 0.35, blue: 0.35).opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.12))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 4)
                }
                
                if vm.isUploadingFiles {
                    FileUploadProgressView(
                        progress: vm.uploadProgress,
                        statusText: vm.uploadProgressText
                    )
                }
                
                // Files Table / List
                if vm.isFileLoading && vm.files.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        ProgressView()
                        Text(loc.string("files_loading"))
                            .font(.system(size: 13))
                            .foregroundColor(OvernodeTheme.textSecondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else if vm.files.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "tray")
                            .font(.system(size: 32))
                            .foregroundColor(OvernodeTheme.textMuted)
                        Text(loc.string("files_empty_directory"))
                            .font(.system(size: 13))
                            .foregroundColor(OvernodeTheme.textSecondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(vm.files) { item in
                                FileRowView(
                                    item: item,
                                    isSynced: vm.isFolderSynced(item: item),
                                    onOpen: { vm.openFile(item) },
                                    onOpenInternal: { vm.openFileInternally(item) },
                                    onOpenExternal: { forceChoose in
                                        vm.openFileInExternalEditor(item, forceChooseEditor: forceChoose)
                                    },
                                    onPromptSync: { vm.promptSyncFolder(item: item) },
                                    onOpenFinder: { vm.openSyncedFolderInFinder(item: item) },
                                    onForceSync: { Task { await vm.forceSyncFolder(item: item) } },
                                    onStopSync: { vm.stopSyncFolder(item: item) },
                                    onDelete: {
                                        Task { await vm.deleteFile(item) }
                                    },
                                    onDrag: {
                                        vm.itemProviderForDrag(item: item)
                                    }
                                )
                            }
                        }
                        .background(OvernodeTheme.cardBackground)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                    }
                }
            }
            
            if isDropTargeted {
                FileDropOverlayView()
            }
        }
        .onDrop(of: [UTType.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
        .sheet(item: $vm.selectedFile) { _ in
            FileEditorSheetView(vm: vm)
        }
        .sheet(isPresented: $showingNewFolderSheet) {
            NewFolderSheetView(vm: vm, isPresented: $showingNewFolderSheet, folderName: $newFolderName)
        }
        .onAppear {
            Task { await vm.loadFiles() }
        }
    }
    
    private func navigateToParent() {
        guard vm.currentDirectory != "/" else { return }
        var parts = vm.currentDirectory.split(separator: "/").map(String.init)
        if !parts.isEmpty {
            parts.removeLast()
        }
        let parent = parts.isEmpty ? "/" : "/" + parts.joined(separator: "/")
        Task { await vm.loadFiles(directory: parent) }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        Task { @MainActor in
            var droppedURLs: [URL] = []
            for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                if let url = await loadURL(from: provider) {
                    droppedURLs.append(url)
                }
            }
            guard !droppedURLs.isEmpty else { return }
            await vm.uploadDroppedURLs(droppedURLs)
        }
        return true
    }
    
    private func loadURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                if let url = item as? URL {
                    continuation.resume(returning: url)
                } else if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    continuation.resume(returning: url)
                } else if let str = item as? String, let url = URL(string: str) {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

// Subview: File Row
private struct FileRowView: View {
    @ObservedObject var loc = LocalizationManager.shared
    let item: ServerFileItem
    let isSynced: Bool
    let onOpen: () -> Void
    let onOpenInternal: () -> Void
    let onOpenExternal: (Bool) -> Void
    let onPromptSync: () -> Void
    let onOpenFinder: () -> Void
    let onForceSync: () -> Void
    let onStopSync: () -> Void
    let onDelete: () -> Void
    let onDrag: () -> NSItemProvider
    
    var iconName: String {
        if !item.isFile { return isSynced ? "folder.fill.badge.gearshape" : "folder.fill" }
        let ext = (item.name as NSString).pathExtension.lowercased()
        switch ext {
        case "json", "toml", "yml", "yaml", "xml", "properties": return "doc.text.fill"
        case "jar", "zip", "tar", "gz": return "archivebox.fill"
        case "log", "txt": return "text.alignleft"
        default: return "doc.fill"
        }
    }
    
    var iconColor: Color {
        if !item.isFile {
            return isSynced ? Color(red: 0.25, green: 0.78, blue: 0.50) : OvernodeTheme.accentGold
        }
        let ext = (item.name as NSString).pathExtension.lowercased()
        switch ext {
        case "json", "yml", "yaml", "properties": return Color(red: 0.35, green: 0.55, blue: 0.95)
        case "jar", "zip": return Color(red: 0.95, green: 0.65, blue: 0.20)
        default: return OvernodeTheme.textSecondary
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 15))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            HStack(spacing: 6) {
                Text(item.name)
                    .font(.system(size: 13, weight: item.isFile ? .regular : .semibold))
                    .foregroundColor(OvernodeTheme.textPrimary)
                    .lineLimit(1)
                
                if isSynced {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 9, weight: .bold))
                        Text(loc.string("files_sync_badge"))
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(Color(red: 0.25, green: 0.78, blue: 0.50))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(red: 0.25, green: 0.78, blue: 0.50).opacity(0.12))
                    .cornerRadius(4)
                }
            }
            
            Spacer()
            
            Text(item.formattedSize)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(OvernodeTheme.textSecondary)
                .frame(width: 90, alignment: .trailing)
            
            // Delete button
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(OvernodeTheme.textMuted)
            }
            .buttonStyle(.plain)
            .padding(.leading, 8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onOpen()
        }
        .onTapGesture(count: 1) {
            if !item.isFile {
                onOpen()
            }
        }
        .onDrag {
            onDrag()
        }
        .contextMenu {
            if item.isFile {
                Button(action: { onOpenExternal(false) }) {
                    Label(loc.string("files_context_open_external"), systemImage: "arrow.up.forward.app")
                }
                
                Button(action: { onOpenExternal(true) }) {
                    Label(loc.string("files_context_choose_editor"), systemImage: "ellipsis.rectangle")
                }
                
                Button(action: { onOpenInternal() }) {
                    Label(loc.string("files_context_open_internal"), systemImage: "macwindow")
                }
                
                Divider()
                
                Button(role: .destructive, action: onDelete) {
                    Label(loc.string("generic_delete"), systemImage: "trash")
                }
            } else {
                Button(action: onOpen) {
                    Label(loc.string("files_context_open_folder"), systemImage: "folder")
                }
                
                Divider()
                
                if isSynced {
                    Button(action: onOpenFinder) {
                        Label(loc.string("files_context_sync_open_finder"), systemImage: "arrow.up.forward.app")
                    }
                    
                    Button(action: onForceSync) {
                        Label(loc.string("files_context_sync_force"), systemImage: "arrow.triangle.2.circlepath")
                    }
                    
                    Button(role: .destructive, action: onStopSync) {
                        Label(loc.string("files_context_sync_stop"), systemImage: "xmark.circle")
                    }
                } else {
                    Button(action: onPromptSync) {
                        Label(loc.string("files_context_sync_enable"), systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                
                Divider()
                
                Button(role: .destructive, action: onDelete) {
                    Label(loc.string("generic_delete"), systemImage: "trash")
                }
            }
        }
    }
}

