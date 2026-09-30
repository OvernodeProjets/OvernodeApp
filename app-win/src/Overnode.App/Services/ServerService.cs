using System;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace Overnode.App.Services;

public class ServerService
{
    private static readonly Lazy<ServerService> _instance = new(() => new ServerService());
    public static ServerService Shared => _instance.Value;

    private readonly APIClient _client;

    private ServerService()
    {
        _client = APIClient.Shared;
    }

    public async Task SendPowerSignalAsync(string serverId, string signal, string? fallbackId = null)
    {
        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1")
        {
            return;
        }

        string primaryId = !string.IsNullOrWhiteSpace(serverId) ? serverId : (fallbackId ?? string.Empty);
        if (string.IsNullOrWhiteSpace(primaryId))
        {
            throw new InvalidOperationException("Identifiant du serveur introuvable.");
        }

        try
        {
            await _client.PostEmptyAsync($"/api/server/{primaryId}/power", new { signal });
        }
        catch (HttpRequestException) when (!string.IsNullOrWhiteSpace(fallbackId) && !string.Equals(fallbackId, primaryId, StringComparison.OrdinalIgnoreCase))
        {
            await _client.PostEmptyAsync($"/api/server/{fallbackId}/power", new { signal });
        }
    }

    public async Task SendCommandAsync(string serverId, string command, string? fallbackId = null)
    {
        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1")
        {
            return;
        }

        string primaryId = !string.IsNullOrWhiteSpace(serverId) ? serverId : (fallbackId ?? string.Empty);
        if (string.IsNullOrWhiteSpace(primaryId)) return;

        try
        {
            await _client.PostEmptyAsync($"/api/server/{primaryId}/command", new { command });
        }
        catch (HttpRequestException) when (!string.IsNullOrWhiteSpace(fallbackId) && !string.Equals(fallbackId, primaryId, StringComparison.OrdinalIgnoreCase))
        {
            await _client.PostEmptyAsync($"/api/server/{fallbackId}/command", new { command });
        }
    }

    public async Task DeleteServerAsync(string serverId)
    {
        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1")
        {
            return;
        }

        await _client.DeleteEmptyAsync($"/api/v5/servers/{serverId}");
    }

    public async Task<Models.ServerRenewalStatus?> FetchRenewalStatusAsync(string serverId)
    {
        try
        {
            return await _client.GetAsync<Models.ServerRenewalStatus>($"/api/server/{serverId}/renewal/status");
        }
        catch
        {
            return null;
        }
    }

    public async Task<Models.ServerRenewalActionResponse> RenewServerAsync(string serverId)
    {
        try
        {
            var (data, rawError, statusCode) = await _client.PostWithResponseFallbackAsync<Models.ServerRenewalActionResponse>(
                $"/api/server/{serverId}/renewal/renew", new { });

            if (data != null)
            {
                return data;
            }

            return new Models.ServerRenewalActionResponse
            {
                Error = rawError ?? $"HTTP {statusCode}"
            };
        }
        catch (Exception ex)
        {
            return new Models.ServerRenewalActionResponse
            {
                Error = ex.Message
            };
        }
    }

    private class LiveResourceApiResponse
    {
        public class LiveAttributes
        {
            [JsonPropertyName("current_state")]
            public string? CurrentState { get; set; }

            public class ResPayload
            {
                [JsonPropertyName("memory_bytes")]
                public double? MemoryBytes { get; set; }

                [JsonPropertyName("cpu_absolute")]
                public double? CpuAbsolute { get; set; }

                [JsonPropertyName("disk_bytes")]
                public double? DiskBytes { get; set; }
            }

            [JsonPropertyName("resources")]
            public ResPayload? Resources { get; set; }
        }

        [JsonPropertyName("attributes")]
        public LiveAttributes? Attributes { get; set; }
    }

    public async Task<(string state, double memoryMB, double cpuPercent, double diskMB)?> FetchLiveResourcesAsync(string identifier, int serverId = 0)
    {
        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1")
        {
            return ("running", 512, 25.5, 1200);
        }

        // 1. Try /api/v5/servers/status from Toledo backend which has real live status and resources
        try
        {
            var servers = await _client.GetAsync<System.Collections.Generic.List<Models.ServerInstance>>("/api/v5/servers/status");
            if (servers != null && servers.Count > 0)
            {
                var match = servers.Find(s =>
                    (!string.IsNullOrEmpty(identifier) && string.Equals(s.Identifier, identifier, StringComparison.OrdinalIgnoreCase)) ||
                    (serverId > 0 && s.Id == serverId));

                if (match != null)
                {
                    return (match.State, match.MemoryUsedMB, match.CpuUsedPercent, match.DiskUsedMB);
                }
            }
        }
        catch
        {
            // Fallback to client proxy
        }

        // 2. Direct client resources endpoint fallback
        if (!string.IsNullOrWhiteSpace(identifier))
        {
            try
            {
                var res = await _client.GetAsync<LiveResourceApiResponse>($"/api/client/servers/{identifier}/resources");
                if (res?.Attributes != null)
                {
                    var state = res.Attributes.CurrentState ?? "offline";
                    var r = res.Attributes.Resources;
                    var mem = (r?.MemoryBytes ?? 0) / 1024.0 / 1024.0;
                    var cpu = r?.CpuAbsolute ?? 0;
                    var disk = (r?.DiskBytes ?? 0) / 1024.0 / 1024.0;
                    return (state, mem, cpu, disk);
                }
            }
            catch
            {
                // Both attempts failed
            }
        }

        return null;
    }
}
