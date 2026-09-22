import SwiftUI

public struct CreateServerResourceSectionView: View {
    @ObservedObject var loc = LocalizationManager.shared
    @ObservedObject var vm: CreateServerViewModel
    
    public init(vm: CreateServerViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(loc.string("create_server_resources_title"))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(OvernodeTheme.textPrimary)
            
            let rem = vm.options?.resources.remaining ?? ResourceBucket(ram: 4096, disk: 20480, cpu: 200, servers: 2)
            let minRam = max(128.0, vm.selectedEgg?.minimum.ram ?? 128.0)
            let minCpu = max(10.0, vm.selectedEgg?.minimum.cpu ?? 10.0)
            let minDisk = max(256.0, vm.selectedEgg?.minimum.disk ?? 256.0)
            
            // RAM Slider
            resourceSliderRow(
                title: loc.string("resource_ram"),
                icon: "chart.pie",
                color: Color(red: 0.35, green: 0.55, blue: 0.95),
                value: $vm.ramMB,
                minValue: minRam,
                rawMax: rem.ram,
                step: 256,
                unit: "MB",
                remaining: rem.ram
            )
            
            // CPU Slider
            resourceSliderRow(
                title: loc.string("resource_cpu"),
                icon: "cpu",
                color: Color(red: 0.20, green: 0.75, blue: 0.85),
                value: $vm.cpuPercent,
                minValue: minCpu,
                rawMax: rem.cpu,
                step: 25,
                unit: "%",
                remaining: rem.cpu
            )
            
            // Disk Slider
            resourceSliderRow(
                title: loc.string("resource_disk"),
                icon: "archivebox",
                color: Color(red: 0.25, green: 0.78, blue: 0.50),
                value: $vm.diskMB,
                minValue: minDisk,
                rawMax: rem.disk,
                step: 512,
                unit: "MB",
                remaining: rem.disk
            )
        }
        .padding(16)
        .background(OvernodeTheme.cardBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(OvernodeTheme.borderSubtle, lineWidth: 1)
        )
    }
    
    private func resourceSliderRow(
        title: String,
        icon: String,
        color: Color,
        value: Binding<Double>,
        minValue: Double,
        rawMax: Double,
        step: Double,
        unit: String,
        remaining: Double
    ) -> some View {
        let safeMax = max(minValue + step, rawMax)
        let isQuotaExceeded = remaining < minValue
        
        return VStack(spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                        .foregroundColor(color)
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                
                Spacer()
                
                Text(String(format: "%.0f %@", value.wrappedValue, unit))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(OvernodeTheme.textPrimary)
                
                Text(String(format: "(%@: %.0f %@)", loc.string("create_server_remaining"), remaining, unit))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(isQuotaExceeded ? Color(red: 0.95, green: 0.35, blue: 0.35) : OvernodeTheme.textMuted)
            }
            
            Slider(
                value: Binding(
                    get: { min(safeMax, max(minValue, value.wrappedValue)) },
                    set: { value.wrappedValue = $0 }
                ),
                in: minValue...safeMax,
                step: step
            )
            .tint(color)
            .disabled(isQuotaExceeded)
        }
    }
}

