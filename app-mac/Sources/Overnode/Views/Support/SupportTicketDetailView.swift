import SwiftUI

public struct SupportTicketDetailView: View {
    @ObservedObject var vm: SupportViewModel
    @ObservedObject var loc = LocalizationManager.shared
    let ticket: SupportTicket
    let onBack: () -> Void
    
    public init(vm: SupportViewModel, ticket: SupportTicket, onBack: @escaping () -> Void) {
        self.vm = vm
        self.ticket = ticket
        self.onBack = onBack
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top Bar: Back button, subject, status, close button
            HStack(spacing: 12) {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .bold))
                        Text(loc.string("support_back"))
                            .font(.system(size: 13))
                    }
                    .foregroundColor(OvernodeTheme.textSecondary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                if ticket.isOpen {
                    Button(action: { vm.closeCurrentTicket() }) {
                        Text(loc.string("support_close_ticket"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.red.opacity(0.9))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Ticket info card
            VStack(alignment: .leading, spacing: 8) {
                Text(ticket.subject)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(OvernodeTheme.textPrimary)
                
                HStack(spacing: 8) {
                    Text(ticket.isOpen ? loc.string("support_status_open") : loc.string("support_status_closed"))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(ticket.isOpen ? Color(red: 0.133, green: 0.773, blue: 0.365) : Color.white.opacity(0.5))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(ticket.isOpen ? Color.green.opacity(0.12) : Color.white.opacity(0.08))
                        .cornerRadius(4)
                    
                    Text(loc.string("support_field_category") + " : \(ticket.category.capitalized)")
                        .font(.system(size: 11))
                        .foregroundColor(OvernodeTheme.textSecondary)
                    
                    Text("•")
                        .foregroundColor(OvernodeTheme.textMuted)
                    
                    Text(loc.string("support_field_priority") + " : \(ticket.priority.capitalized)")
                        .font(.system(size: 11))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.125, green: 0.133, blue: 0.161).opacity(0.5))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
            
            // Messages thread
            VStack(alignment: .leading, spacing: 12) {
                let msgs = vm.selectedTicket?.messages ?? ticket.messages ?? []
                ForEach(msgs) { msg in
                    messageBubble(msg: msg)
                }
            }
            
            // Reply box if open
            if ticket.isOpen {
                VStack(spacing: 8) {
                    HStack {
                        TextField(loc.string("support_reply_placeholder"), text: $vm.replyMessage)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(Color(red: 0.125, green: 0.133, blue: 0.161))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
                        
                        Button(action: { vm.sendReply() }) {
                            HStack(spacing: 6) {
                                if vm.isSendingMessage {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 12))
                                }
                                Text(loc.string("support_btn_reply"))
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .foregroundColor(Color.black)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.isSendingMessage || vm.replyMessage.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    private func messageBubble(msg: TicketMessage) -> some View {
        let isStaff = msg.isStaff ?? false
        return HStack {
            if !isStaff { Spacer() }
            
            VStack(alignment: isStaff ? .leading : .trailing, spacing: 4) {
                HStack(spacing: 6) {
                    Text(isStaff ? loc.string("support_staff_badge") : loc.string("support_you_badge"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isStaff ? OvernodeTheme.accentGold : OvernodeTheme.textPrimary)
                    if isStaff {
                        Text("STAFF")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color.black)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(OvernodeTheme.accentGold)
                            .cornerRadius(3)
                    }
                }
                
                Text(msg.content)
                    .font(.system(size: 13))
                    .foregroundColor(OvernodeTheme.textPrimary)
                    .padding(12)
                    .background(isStaff ? Color(red: 0.14, green: 0.16, blue: 0.20) : Color(red: 0.18, green: 0.22, blue: 0.32))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.06), lineWidth: 1))
            }
            
            if isStaff { Spacer() }
        }
    }
}
