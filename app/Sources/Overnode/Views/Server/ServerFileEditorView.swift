import SwiftUI

public struct FileEditorSheetView: View {
    @ObservedObject var vm: ServerDetailViewModel
    @ObservedObject var loc = LocalizationManager.shared
    
    public init(vm: ServerDetailViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(vm.selectedFile?.name ?? loc.string("files_editor_title"))
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundColor(OvernodeTheme.textPrimary)
                
                Spacer()
                
                Button(action: {
                    vm.saveCurrentFile()
                }) {
                    HStack(spacing: 6) {
                        if vm.isFileSaving {
                            ProgressView().scaleEffect(0.6)
                        } else {
                            Image(systemName: "checkmark")
                        }
                        Text(loc.string("files_save"))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(OvernodeTheme.accentGold)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(vm.isFileSaving)
                
                Button(action: {
                    vm.selectedFile = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
            }
            .padding(14)
            .background(OvernodeTheme.cardBackground)
            
            Divider().background(Color.white.opacity(0.06))
            
            TextEditor(text: $vm.fileEditorContent)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .padding(12)
                .background(Color(red: 0.05, green: 0.06, blue: 0.08))
                .foregroundColor(Color.white)
        }
        .frame(minWidth: 640, minHeight: 460)
        .background(OvernodeTheme.background)
    }
}

public struct NewFolderSheetView: View {
    @ObservedObject var vm: ServerDetailViewModel
    @ObservedObject var loc = LocalizationManager.shared
    @Binding var isPresented: Bool
    @Binding var folderName: String
    
    public init(vm: ServerDetailViewModel, isPresented: Binding<Bool>, folderName: Binding<String>) {
        self.vm = vm
        self._isPresented = isPresented
        self._folderName = folderName
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(loc.string("files_new_folder_title"))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(OvernodeTheme.textPrimary)
            
            TextField(loc.string("files_folder_placeholder"), text: $folderName)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13))
            
            HStack {
                Spacer()
                Button(loc.string("generic_cancel")) {
                    isPresented = false
                }
                .buttonStyle(.plain)
                .foregroundColor(OvernodeTheme.textSecondary)
                
                Button(loc.string("generic_create")) {
                    let name = folderName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    isPresented = false
                    Task { await vm.createFolder(name: name) }
                }
                .buttonStyle(.borderedProminent)
                .tint(OvernodeTheme.accentGold)
            }
        }
        .padding(20)
        .frame(width: 360)
        .background(OvernodeTheme.cardBackground)
    }
}

