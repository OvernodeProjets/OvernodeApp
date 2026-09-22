import SwiftUI

public struct StoreResourcesView: View {
    @ObservedObject var vm: StoreViewModel
    @ObservedObject var loc = LocalizationManager.shared
    let onResourcePurchased: (Int) -> Void
    
    public init(vm: StoreViewModel, onResourcePurchased: @escaping (Int) -> Void) {
        self.vm = vm
        self.onResourcePurchased = onResourcePurchased
    }
    
    public var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            // RAM Card
            StoreResourceCardItemView(
                type: "ram",
                title: loc.string("store_ram_title"),
                description: loc.string("store_ram_desc"),
                unitMultiplier: "1024 Mo",
                costPerUnit: vm.storeConfig?.prices?.resources?["ram"] ?? 600,
                iconName: "chart.pie.fill",
                iconColor: Color(red: 0.35, green: 0.55, blue: 0.95),
                userCoins: vm.userCoins,
                isPurchasing: vm.isPurchasing,
                onBuy: { amount in
                    vm.buyResource(resourceType: "ram", amount: amount, onSuccess: onResourcePurchased)
                }
            )
            
            // Storage Card
            StoreResourceCardItemView(
                type: "disk",
                title: loc.string("store_disk_title"),
                description: loc.string("store_disk_desc"),
                unitMultiplier: "5120 Mo",
                costPerUnit: vm.storeConfig?.prices?.resources?["disk"] ?? 400,
                iconName: "archivebox.fill",
                iconColor: Color(red: 0.25, green: 0.78, blue: 0.50),
                userCoins: vm.userCoins,
                isPurchasing: vm.isPurchasing,
                onBuy: { amount in
                    vm.buyResource(resourceType: "disk", amount: amount, onSuccess: onResourcePurchased)
                }
            )
            
            // CPU Card
            StoreResourceCardItemView(
                type: "cpu",
                title: loc.string("store_cpu_title"),
                description: loc.string("store_cpu_desc"),
                unitMultiplier: "100%",
                costPerUnit: vm.storeConfig?.prices?.resources?["cpu"] ?? 500,
                iconName: "cpu.fill",
                iconColor: Color(red: 0.20, green: 0.75, blue: 0.85),
                userCoins: vm.userCoins,
                isPurchasing: vm.isPurchasing,
                onBuy: { amount in
                    vm.buyResource(resourceType: "cpu", amount: amount, onSuccess: onResourcePurchased)
                }
            )
            
            // Slots Card
            StoreResourceCardItemView(
                type: "servers",
                title: loc.string("store_servers_title"),
                description: loc.string("store_servers_desc"),
                unitMultiplier: "1 slot",
                costPerUnit: vm.storeConfig?.prices?.resources?["servers"] ?? 200,
                iconName: "server.rack",
                iconColor: Color(red: 0.58, green: 0.45, blue: 0.92),
                userCoins: vm.userCoins,
                isPurchasing: vm.isPurchasing,
                onBuy: { amount in
                    vm.buyResource(resourceType: "servers", amount: amount, onSuccess: onResourcePurchased)
                }
            )
        }
    }
}
