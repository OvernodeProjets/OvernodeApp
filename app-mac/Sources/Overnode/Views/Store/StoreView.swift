import SwiftUI

public struct StoreView: View {
    @StateObject private var vm = StoreViewModel()
    @ObservedObject var loc = LocalizationManager.shared
    let initialCoins: Int
    let onResourcePurchased: (Int) -> Void
    
    public init(initialCoins: Int, onResourcePurchased: @escaping (Int) -> Void) {
        self.initialCoins = initialCoins
        self.onResourcePurchased = onResourcePurchased
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(loc.string("store_title"))
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(OvernodeTheme.textPrimary)
                            Text(loc.string("store_subtitle"))
                                .font(.system(size: 13))
                                .foregroundColor(OvernodeTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        // Balance display
                        HStack(spacing: 6) {
                            Image(systemName: "circle.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(OvernodeTheme.accentGold)
                            Text("\(vm.userCoins) " + loc.string("wallet_coins_suffix"))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(OvernodeTheme.textPrimary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.125, green: 0.133, blue: 0.161))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
                    }
                    
                    // Tabs: Resources vs Bundles
                    HStack(spacing: 8) {
                        tabButton(.resources, label: loc.string("store_tab_resources"))
                        tabButton(.bundles, label: loc.string("store_tab_bundles"))
                    }
                    .overlay(Rectangle().frame(height: 1).foregroundColor(OvernodeTheme.borderSubtle), alignment: .bottom)
                }
                .padding(.top, 4)
                
                // Success / Error alerts
                if let success = vm.successMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(red: 0.133, green: 0.773, blue: 0.365))
                        Text(success)
                            .font(.system(size: 13))
                            .foregroundColor(OvernodeTheme.textPrimary)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green.opacity(0.2), lineWidth: 1))
                }
                
                if let err = vm.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color.red)
                        Text(err)
                            .font(.system(size: 13))
                            .foregroundColor(Color.red.opacity(0.9))
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.2), lineWidth: 1))
                }
                
                // Tab content
                switch vm.selectedTab {
                case .resources:
                    StoreResourcesView(vm: vm) { rem in
                        onResourcePurchased(rem)
                    }
                case .bundles:
                    StoreBundlesView(vm: vm)
                }
                
                Spacer()
            }
            .padding(24)
        }
        .background(OvernodeTheme.background)
        .onAppear {
            vm.loadConfig(initialCoins: initialCoins)
        }
    }
    
    private func tabButton(_ tab: StoreTab, label: String) -> some View {
        Button(action: { vm.selectedTab = tab }) {
            HStack(spacing: 6) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 13, weight: vm.selectedTab == tab ? .semibold : .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundColor(vm.selectedTab == tab ? OvernodeTheme.textPrimary : OvernodeTheme.textSecondary)
            .overlay(
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(vm.selectedTab == tab ? Color.white : Color.clear),
                alignment: .bottom
            )
        }
        .buttonStyle(.plain)
    }
}
