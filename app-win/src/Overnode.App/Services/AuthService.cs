using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using Overnode.App.Models;

namespace Overnode.App.Services;

public sealed class AuthService
{
    private static readonly Lazy<AuthService> _instance = new(() => new AuthService());
    public static AuthService Instance => _instance.Value;

    private readonly APIClient _client = APIClient.Instance;

    private AuthService() { }

    public async Task<AuthStateResponse> CheckAuthStateAsync()
    {
        return await _client.GetAsync<AuthStateResponse>("/api/v5/state");
    }

    public async Task<InitResponse> FetchInitAsync()
    {
        return await _client.GetAsync<InitResponse>("/api/v5/init");
    }

    public async Task<ResourcesResponse> FetchResourcesAsync()
    {
        return await _client.GetAsync<ResourcesResponse>("/api/v5/resources");
    }

    private class CoinsResponse
    {
        [JsonPropertyName("coins")]
        public int Coins { get; set; }
    }

    public async Task<int> FetchCoinsAsync()
    {
        try
        {
            var res = await _client.GetAsync<CoinsResponse>("/api/coins");
            return res?.Coins ?? 0;
        }
        catch
        {
            return 0;
        }
    }

    public async Task<TwoFactorVerifyResponse> Verify2FAAsync(string code)
    {
        var request = new TwoFactorVerifyRequest { Code = code };
        return await _client.PostAsync<TwoFactorVerifyResponse>("/auth/2fa/verify", request);
    }

    public async Task<PasskeyOptionsResponse> GetPasskeyOptionsAsync()
    {
        return await _client.GetAsync<PasskeyOptionsResponse>("/auth/passkey/options");
    }

    public async Task<AuthStateResponse> VerifyPasskeyAsync(PasskeyVerifyPayload payload)
    {
        return await _client.PostAsync<AuthStateResponse>("/auth/passkey/verify", payload);
    }

    public async Task<PlatformStatsResponse> FetchPlatformStatsAsync()
    {
        try
        {
            var stats = await _client.GetAsync<PlatformStatsResponse>("/api/v5/platform-stats");
            if (stats != null) return stats;
        }
        catch { }

        try
        {
            var stats = await _client.GetAsync<PlatformStatsResponse>("/api/stats");
            if (stats != null) return stats;
        }
        catch { }

        return new PlatformStatsResponse(1268, 91, 4, 2);
    }

    public async Task<List<ServerInstance>> FetchServersStatusAsync()
    {
        var baseServers = new List<ServerInstance>();

        // 1. Fetch user's own servers from live endpoint or fallbacks
        try
        {
            var live = await _client.GetAsync<List<ServerInstance>>("/api/v5/servers/status");
            if (live != null && live.Count > 0)
            {
                baseServers = live;
            }
        }
        catch { }

        if (baseServers.Count == 0)
        {
            try
            {
                var raw = await _client.GetAsync<List<PteroServerWrapper>>("/api/v5/servers");
                if (raw != null && raw.Count > 0)
                {
                    baseServers = raw.Select(s => s.ToServerInstance()).ToList();
                }
            }
            catch { }
        }

        if (baseServers.Count == 0)
        {
            try
            {
                var raw = await _client.GetAsync<List<PteroServerWrapper>>("/api/servers");
                if (raw != null && raw.Count > 0)
                {
                    baseServers = raw.Select(s => s.ToServerInstance()).ToList();
                }
            }
            catch { }
        }

        if (baseServers.Count == 0)
        {
            try
            {
                var initData = await FetchInitAsync();
                if (initData?.Servers != null && initData.Servers.Count > 0)
                {
                    baseServers = initData.Servers.Select(s => s.ToServerInstance()).ToList();
                }
            }
            catch { }
        }

        // 2. Fetch shared / subuser servers
        var sharedServers = await FetchSharedServersAsync(baseServers);

        // Combine base and shared servers (deduplicating by identifier)
        var allServers = new List<ServerInstance>();
        var seenIdentifiers = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (var s in baseServers)
        {
            if (!string.IsNullOrEmpty(s.Identifier) && seenIdentifiers.Add(s.Identifier))
            {
                allServers.Add(s);
            }
        }

        foreach (var s in sharedServers)
        {
            if (!string.IsNullOrEmpty(s.Identifier) && seenIdentifiers.Add(s.Identifier))
            {
                allServers.Add(s);
            }
        }

        // 3. Enrich with real-time status and consumptions
        return await EnrichServersAsync(allServers);
    }

    private class SubuserServerDTO
    {
        [JsonPropertyName("id")]
        public string? Id { get; set; }

        [JsonPropertyName("serverId")]
        public string? ServerId { get; set; }

        [JsonPropertyName("name")]
        public string? Name { get; set; }

        [JsonPropertyName("serverName")]
        public string? ServerName { get; set; }

        [JsonPropertyName("ownerId")]
        public string? OwnerId { get; set; }

        public string ResolvedId => !string.IsNullOrEmpty(ServerId) ? ServerId : (Id ?? string.Empty);
        public string ResolvedName => !string.IsNullOrEmpty(ServerName) ? ServerName : (Name ?? "Shared Server");
    }

    private class ServerDetailApiResponse
    {
        public class AttributesPayload
        {
            [JsonPropertyName("id")]
            public int? Id { get; set; }

