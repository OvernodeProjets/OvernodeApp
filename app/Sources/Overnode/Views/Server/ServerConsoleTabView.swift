import SwiftUI

public struct ServerConsoleTabView: View {
    @ObservedObject var vm: ServerDetailViewModel
    @ObservedObject var loc = LocalizationManager.shared
    
    public init(vm: ServerDetailViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Live Resource Bar
            HStack(spacing: 16) {
                // CPU chip
                HStack(spacing: 8) {
                    Image(systemName: "cpu")
                        .foregroundColor(Color(red: 0.20, green: 0.75, blue: 0.85))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(loc.string("resource_cpu"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(OvernodeTheme.textSecondary)
                        Text(String(format: "%.1f%% / %.0f%%", vm.server.cpuUsedPercent, vm.server.cpuLimitPercent))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(OvernodeTheme.textPrimary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(red: 0.125, green: 0.133, blue: 0.161))
                .cornerRadius(8)
                
                // Memory chip
                HStack(spacing: 8) {
                    Image(systemName: "chart.pie")
                        .foregroundColor(Color(red: 0.35, green: 0.55, blue: 0.95))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(loc.string("resource_ram"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(OvernodeTheme.textSecondary)
                        Text(String(format: "%.0f / %.0f MB", vm.server.memoryUsedMB, vm.server.memoryLimitMB))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(OvernodeTheme.textPrimary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(red: 0.125, green: 0.133, blue: 0.161))
                .cornerRadius(8)
                
                // Disk chip
                HStack(spacing: 8) {
                    Image(systemName: "archivebox")
                        .foregroundColor(Color(red: 0.25, green: 0.78, blue: 0.50))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(loc.string("resource_disk"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(OvernodeTheme.textSecondary)
                        Text(String(format: "%.0f / %.0f MB", vm.server.diskUsedMB, vm.server.diskLimitMB))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(OvernodeTheme.textPrimary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(red: 0.125, green: 0.133, blue: 0.161))
                .cornerRadius(8)
                
                Spacer()
            }
            
            // Console Terminal View
            VStack(spacing: 0) {
                // Header terminal dots
                HStack(spacing: 6) {
                    Circle().fill(Color(red: 0.95, green: 0.35, blue: 0.35)).frame(width: 10, height: 10)
                    Circle().fill(Color(red: 0.95, green: 0.75, blue: 0.25)).frame(width: 10, height: 10)
                    Circle().fill(Color(red: 0.25, green: 0.85, blue: 0.45)).frame(width: 10, height: 10)
                    
                    Spacer()
                    
                    Text("terminal - bash")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.4))
                    
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(red: 0.08, green: 0.09, blue: 0.11))
                
                Divider()
                    .background(Color.white.opacity(0.06))
                
                // Scrollable log lines
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(vm.consoleLines.enumerated()), id: \.offset) { index, line in
                                Text(line)
                                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                                    .foregroundColor(consoleLineColor(line))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id(index)
                            }
                        }
                        .padding(14)
                    }
                    .frame(height: 380)
                    .background(Color(red: 0.05, green: 0.06, blue: 0.08))
                    .onChange(of: vm.consoleLines.count) { _, _ in
                        if let lastIndex = vm.consoleLines.indices.last {
                            proxy.scrollTo(lastIndex, anchor: .bottom)
                        }
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.06))
                
                // Command Input Bar
                HStack(spacing: 8) {
                    Text("$")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(OvernodeTheme.accentGold)
                    
                    TextField(loc.string("console_input_placeholder"), text: $vm.commandInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundColor(Color.white)
                        .onSubmit {
                            vm.sendConsoleCommand()
                        }
                    
                    Button(action: {
                        vm.sendConsoleCommand()
                    }) {
                        HStack(spacing: 4) {
                            Text(loc.string("console_send"))
                                .font(.system(size: 12, weight: .semibold))
                            Image(systemName: "return")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(Color.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(OvernodeTheme.accentGold)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(red: 0.08, green: 0.09, blue: 0.11))
            }
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .frame(minHeight: 340)
        }
    }
    
    private func consoleLineColor(_ line: String) -> Color {
        if line.contains("[Error]") || line.contains("Exception") || line.contains("ERROR") {
            return Color(red: 0.95, green: 0.40, blue: 0.40)
        }
        if line.contains("[Action]") || line.contains("WARN") {
            return Color(red: 0.95, green: 0.75, blue: 0.30)
        }
        if line.contains("> ") {
            return Color(red: 0.40, green: 0.85, blue: 0.95)
        }
        return Color(red: 0.85, green: 0.88, blue: 0.92)
    }
}
