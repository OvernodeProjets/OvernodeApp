using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace Overnode.App.Models;

public class TicketMessage
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("sender")]
    public string Sender { get; set; } = string.Empty;

    [JsonPropertyName("isStaff")]
    public bool IsStaff { get; set; }

    [JsonPropertyName("content")]
    public string Content { get; set; } = string.Empty;

    [JsonPropertyName("createdAt")]
    public string CreatedAt { get; set; } = string.Empty;

    public TicketMessage() { }

    public TicketMessage(string id, string sender, bool isStaff, string content, string createdAt)
    {
        Id = id;
        Sender = sender;
        IsStaff = isStaff;
        Content = content;
        CreatedAt = createdAt;
    }
}

public class SupportTicket
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("subject")]
    public string Subject { get; set; } = string.Empty;

    [JsonPropertyName("category")]
    public string Category { get; set; } = "general";

    [JsonPropertyName("priority")]
    public string Priority { get; set; } = "medium";

    [JsonPropertyName("status")]
    public string Status { get; set; } = "open";

    [JsonPropertyName("createdAt")]
    public string CreatedAt { get; set; } = string.Empty;

    [JsonPropertyName("messages")]
    public List<TicketMessage> Messages { get; set; } = new();

    public SupportTicket() { }

    public SupportTicket(string id, string subject, string category, string priority, string status, string createdAt, List<TicketMessage>? messages = null)
    {
        Id = id;
        Subject = subject;
        Category = category;
        Priority = priority;
        Status = status;
        CreatedAt = createdAt;
        Messages = messages ?? new();
    }
}

public class PaginatedTickets
{
    [JsonPropertyName("data")]
    public List<SupportTicket> Data { get; set; } = new();

    [JsonPropertyName("total")]
    public int Total { get; set; }

    [JsonPropertyName("page")]
    public int Page { get; set; } = 1;
}

public class CreateTicketPayload
{
    [JsonPropertyName("subject")]
    public string Subject { get; set; } = string.Empty;

    [JsonPropertyName("category")]
    public string Category { get; set; } = "general";

    [JsonPropertyName("priority")]
    public string Priority { get; set; } = "medium";

    [JsonPropertyName("description")]
    public string Description { get; set; } = string.Empty;
}

public class SendTicketMessagePayload
{
    [JsonPropertyName("content")]
    public string Content { get; set; } = string.Empty;
}
