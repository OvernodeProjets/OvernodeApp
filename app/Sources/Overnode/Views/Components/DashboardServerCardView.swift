import SwiftUI

public struct DashboardServerCardView: View {
    @ObservedObject var loc = LocalizationManager.shared
    let server: ServerInstance
    
    public init(server: ServerInstance) {
        self.server = server
    }
    
    private var statusColor: Color {
        if server.suspended {
            return Color(red: 0.937, green: 0.267, blue: 0.267) // red
        }
        switch server.state.lowercased() {
        case "running":
            return Color(red: 0.133, green: 0.773, blue: 0.365) // emerald green
        case "starting", "stopping":
            return Color(red: 0.961, green: 0.620, blue: 0.106) // amber
        default:
            return Color(red: 0.45, green: 0.49, blue: 0.54) // neutral gray
        }
    }
    
    private var statusLabel: String {
        if server.suspended {
            return loc.string("server_status_suspended")
        }
        switch server.state.lowercased() {
        case "running":
            return loc.string("server_status_online")
        case "starting":
            return loc.string("server_status_starting")
        case "stopping":
            return loc.string("server_status_stopping")
        default:
            return loc.string("server_status_offline")
        }
    }
    
    private var diskFormattedString: String {
        let used = server.diskUsedMB
        let limit = server.diskLimitMB
        
        let usedStr = used >= 1024 ? String(format: "%.2f GB", used / 1024.0) : String(format: "%.0f MB", used)
        let limitStr = limit >= 1024 ? String(format: "%.0f GB", limit / 1024.0) : String(format: "%.0f MB", limit)
        
        return "\(usedStr) / \(limitStr)"
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Toledo Icon square + Server Name + Status + Manage button
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.125, green: 0.133, blue: 0.161)) // #202229
                        .frame(width: 40, height: 40)
                    Image(systemName: "server.rack")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.584, green: 0.631, blue: 0.678)) // #95a1ad
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(server.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)
                        
                        Text(statusLabel)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(red: 0.584, green: 0.631, blue: 0.678)) // #95a1ad
                    }
                }
                
                Spacer()
                
                // Manage button
                Button(action: {
                    // Placeholder button
                }) {
                    HStack(spacing: 5) {
                        Text(loc.string("server_manage_button"))
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(Color.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.125, green: 0.133, blue: 0.161)) // #202229
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Consumptions list: Memory, CPU, Disk
            VStack(spacing: 12) {
                // Memory Gauge line
                VStack(spacing: 5) {
                    HStack {
                        Text("Memory")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(red: 0.584, green: 0.631, blue: 0.678))
                        Spacer()
                        Text(String(format: "%.0f / %.0f MB", server.memoryUsedMB, server.memoryLimitMB))
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundColor(OvernodeTheme.textPrimary)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(red: 0.125, green: 0.133, blue: 0.161))
                                .frame(height: 3)
                            
                            let pct = server.memoryLimitMB > 0 ? min(server.memoryUsedMB / server.memoryLimitMB, 1.0) : 0
                            Capsule()
                                .fill(Color(red: 0.35, green: 0.55, blue: 0.95))
                                .frame(width: max(0, geo.size.width * CGFloat(pct)), height: 3)
                        }
                    }
                    .frame(height: 3)
                }
                
                // CPU Gauge line
                VStack(spacing: 5) {
                    HStack {
                        Text("CPU")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(red: 0.584, green: 0.631, blue: 0.678))
                        Spacer()
                        Text(String(format: "%.1f / %.0f%%", server.cpuUsedPercent, server.cpuLimitPercent))
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundColor(OvernodeTheme.textPrimary)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(red: 0.125, green: 0.133, blue: 0.161))
                                .frame(height: 3)
                            
                            let pct = server.cpuLimitPercent > 0 ? min(server.cpuUsedPercent / server.cpuLimitPercent, 1.0) : 0
                            Capsule()
                                .fill(Color(red: 0.20, green: 0.75, blue: 0.85))
                                .frame(width: max(0, geo.size.width * CGFloat(pct)), height: 3)
                        }
                    }
                    .frame(height: 3)
                }
                
                // Disk Gauge line
                VStack(spacing: 5) {
                    HStack {
                        Text("Disk")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(red: 0.584, green: 0.631, blue: 0.678))
                        Spacer()
                        Text(diskFormattedString)
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundColor(OvernodeTheme.textPrimary)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(red: 0.125, green: 0.133, blue: 0.161))
                                .frame(height: 3)
                            
                            let pct = server.diskLimitMB > 0 ? min(server.diskUsedMB / server.diskLimitMB, 1.0) : 0
                            Capsule()
                                .fill(Color(red: 0.25, green: 0.78, blue: 0.50))
                                .frame(width: max(0, geo.size.width * CGFloat(pct)), height: 3)
                        }
                    }
                    .frame(height: 3)
                }
            }
        }
        .padding(18)
        .background(Color.clear)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(red: 0.180, green: 0.200, blue: 0.216).opacity(0.5), lineWidth: 1)
        )
    }
}
