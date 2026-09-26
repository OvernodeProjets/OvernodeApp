import SwiftUI

public struct CreateServerSoftwareSectionView: View {
    @ObservedObject var loc = LocalizationManager.shared
    @ObservedObject var vm: CreateServerViewModel
    
    public init(vm: CreateServerViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            categorySelector
            eggsGrid
        }
    }
    
    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(OvernodeTheme.accentGold)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(loc.string("create_server_software_label"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(OvernodeTheme.textPrimary)
                Text(loc.string("create_server_software_subtitle"))
                    .font(.system(size: 11))
                    .foregroundColor(OvernodeTheme.textSecondary)
            }
        }
    }
    
    @ViewBuilder
    private var categorySelector: some View {
        if let categories = vm.options?.categories, !categories.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories) { cat in
                        let isSelected = vm.selectedCategory.lowercased() == cat.id.lowercased()
                        Button(action: {
                            vm.selectedCategory = cat.id
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 11))
                                Text(cat.name)
                                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(isSelected ? OvernodeTheme.accentGold.opacity(0.18) : OvernodeTheme.secondaryCardBackground)
                            .foregroundColor(isSelected ? OvernodeTheme.accentGold : OvernodeTheme.textSecondary)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? OvernodeTheme.accentGold.opacity(0.8) : OvernodeTheme.borderSubtle, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private var eggsGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(vm.filteredEggs) { egg in
                CreateServerEggCardView(egg: egg, isSelected: vm.selectedEgg?.id == egg.id) {
                    vm.selectEgg(egg)
                }
            }
        }
    }
}
