import SwiftUI

public struct ServerPackageTabView: View {
    @ObservedObject var vm: ServerDetailViewModel
    @ObservedObject var loc = LocalizationManager.shared
    
    public init(vm: ServerDetailViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(loc.string("package_title"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(OvernodeTheme.textPrimary)
                Text(loc.string("package_subtitle"))
                    .font(.system(size: 12))
                    .foregroundColor(OvernodeTheme.textSecondary)
            }
            .padding(18)
            .background(OvernodeTheme.cardBackground)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            
            // Resource Modification Controls
            VStack(spacing: 20) {
                // RAM Slider
                ResourceSliderRow(
                    title: loc.string("resource_ram"),
                    icon: "chart.pie",
                    iconColor: Color(red: 0.35, green: 0.55, blue: 0.95),
                    value: $vm.packageRamMB,
                    range: 512...32768,
                    step: 512,
                    unit: "MB"
                )
                
                Divider().background(Color.white.opacity(0.06))
                
                // CPU Slider
                ResourceSliderRow(
                    title: loc.string("resource_cpu"),
                    icon: "cpu",
                    iconColor: Color(red: 0.20, green: 0.75, blue: 0.85),
                    value: $vm.packageCpuPercent,
                    range: 50...800,
                    step: 25,
                    unit: "%"
                )
                
                Divider().background(Color.white.opacity(0.06))
                
                // Disk Slider
                ResourceSliderRow(
                    title: loc.string("resource_disk"),
                    icon: "archivebox",
                    iconColor: Color(red: 0.25, green: 0.78, blue: 0.50),
                    value: $vm.packageDiskMB,
                    range: 1024...65536,
                    step: 1024,
                    unit: "MB"
                )
            }
            .padding(20)
            .background(OvernodeTheme.cardBackground)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            
            // Save Changes Row
            HStack {
                if let msg = vm.successMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(red: 0.25, green: 0.78, blue: 0.50))
                        Text(msg)
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.25, green: 0.78, blue: 0.50))
                    }
                }
                
                if let err = vm.errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color.red)
                        Text(err)
                            .font(.system(size: 12))
                            .foregroundColor(Color.red)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    vm.savePackageChanges()
                }) {
                    HStack(spacing: 6) {
                        if vm.isSavingPackage {
                            ProgressView().scaleEffect(0.6)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }
                        Text(loc.string("package_save_changes"))
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(Color.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(OvernodeTheme.accentGold)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(vm.isSavingPackage)
            }
            
            Spacer()
        }
    }
}

private struct ResourceSliderRow: View {
    let title: String
    let icon: String
    let iconColor: Color
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(OvernodeTheme.textPrimary)
                
                Spacer()
                
                Text(String(format: "%.0f %@", value, unit))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(OvernodeTheme.textPrimary)
            }
            
            Slider(value: $value, in: range, step: step)
                .tint(iconColor)
        }
    }
}

