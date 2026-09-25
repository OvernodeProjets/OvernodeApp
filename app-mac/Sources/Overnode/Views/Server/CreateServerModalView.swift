import SwiftUI

public struct CreateServerModalView: View {
    @ObservedObject var loc = LocalizationManager.shared
    @StateObject private var vm = CreateServerViewModel()
    let onDismiss: () -> Void
    let onServerCreated: (ServerInstance) -> Void
    
    public init(onDismiss: @escaping () -> Void, onServerCreated: @escaping (ServerInstance) -> Void) {
        self.onDismiss = onDismiss
        self.onServerCreated = onServerCreated
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            CreateServerHeaderView(onDismiss: onDismiss)
            
            if vm.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text(loc.string("create_server_loading"))
                        .font(.system(size: 13))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 18) {
                        generalInfoSection
                        locationSection
                        eggSection
                        CreateServerResourceSectionView(vm: vm)
                        
                        if let err = vm.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Color(red: 0.95, green: 0.35, blue: 0.35))
                                Text(err)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.95, green: 0.35, blue: 0.35))
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(red: 0.95, green: 0.35, blue: 0.35).opacity(0.12))
                            .cornerRadius(8)
                        }
                    }
                    .padding(20)
                }
            }
            
            CreateServerBottomBarView(
                vm: vm,
                onDismiss: onDismiss,
                onDeploy: {
                    Task {
                        if let newServer = await vm.deployServer() {
                            onServerCreated(newServer)
                            onDismiss()
                        }
                    }
                }
            )
        }
        .frame(width: 680, height: 620)
        .background(OvernodeTheme.background)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(OvernodeTheme.borderSubtle, lineWidth: 1)
        )
    }
    
    private var generalInfoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(loc.string("create_server_name_label"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(OvernodeTheme.textPrimary)
            
            TextField(loc.string("create_server_name_placeholder"), text: $vm.serverName)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(10)
                .background(Color(red: 0.125, green: 0.133, blue: 0.161))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(vm.serverName.isEmpty ? OvernodeTheme.borderSubtle : (vm.isNameValid ? OvernodeTheme.accentGold : Color.red.opacity(0.6)), lineWidth: 1)
                )
        }
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(loc.string("create_server_location_label"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(OvernodeTheme.textPrimary)
            
            if let locations = vm.options?.locations {
                HStack(spacing: 10) {
                    ForEach(locations) { locItem in
                        Button(action: { vm.selectLocation(locItem) }) {
                            HStack(spacing: 8) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(vm.selectedLocation?.id == locItem.id ? OvernodeTheme.accentGold : OvernodeTheme.textSecondary)
                                Text(locItem.name)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(OvernodeTheme.textPrimary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(vm.selectedLocation?.id == locItem.id ? OvernodeTheme.accentGold.opacity(0.15) : Color(red: 0.125, green: 0.133, blue: 0.161))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(vm.selectedLocation?.id == locItem.id ? OvernodeTheme.accentGold : OvernodeTheme.borderSubtle, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if !vm.availableNodes.isEmpty {
                        Picker(loc.string("create_server_node_label"), selection: Binding(
                            get: { vm.effectiveNode?.id ?? 0 },
                            set: { newId in
                                vm.selectedNode = vm.availableNodes.first(where: { $0.id == newId })
                            }
                        )) {
                            ForEach(vm.availableNodes) { node in
                                Text(node.name).tag(node.id)
                            }
                        }
                        .labelsHidden()
                        .frame(minWidth: 150)
                    }
                }
            }
        }
    }
    
    private var eggSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(loc.string("create_server_software_label"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(OvernodeTheme.textPrimary)
            
            if let categories = vm.options?.categories {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(categories) { cat in
                            Button(action: { vm.selectedCategory = cat.id }) {
                                Text(cat.name)
                                    .font(.system(size: 11, weight: vm.selectedCategory == cat.id ? .semibold : .regular))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(vm.selectedCategory == cat.id ? OvernodeTheme.accentGold.opacity(0.18) : Color.white.opacity(0.04))
                                    .foregroundColor(vm.selectedCategory == cat.id ? OvernodeTheme.accentGold : OvernodeTheme.textSecondary)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(vm.filteredEggs) { egg in
                    CreateServerEggCardView(egg: egg, isSelected: vm.selectedEgg?.id == egg.id) {
                        vm.selectEgg(egg)
                    }
                }
            }
        }
    }
}

