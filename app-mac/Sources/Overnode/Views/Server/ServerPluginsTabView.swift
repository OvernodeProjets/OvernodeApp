import SwiftUI

public struct ServerPluginsTabView: View {
    @ObservedObject var vm: ServerDetailViewModel
    @ObservedObject var loc = LocalizationManager.shared
    @State private var pluginSubTab: Int = 0 // 0 = Installed, 1 = Search
    
    public init(vm: ServerDetailViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header & SubTab Picker
            HStack {
            Picker("", selection: $pluginSubTab) {
                Text(loc.string("plugins_tab_installed")).tag(0)
                Text(loc.string("plugins_tab_search")).tag(1)
            }
            .pickerStyle(.segmented)
            .frame(width: 280)
            .onChange(of: pluginSubTab) { _, newVal in
                if newVal == 1 && vm.pluginSearchResults.isEmpty {
                    Task { await vm.searchPlugins() }
                }
            }
            
            Spacer()
                
                Button(action: {
                    Task { await vm.loadPlugins() }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(OvernodeTheme.textSecondary)
                        .padding(7)
                        .background(Color(red: 0.125, green: 0.133, blue: 0.161))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            
            if let msg = vm.successMessage {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(red: 0.25, green: 0.78, blue: 0.50))
                    Text(msg)
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.25, green: 0.78, blue: 0.50))
                }
                .padding(8)
                .background(Color(red: 0.25, green: 0.78, blue: 0.50).opacity(0.1))
                .cornerRadius(6)
            }
            
            if let err = vm.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color(red: 0.95, green: 0.35, blue: 0.35))
                    Text(err)
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.95, green: 0.35, blue: 0.35))
                }
                .padding(8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }
            
            if pluginSubTab == 0 {
                // Installed Plugins List
                if vm.isLoading && vm.installedPlugins.isEmpty {
                    VStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 220)
                } else if vm.installedPlugins.isEmpty {
                    VStack(spacing: 10) {
                        Spacer()
                        Image(systemName: "puzzlepiece.extension")
                            .font(.system(size: 32))
                            .foregroundColor(OvernodeTheme.textMuted)
                        Text(loc.string("plugins_none_installed"))
                            .font(.system(size: 13))
                            .foregroundColor(OvernodeTheme.textSecondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 220)
                    .background(OvernodeTheme.cardBackground)
                    .cornerRadius(8)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(vm.installedPlugins) { p in
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color(red: 0.125, green: 0.133, blue: 0.161))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "puzzlepiece.fill")
                                            .foregroundColor(OvernodeTheme.accentGold)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(p.name)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(OvernodeTheme.textPrimary)
                                        
                                        if let desc = p.description, !desc.isEmpty {
                                            Text(desc)
                                                .font(.system(size: 11))
                                                .foregroundColor(OvernodeTheme.textSecondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Button(role: .destructive, action: {
                                        Task { await vm.untrackPlugin(p) }
                                    }) {
                                        Text(loc.string("plugins_uninstall"))
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(Color(red: 0.95, green: 0.40, blue: 0.40))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.red.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(12)
                                .background(OvernodeTheme.cardBackground)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            } else {
                // Search Plugins
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(OvernodeTheme.textSecondary)
                        
                        TextField(loc.string("plugins_search_placeholder"), text: $vm.pluginSearchQuery)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .onSubmit {
                                Task { await vm.searchPlugins() }
                            }
                        
                        Button(action: {
                            Task { await vm.searchPlugins() }
                        }) {
                            Text(loc.string("plugins_search_btn"))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(OvernodeTheme.accentGold)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(Color(red: 0.08, green: 0.09, blue: 0.11))
                    .cornerRadius(8)
                    
                    if vm.isSearchingPlugins {
                        ProgressView().padding(20)
                    } else if vm.pluginSearchResults.isEmpty && !vm.pluginSearchQuery.isEmpty {
                        Text(loc.string("plugins_no_results"))
                            .font(.system(size: 12))
                            .foregroundColor(OvernodeTheme.textSecondary)
                            .padding(20)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(vm.pluginSearchResults) { p in
                                    HStack(spacing: 12) {
                                        Image(systemName: "shippingbox.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color(red: 0.20, green: 0.75, blue: 0.85))
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(p.name)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(OvernodeTheme.textPrimary)
                                            if let desc = p.description {
                                                Text(desc)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(OvernodeTheme.textSecondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        let isInstalled = vm.installedPlugins.contains { $0.id == p.id || $0.name.lowercased() == p.name.lowercased() }
                                        Button(action: {
                                            Task { await vm.installPlugin(p) }
                                        }) {
                                            HStack(spacing: 4) {
                                                if isInstalled {
                                                    Image(systemName: "checkmark")
                                                    Text(loc.string("plugins_installed"))
                                                } else {
                                                    Image(systemName: "arrow.down.circle.fill")
                                                    Text(loc.string("plugins_install_btn"))
                                                }
                                            }
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(Color.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(isInstalled ? Color(red: 0.25, green: 0.78, blue: 0.50) : OvernodeTheme.accentGold)
                                            .cornerRadius(6)
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(isInstalled || vm.isLoading)
                                    }
                                    .padding(12)
                                    .background(OvernodeTheme.cardBackground)
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .onAppear {
            Task {
                await vm.loadPlugins()
                if vm.pluginSearchResults.isEmpty {
                    await vm.searchPlugins()
                }
            }
        }
    }
}
