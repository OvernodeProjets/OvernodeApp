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

    public async Task SendPowerSignalAsync(string serverId, string signal)
    {
        await _client.PostEmptyAsync($"/api/server/{serverId}/power", new { signal });
    }

    public async Task SendCommandAsync(string serverId, string command)
    {
        await _client.PostEmptyAsync($"/api/server/{serverId}/command", new { command });
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
            return await _client.PostAsync<Models.ServerRenewalActionResponse>($"/api/server/{serverId}/renewal/renew", new { });
        }
        catch (HttpRequestException ex)
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

    public async Task<(string state, double memoryMB, double cpuPercent, double diskMB)> FetchLiveResourcesAsync(string identifier)
    {
        try
        {
            var res = await _client.GetAsync<LiveResourceApiResponse>($"/api/client/servers/{identifier}/resources");
            var state = res?.Attributes?.CurrentState ?? "offline";
            var r = res?.Attributes?.Resources;
            var mem = (r?.MemoryBytes ?? 0) / 1024.0 / 1024.0;
            var cpu = r?.CpuAbsolute ?? 0;
            var disk = (r?.DiskBytes ?? 0) / 1024.0 / 1024.0;
            return (state, mem, cpu, disk);
        }
        catch
        {
            return ("offline", 0, 0, 0);
        }
    }
}
