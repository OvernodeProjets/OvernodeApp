using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using Overnode.App.Models;

namespace Overnode.App.Services;

public class ServerConfigService
{
    private static readonly Lazy<ServerConfigService> _instance = new(() => new ServerConfigService());
    public static ServerConfigService Shared => _instance.Value;

    private readonly APIClient _client;

    private ServerConfigService()
    {
        _client = APIClient.Shared;
    }

    public async Task<List<ServerSubdomain>> FetchSubdomainsAsync(string serverId)
    {
        try
        {
            return await _client.GetAsync<List<ServerSubdomain>>($"/api/v5/server/{serverId}/subdomains");
        }
        catch
        {
            return new List<ServerSubdomain>();
        }
    }

    public async Task<List<string>> FetchAvailableDomainsAsync()
    {
        try
        {
            var res = await _client.GetAsync<List<string>>("/api/v5/subdomains/domains");
            if (res != null && res.Count > 0) return res;
        }
        catch
        {
            // fallback
        }
        return new List<string> { "overnode.fr", "overnode.cloud", "play.overnode.fr" };
    }

    public async Task CreateSubdomainAsync(string serverId, string subdomain, string domainName)
    {
        await _client.PostEmptyAsync($"/api/v5/server/{serverId}/subdomains", new { subdomain, domainName });
    }

    public async Task DeleteSubdomainAsync(string serverId, string subdomainId)
    {
        await _client.DeleteEmptyAsync($"/api/v5/server/{serverId}/subdomains/{subdomainId}");
    }

    public async Task<List<ServerSubuser>> FetchSubusersAsync(string serverId)
    {
        try
        {
            var res = await _client.GetAsync<PteroUsersResponse>($"/api/server/{serverId}/users");
            return res.Data.Select(d =>
            {
                var attr = d.Attributes;
                string idStr = attr?.Id?.ToString() ?? attr?.Uuid ?? Guid.NewGuid().ToString();
                return new ServerSubuser
                {
                    Id = idStr,
                    Uuid = attr?.Uuid,
                    Email = attr?.Email ?? string.Empty,
                    Image = attr?.Image,
                    TwoFactorEnabled = attr?.TwoFactorEnabled ?? false,
                    Permissions = attr?.Permissions ?? new List<string>()
                };
            }).ToList();
        }
        catch
        {
            return new List<ServerSubuser>();
        }
    }

    public async Task CreateSubuserAsync(string serverId, string email, List<string> permissions)
    {
        await _client.PostEmptyAsync($"/api/server/{serverId}/users", new { email, permissions });
    }

    public async Task DeleteSubuserAsync(string serverId, string userId)
    {
        await _client.DeleteEmptyAsync($"/api/server/{serverId}/users/{userId}");
    }

    public async Task RenameServerAsync(string serverId, string name)
    {
        await _client.PostEmptyAsync($"/api/server/{serverId}/rename", new { name });
    }

    public async Task ReinstallServerAsync(string serverId)
    {
        await _client.PostEmptyAsync($"/api/server/{serverId}/reinstall");
    }

    public async Task<List<ServerStartupVariable>> FetchVariablesAsync(string serverId)
    {
        try
        {
            var res = await _client.GetAsync<PteroStartupVariablesResponse>($"/api/server/{serverId}/variables");
            return res.Data.Select(d =>
            {
                var attr = d.Attributes;
                return new ServerStartupVariable
                {
                    Name = attr?.Name ?? string.Empty,
                    EnvVariable = attr?.EnvVariable ?? string.Empty,
                    DefaultValue = attr?.DefaultValue ?? string.Empty,
                    ServerValue = attr?.ServerValue ?? string.Empty,
                    IsEditable = attr?.IsEditable ?? true
                };
            }).ToList();
        }
        catch
        {
            return new List<ServerStartupVariable>();
        }
    }

    public async Task UpdateVariableAsync(string serverId, string key, string value)
    {
        await _client.PutEmptyAsync($"/api/server/{serverId}/variables", new { key, value });
    }

    public async Task ModifyServerResourcesAsync(string serverId, int ramMB, int diskMB, int cpuPercent)
    {
        await _client.PatchEmptyAsync($"/api/v5/servers/{serverId}", new { ram = ramMB, disk = diskMB, cpu = cpuPercent });
    }
}
