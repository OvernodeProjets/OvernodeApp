import SwiftUI

public struct CreateServerResourceSectionView: View {
    @ObservedObject var loc = LocalizationManager.shared
    @ObservedObject var vm: CreateServerViewModel
    
    public init(vm: CreateServerViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            
            let rem = vm.options?.resources.remaining ?? ResourceBucket(ram: 4096, disk: 20480, cpu: 200, servers: 2)
            let minRam = max(128.0, vm.selectedEgg?.minimum.ram ?? 128.0)
            let minCpu = max(10.0, vm.selectedEgg?.minimum.cpu ?? 10.0)
            let minDisk = max(256.0, vm.selectedEgg?.minimum.disk ?? 256.0)
            
            VStack(spacing: 12) {
                // RAM Slider
                resourceRow(
                    title: loc.string("resource_ram"),
                    icon: "chart.pie.fill",
                    color: OvernodeTheme.accentBlue,
                    value: $vm.ramMB,
                    minValue: minRam,
                    rawMax: rem.ram,
                    step: 256,
                    unit: "MB",
                    remaining: rem.ram,
                    presets: [
                        (loc.string("create_server_preset_min"), minRam),
                        ("1 GB", 1024),
                        ("2 GB", 2048),
                        ("4 GB", 4096),
                        (loc.string("create_server_preset_max"), rem.ram)
                    ]
                )
                
                Divider().background(OvernodeTheme.borderSubtle)
                
                // CPU Slider
                resourceRow(
                    title: loc.string("resource_cpu"),
                    icon: "cpu",
                    color: OvernodeTheme.accentCyan,
                    value: $vm.cpuPercent,
                    minValue: minCpu,
                    rawMax: rem.cpu,
                    step: 25,
                    unit: "%",
                    remaining: rem.cpu,
                    presets: [
                        (loc.string("create_server_preset_min"), minCpu),
                        ("50%", 50),
                        ("100%", 100),
                        ("200%", 200),
                        (loc.string("create_server_preset_max"), rem.cpu)
                    ]
                )
                
                Divider().background(OvernodeTheme.borderSubtle)
                
                // Disk Slider
                resourceRow(
                    title: loc.string("resource_disk"),
                    icon: "archivebox.fill",
                    color: OvernodeTheme.accentSuccess,
                    value: $vm.diskMB,
                    minValue: minDisk,
                    rawMax: rem.disk,
                    step: 512,
                    unit: "MB",
                    remaining: rem.disk,
                    presets: [
                        (loc.string("create_server_preset_min"), minDisk),
                        ("2 GB", 2048),
                        ("5 GB", 5120),
                        ("10 GB", 10240),
                        (loc.string("create_server_preset_max"), rem.disk)
                    ]
                )
            }
            .padding(14)
            .background(OvernodeTheme.secondaryCardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(OvernodeTheme.borderSubtle, lineWidth: 1)
            )
        }
    }
    
    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(OvernodeTheme.accentGold)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(loc.string("create_server_resources_title"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(OvernodeTheme.textPrimary)
                Text(loc.string("create_server_resources_subtitle"))
                    .font(.system(size: 11))
                    .foregroundColor(OvernodeTheme.textSecondary)
            }
        }
    }
    
    private func resourceRow(
        title: String,
        icon: String,
        color: Color,
        value: Binding<Double>,
        minValue: Double,
        rawMax: Double,
        step: Double,
        unit: String,
        remaining: Double,
        presets: [(String, Double)]
    ) -> some View {
        let safeMax = max(minValue + step, rawMax)
        let isQuotaExceeded = remaining < minValue
        
        return VStack(spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(color)
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(OvernodeTheme.textPrimary)
                }
                
                Spacer()
                
                Text(String(format: "%.0f %@", value.wrappedValue, unit))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                
                Text(String(format: "(%@: %.0f %@)", loc.string("create_server_remaining"), remaining, unit))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(isQuotaExceeded ? OvernodeTheme.accentDanger : OvernodeTheme.textMuted)
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
            
            HStack(spacing: 6) {
                ForEach(presets, id: \.0) { label, val in
                    let isCurrent = abs(value.wrappedValue - val) < (step / 2)
                    let isAvailable = val >= minValue && val <= rawMax
                    Button(action: {
                        if isAvailable {
                            value.wrappedValue = min(rawMax, max(minValue, val))
                        }
                    }) {
                        Text(label)
                            .font(.system(size: 10, weight: isCurrent ? .bold : .medium, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(isCurrent ? color.opacity(0.2) : Color.white.opacity(0.04))
                            .foregroundColor(isCurrent ? color : (isAvailable ? OvernodeTheme.textSecondary : OvernodeTheme.textMuted.opacity(0.5)))
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(isCurrent ? color : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!isAvailable || isQuotaExceeded)
                }
                Spacer()
            }
        }
    }
}
