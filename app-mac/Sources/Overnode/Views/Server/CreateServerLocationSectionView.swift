import SwiftUI

public struct CreateServerLocationSectionView: View {
    @ObservedObject var loc = LocalizationManager.shared
    @ObservedObject var vm: CreateServerViewModel
    
    public init(vm: CreateServerViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            
            if let locations = vm.options?.locations, !locations.isEmpty {
                locationsGrid(locations: locations)
                nodeSelectionSection
            }
        }
    }
    
    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "network")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(OvernodeTheme.accentGold)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(loc.string("create_server_location_label"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(OvernodeTheme.textPrimary)
                Text(loc.string("create_server_location_subtitle"))
                    .font(.system(size: 11))
                    .foregroundColor(OvernodeTheme.textSecondary)
            }
        }
    }
    
    private func locationsGrid(locations: [ServerLocation]) -> some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(locations) { locItem in
                locationCard(locItem: locItem)
            }
        }
    }
    
    private func locationCard(locItem: ServerLocation) -> some View {
        let isSelected = vm.selectedLocation?.id == locItem.id
        let info = LocationHelper.format(location: locItem)
        let isFull = locItem.full
        
        return Button(action: {
            guard !isFull else { return }
            vm.selectLocation(locItem)
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? OvernodeTheme.accentGold.opacity(0.18) : Color.white.opacity(0.05))
                        .frame(width: 40, height: 40)
                    Text(info.flag)
                        .font(.system(size: 20))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(info.countryName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(OvernodeTheme.textPrimary)
                        
                        if isFull {
                            Text(loc.string("create_server_location_status_full"))
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.2))
                                .foregroundColor(Color.red)
                                .cornerRadius(4)
                        } else {
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                Text(info.pingText)
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(OvernodeTheme.textMuted)
                            }
                        }
                    }
                    
                    Text(info.regionName)
                        .font(.system(size: 10.5))
                        .foregroundColor(OvernodeTheme.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(OvernodeTheme.accentGold)
                }
            }
            .padding(12)
            .background(isSelected ? OvernodeTheme.accentGold.opacity(0.12) : OvernodeTheme.secondaryCardBackground)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? OvernodeTheme.accentGold : OvernodeTheme.borderSubtle, lineWidth: isSelected ? 1.5 : 1)
            )
            .opacity(isFull ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isFull)
    }
    
    @ViewBuilder
    private var nodeSelectionSection: some View {
        let nodes = vm.availableNodes
        if !nodes.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                if nodes.count > 1 {
                    Text(loc.string("create_server_node_selection_title"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(OvernodeTheme.textSecondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(nodes) { node in
                                nodeChipButton(node: node)
                            }
                        }
                    }
                } else if let singleNode = nodes.first {
                    singleNodeInfoRow(node: singleNode)
                }
            }
            .padding(10)
            .background(OvernodeTheme.cardBackground.opacity(0.7))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(OvernodeTheme.borderSubtle, lineWidth: 1)
            )
        }
    }
    
    private func nodeChipButton(node: ServerNode) -> some View {
        let isSelected = vm.effectiveNode?.id == node.id
        let nodeInfo = LocationHelper.format(node: node)
        
        return Button(action: {
            vm.selectedNode = node
        }) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "bolt.fill" : "server.rack")
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? OvernodeTheme.accentGold : OvernodeTheme.textSecondary)
                
                Text(nodeInfo.displayName)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium, design: .monospaced))
                    .foregroundColor(OvernodeTheme.textPrimary)
                
                Text(nodeInfo.city)
                    .font(.system(size: 10))
                    .foregroundColor(OvernodeTheme.textSecondary)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(OvernodeTheme.accentGold)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? OvernodeTheme.accentGold.opacity(0.18) : Color.white.opacity(0.04))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? OvernodeTheme.accentGold : OvernodeTheme.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func singleNodeInfoRow(node: ServerNode) -> some View {
        let nodeInfo = LocationHelper.format(node: node)
        
        return HStack(spacing: 8) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 12))
                .foregroundColor(OvernodeTheme.accentSuccess)
            
            Text("\(loc.string("create_server_node_label")) : \(nodeInfo.displayName) (\(nodeInfo.city))")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(OvernodeTheme.textPrimary)
            
            Spacer()
            
            Text(loc.string("create_server_location_game_ddos"))
                .font(.system(size: 9.5, weight: .semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.12))
                .foregroundColor(OvernodeTheme.accentSuccess)
                .cornerRadius(4)
        }
    }
}
