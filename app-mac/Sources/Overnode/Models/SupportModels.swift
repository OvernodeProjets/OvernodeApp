import Foundation

public struct SupportTicket: Codable, Identifiable, Sendable {
    public let id: String
    public let userId: String?
    public let subject: String
    public let description: String?
    public let priority: String
    public let category: String
    public let status: String
    public let createdAt: String?
    public let updatedAt: String?
    public var messages: [TicketMessage]?
    
    public var isOpen: Bool {
        status.lowercased() == "open"
    }
    
    public init(
        id: String,
        userId: String? = nil,
        subject: String,
        description: String? = nil,
        priority: String = "medium",
        category: String = "technical",
        status: String = "open",
        createdAt: String? = nil,
        updatedAt: String? = nil,
        messages: [TicketMessage]? = nil
    ) {
        self.id = id
        self.userId = userId
        self.subject = subject
        self.description = description
        self.priority = priority
        self.category = category
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
    }
}

public struct TicketMessage: Codable, Identifiable, Sendable {
    public let id: String
    public let ticketId: String?
    public let userId: String?
    public let content: String
    public let isStaff: Bool?
    public let createdAt: String?
    
    public init(
        id: String,
        ticketId: String? = nil,
        userId: String? = nil,
        content: String,
        isStaff: Bool? = false,
        createdAt: String? = nil
    ) {
        self.id = id
        self.ticketId = ticketId
        self.userId = userId
        self.content = content
        self.isStaff = isStaff
        self.createdAt = createdAt
    }
}

public struct PaginatedTickets: Codable, Sendable {
    public let data: [SupportTicket]
    public let total: Int?
    public let page: Int?
    public let perPage: Int?
    public let totalPages: Int?
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        
        if let dataKey = DynamicCodingKey(stringValue: "data"),
           let tickets = try? container.decode([SupportTicket].self, forKey: dataKey) {
            self.data = tickets
        } else if let itemsKey = DynamicCodingKey(stringValue: "items"),
                  let tickets = try? container.decode([SupportTicket].self, forKey: itemsKey) {
            self.data = tickets
        } else {
            // Check if root itself is an array
            let singleVal = try decoder.singleValueContainer()
            if let arr = try? singleVal.decode([SupportTicket].self) {
                self.data = arr
            } else {
                self.data = []
            }
        }
        
        let totalKey = DynamicCodingKey(stringValue: "total")
        self.total = totalKey != nil ? (try? container.decode(Int.self, forKey: totalKey!)) : nil
        
        let pageKey = DynamicCodingKey(stringValue: "page")
        self.page = pageKey != nil ? (try? container.decode(Int.self, forKey: pageKey!)) : nil
        
        let perPageKey = DynamicCodingKey(stringValue: "perPage")
        self.perPage = perPageKey != nil ? (try? container.decode(Int.self, forKey: perPageKey!)) : nil
        
        let totalPagesKey = DynamicCodingKey(stringValue: "totalPages")
        self.totalPages = totalPagesKey != nil ? (try? container.decode(Int.self, forKey: totalPagesKey!)) : nil
    }
    
    public init(data: [SupportTicket], total: Int? = nil, page: Int? = 1, perPage: Int? = 20, totalPages: Int? = 1) {
        self.data = data
        self.total = total
        self.page = page
        self.perPage = perPage
        self.totalPages = totalPages
    }
}

private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { self.intValue = intValue; self.stringValue = "\(intValue)" }
}

public struct CreateTicketPayload: Codable, Sendable {
    public let subject: String
    public let category: String
    public let priority: String
    public let description: String
    
    public init(subject: String, category: String, priority: String, description: String) {
        self.subject = subject
        self.category = category
        self.priority = priority
        self.description = description
    }
}

public struct SendMessagePayload: Codable, Sendable {
    public let content: String
    
    public init(content: String) {
        self.content = content
    }
}

public struct UpdateTicketStatusPayload: Codable, Sendable {
    public let status: String
    
    public init(status: String) {
        self.status = status
    }
}

