import Foundation

public final class SupportService: @unchecked Sendable {
    public static let shared = SupportService()
    private let client = APIClient.shared
    
    private init() {}
    
    public func fetchTickets(page: Int = 1, perPage: Int = 20) async throws -> PaginatedTickets {
        return try await client.request(endpoint: "/api/tickets?page=\(page)&per_page=\(perPage)")
    }
    
    public func fetchTicketDetails(id: String) async throws -> SupportTicket {
        return try await client.request(endpoint: "/api/tickets/\(id)")
    }
    
    public func createTicket(subject: String, category: String, priority: String, description: String) async throws -> SupportTicket {
        let payload = CreateTicketPayload(
            subject: subject,
            category: category,
            priority: priority,
            description: description
        )
        let body = try JSONEncoder().encode(payload)
        return try await client.request(
            endpoint: "/api/tickets",
            method: "POST",
            body: body
        )
    }
    
    public func sendMessage(ticketId: String, content: String) async throws -> TicketMessage {
        let payload = SendMessagePayload(content: content)
        let body = try JSONEncoder().encode(payload)
        return try await client.request(
            endpoint: "/api/tickets/\(ticketId)/messages",
            method: "POST",
            body: body
        )
    }
    
    public func closeTicket(ticketId: String) async throws {
        let payload = UpdateTicketStatusPayload(status: "closed")
        let body = try JSONEncoder().encode(payload)
        struct GenericResponse: Codable {}
        let _: GenericResponse? = try? await client.request(
            endpoint: "/api/tickets/\(ticketId)/status",
            method: "PATCH",
            body: body
        )
    }
}

