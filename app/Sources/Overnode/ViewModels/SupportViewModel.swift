import Foundation
import Combine

@MainActor
public final class SupportViewModel: ObservableObject {
    @Published public var tickets: [SupportTicket] = []
    @Published public var selectedTicket: SupportTicket?
    @Published public var isLoading: Bool = false
    @Published public var isSendingMessage: Bool = false
    @Published public var isCreatingTicket: Bool = false
    @Published public var showCreateModal: Bool = false
    
    // New ticket form fields
    @Published public var newSubject: String = ""
    @Published public var newCategory: String = "technical"
    @Published public var newPriority: String = "medium"
    @Published public var newDescription: String = ""
    
    // Reply field
    @Published public var replyMessage: String = ""
    
    @Published public var errorMessage: String?
    @Published public var successMessage: String?
    
    private let service = SupportService.shared
    
    public init() {}
    
    public func loadTickets() {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                let paginated = try await service.fetchTickets()
                self.tickets = paginated.data
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }
    
    public func selectTicket(_ ticket: SupportTicket) {
        self.selectedTicket = ticket
        Task {
            if let detailed = try? await service.fetchTicketDetails(id: ticket.id) {
                self.selectedTicket = detailed
            }
        }
    }
    
    public func createTicket() {
        guard !newSubject.trimmingCharacters(in: .whitespaces).isEmpty,
              !newDescription.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Veuillez renseigner le sujet et la description."
            return
        }
        
        isCreatingTicket = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                let created = try await service.createTicket(
                    subject: newSubject,
                    category: newCategory,
                    priority: newPriority,
                    description: newDescription
                )
                self.tickets.insert(created, at: 0)
                self.selectedTicket = created
                self.showCreateModal = false
                self.newSubject = ""
                self.newDescription = ""
                self.successMessage = "Ticket créé avec succès."
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isCreatingTicket = false
        }
    }
    
    public func sendReply() {
        guard let ticket = selectedTicket, !replyMessage.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSendingMessage = true
        let content = replyMessage
        self.replyMessage = ""
        
        Task {
            do {
                let msg = try await service.sendMessage(ticketId: ticket.id, content: content)
                if var msgs = self.selectedTicket?.messages {
                    msgs.append(msg)
                    self.selectedTicket?.messages = msgs
                } else {
                    self.selectedTicket?.messages = [msg]
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isSendingMessage = false
        }
    }
    
    public func closeCurrentTicket() {
        guard let ticket = selectedTicket else { return }
        Task {
            try? await service.closeTicket(ticketId: ticket.id)
            if let index = tickets.firstIndex(where: { $0.id == ticket.id }) {
                tickets[index] = SupportTicket(
                    id: ticket.id,
                    userId: ticket.userId,
                    subject: ticket.subject,
                    description: ticket.description,
                    priority: ticket.priority,
                    category: ticket.category,
                    status: "closed",
                    createdAt: ticket.createdAt,
                    updatedAt: ticket.updatedAt,
                    messages: ticket.messages
                )
                self.selectedTicket = tickets[index]
            }
        }
    }
}

