import SwiftUI

public struct ServerFilesTabView: View {
    @ObservedObject var vm: ServerDetailViewModel
    @ObservedObject var loc = LocalizationManager.shared
    @State private var showingNewFolderSheet = false
    @State private var newFolderName = ""
    
    public init(vm: ServerDetailViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
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
                                onOpen: { vm.openFile(item) },
                                onDelete: {
                                    Task { await vm.deleteFile(item) }
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
}

// Subview: File Row
private struct FileRowView: View {
    let item: ServerFileItem
    let onOpen: () -> Void
    let onDelete: () -> Void
    
    var iconName: String {
        if !item.isFile { return "folder.fill" }
        let ext = (item.name as NSString).pathExtension.lowercased()
        switch ext {
        case "json", "toml", "yml", "yaml", "xml", "properties": return "doc.text.fill"
        case "jar", "zip", "tar", "gz": return "archivebox.fill"
        case "log", "txt": return "text.alignleft"
        default: return "doc.fill"
        }
    }
    
    var iconColor: Color {
        if !item.isFile { return OvernodeTheme.accentGold }
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
            
            Text(item.name)
                .font(.system(size: 13, weight: item.isFile ? .regular : .semibold))
                .foregroundColor(OvernodeTheme.textPrimary)
                .lineLimit(1)
            
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
        .onTapGesture {
            onOpen()
        }
    }
}

