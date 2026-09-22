import SwiftUI

public struct SupportTicketListView: View {
    @ObservedObject var vm: SupportViewModel
    @ObservedObject var loc = LocalizationManager.shared
    
    public init(vm: SupportViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            if vm.tickets.isEmpty && !vm.isLoading {
                VStack(spacing: 12) {
                    Image(systemName: "ticket")
                        .font(.system(size: 36))
                        .foregroundColor(OvernodeTheme.textMuted)
                    Text(loc.string("support_no_tickets"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    Text(loc.string("support_no_tickets_desc"))
                        .font(.system(size: 13))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(48)
            } else {
                ForEach(vm.tickets) { ticket in
                    Button(action: { vm.selectTicket(ticket) }) {
                        HStack(spacing: 12) {
                            // Status indicator
                            Circle()
                                .fill(ticket.isOpen ? Color(red: 0.133, green: 0.773, blue: 0.365) : Color(red: 0.5, green: 0.5, blue: 0.5))
                                .frame(width: 8, height: 8)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(ticket.subject)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(OvernodeTheme.textPrimary)
                                        .lineLimit(1)
                                    
                                    // Status badge
                                    Text(ticket.isOpen ? loc.string("support_status_open") : loc.string("support_status_closed"))
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(ticket.isOpen ? Color(red: 0.133, green: 0.773, blue: 0.365) : Color.white.opacity(0.5))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(ticket.isOpen ? Color.green.opacity(0.12) : Color.white.opacity(0.08))
                                        .cornerRadius(4)
                                    
                                    // Priority badge
                                    Text(priorityLabel(ticket.priority))
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(priorityColor(ticket.priority))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(priorityColor(ticket.priority).opacity(0.12))
                                        .cornerRadius(4)
                                }
                                
                                HStack(spacing: 6) {
                                    Text("ID: #\(String(ticket.id.prefix(8)))")
                                        .font(.system(size: 11, design: .monospaced))
                                    Text("•")
                                    Text(categoryLabel(ticket.category))
                                        .font(.system(size: 11))
                                    if let date = ticket.createdAt {
                                        Text("•")
                                        Text(formatDate(date))
                                            .font(.system(size: 11))
                                    }
                                }
                                .foregroundColor(OvernodeTheme.textMuted)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11))
                                .foregroundColor(OvernodeTheme.textMuted)
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func priorityLabel(_ priority: String) -> String {
        switch priority.lowercased() {
        case "urgent": return loc.string("support_priority_urgent")
        case "high": return loc.string("support_priority_high")
        case "medium": return loc.string("support_priority_medium")
        default: return loc.string("support_priority_low")
        }
    }
    
    private func categoryLabel(_ cat: String) -> String {
        switch cat.lowercased() {
        case "technical": return loc.string("support_cat_tech")
        case "billing": return loc.string("support_cat_billing")
        case "abuse": return loc.string("support_cat_abuse")
        default: return loc.string("support_cat_general")
        }
    }
    
    private func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "urgent": return Color.red
        case "high": return Color.orange
        case "medium": return Color.yellow
        default: return Color.blue
        }
    }
    
    private func formatDate(_ dateStr: String) -> String {
        let prefix = String(dateStr.prefix(10))
        return prefix
    }
}
