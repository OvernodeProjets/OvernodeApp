using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Overnode.App.Models;

namespace Overnode.App.Services;

public sealed class SupportService
{
    private static readonly Lazy<SupportService> _instance = new(() => new SupportService());
    public static SupportService Instance => _instance.Value;
    public static SupportService Shared => _instance.Value;

    private readonly APIClient _client = APIClient.Instance;

    private SupportService() { }

    public async Task<PaginatedTickets> FetchTicketsAsync(int page = 1, int perPage = 20)
    {
        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1")
        {
            return new PaginatedTickets
            {
                Total = 2,
                Page = 1,
                Data = new()
                {
                    new(
                        "tick_01",
                        "Question sur le renouvellement",
                        "Serveurs",
                        "normal",
                        "open",
                        "2026-09-28 16:30",
                        new()
                        {
                            new("msg_1", "OvernodeUser", false, "Bonjour, combien de temps avant l'expiration dois-je renouveler mon serveur ?", "2026-09-28 16:30"),
                            new("msg_2", "Support Overnode", true, "Bonjour ! Vous pouvez renouveler votre serveur jusqu'à 3 jours avant son échéance directement depuis l'onglet Renouvellement.", "2026-09-28 17:05")
                        }
                    ),
                    new(
                        "tick_02",
                        "Configuration du sous-domaine",
                        "Réseau",
                        "faible",
                        "closed",
                        "2026-09-20 11:00",
                        new()
                        {
                            new("msg_3", "OvernodeUser", false, "Comment faire pointer mon nom de domaine personnalisé ?", "2026-09-20 11:00"),
                            new("msg_4", "Support Overnode", true, "Il vous suffit de créer un enregistrement CNAME ou A vers notre proxy.", "2026-09-20 11:20")
                        }
                    )
                }
            };
        }

        return await _client.GetAsync<PaginatedTickets>($"/api/tickets?page={page}&per_page={perPage}");
    }

    public async Task<SupportTicket> CreateTicketAsync(CreateTicketPayload payload)
    {
        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1")
        {
            await Task.Delay(300);
            return new SupportTicket(
                $"tick_{Guid.NewGuid().ToString("N")[..6]}",
                payload.Subject,
                payload.Category,
                payload.Priority,
                "open",
                DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm"),
                new()
                {
                    new("msg_init", "OvernodeUser", false, payload.Description, DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm"))
                }
            );
        }

        return await _client.PostAsync<SupportTicket>("/api/tickets", payload);
    }

    public async Task<TicketMessage> SendMessageAsync(string ticketId, string content)
    {
        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1")
        {
            await Task.Delay(300);
            return new TicketMessage(
                $"msg_{Guid.NewGuid().ToString("N")[..6]}",
                "OvernodeUser",
                false,
                content,
                DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm")
            );
        }

        var payload = new SendTicketMessagePayload { Content = content };
        return await _client.PostAsync<TicketMessage>($"/api/tickets/{ticketId}/messages", payload);
    }
}