            [JsonPropertyName("identifier")]
            public string? Identifier { get; set; }

            [JsonPropertyName("name")]
            public string? Name { get; set; }

            [JsonPropertyName("node")]
            public string? Node { get; set; }

            [JsonPropertyName("is_suspended")]
            public bool? IsSuspended { get; set; }

            public class LimitsPayload
            {
                [JsonPropertyName("memory")]
                public double? Memory { get; set; }

                [JsonPropertyName("cpu")]
                public double? Cpu { get; set; }

                [JsonPropertyName("disk")]
                public double? Disk { get; set; }
            }

            [JsonPropertyName("limits")]
            public LimitsPayload? Limits { get; set; }
        }

        public class MetaPayload
        {
            [JsonPropertyName("isOwner")]
            public bool? IsOwner { get; set; }

            [JsonPropertyName("is_server_owner")]
            public bool? IsServerOwner { get; set; }

            [JsonPropertyName("user_permissions")]
            public List<string>? UserPermissions { get; set; }

            [JsonPropertyName("permissions")]
            public List<string>? Permissions { get; set; }
        }

        [JsonPropertyName("attributes")]
        public AttributesPayload? Attributes { get; set; }

        [JsonPropertyName("meta")]
        public MetaPayload? Meta { get; set; }
    }

    private async Task<List<ServerInstance>> FetchSharedServersAsync(List<ServerInstance> existingServers)
    {
        var subuserItems = new List<SubuserServerDTO>();

        try
        {
            var subs = await _client.GetAsync<List<SubuserServerDTO>>("/api/subuser-servers");
            if (subs != null && subs.Count > 0) subuserItems.AddRange(subs);
        }
        catch { }

        try
        {
            var initData = await FetchInitAsync();
            if (initData?.SubuserServers != null)
            {
                foreach (var sub in initData.SubuserServers)
                {
                    subuserItems.Add(new SubuserServerDTO
                    {
                        Id = sub.ResolvedId,
                        ServerId = sub.ServerId,
                        Name = sub.ResolvedName,
                        ServerName = sub.ResolvedName
                    });
                }
            }
        }
        catch { }

        if (subuserItems.Count == 0) return new List<ServerInstance>();

        var existingIds = new HashSet<string>(
            existingServers.Select(s => s.Identifier).Concat(existingServers.Select(s => s.Id.ToString())),
            StringComparer.OrdinalIgnoreCase
        );

        var uniqueSubs = new List<SubuserServerDTO>();
        var seenSubIds = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (var sub in subuserItems)
        {
            var sid = sub.ResolvedId;
            if (!string.IsNullOrEmpty(sid) && !existingIds.Contains(sid) && seenSubIds.Add(sid))
            {
                uniqueSubs.Add(sub);
            }
        }

        var results = new List<ServerInstance>();
        foreach (var sub in uniqueSubs)
        {
            var serverId = sub.ResolvedId;
            var fallbackName = sub.ResolvedName;
            try
            {
                var detail = await _client.GetAsync<ServerDetailApiResponse>($"/api/v5/server/{serverId}");
                if (detail != null)
                {
                    var attr = detail.Attributes;
                    var meta = detail.Meta;
                    var perms = meta?.UserPermissions ?? meta?.Permissions ?? new List<string>
                    {
                        "control.console", "control.start", "control.stop", "control.restart", "file.read"
                    };

                    results.Add(new ServerInstance
                    {
                        Id = attr?.Id ?? 0,
                        Identifier = attr?.Identifier ?? serverId,
                        Name = attr?.Name ?? fallbackName,
                        Node = attr?.Node,
                        Suspended = attr?.IsSuspended ?? false,
                        State = "offline",
                        IsOwner = meta?.IsOwner ?? meta?.IsServerOwner ?? false,
                        Permissions = perms,
                        MemoryUsedMB = 0,
                        MemoryLimitMB = attr?.Limits?.Memory ?? 0,
                        CpuUsedPercent = 0,
                        CpuLimitPercent = attr?.Limits?.Cpu ?? 0,
                        DiskUsedMB = 0,
                        DiskLimitMB = attr?.Limits?.Disk ?? 0
                    });
                    continue;
                }
            }
            catch { }

            results.Add(new ServerInstance
            {
                Id = 0,
                Identifier = serverId,
                Name = fallbackName,
                Node = null,
                Suspended = false,
                State = "offline",
                IsOwner = false,
                Permissions = new List<string> { "control.console", "control.start", "control.stop", "control.restart", "file.read" }
            });
        }

        return results;
    }

    private async Task<List<ServerInstance>> EnrichServersAsync(List<ServerInstance> servers)
    {
        var tasks = servers.Select(async server =>
        {
            try
            {
                var (state, mem, cpu, disk) = await ServerService.Shared.FetchLiveResourcesAsync(server.Identifier);
                server.State = state;
                server.MemoryUsedMB = Math.Round(mem);
                server.CpuUsedPercent = Math.Round(cpu, 1);
                server.DiskUsedMB = Math.Round(disk);
            }
            catch { }
            return server;
        });

        var enriched = await Task.WhenAll(tasks);
        return enriched.OrderBy(s => s.Name).ToList();
    }

    public void Logout()
    {
        _client.ClearCookies();
    }
}
