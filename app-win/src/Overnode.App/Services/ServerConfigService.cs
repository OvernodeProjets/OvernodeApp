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
    public static ServerConfigService Instance => _instance.Value;
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
        await Task.CompletedTask;
        return new List<string> { "overnode.fr" };
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

    // MARK: - Plugins
    public async Task<List<ServerPluginItem>> FetchInstalledPluginsAsync(string serverId)
    {
        var result = new List<ServerPluginItem>();
        try
        {
            string raw = await _client.GetStringAsync($"/api/plugins/installed/{serverId}");
            using var doc = JsonDocument.Parse(raw);
            var root = doc.RootElement;

            if (root.ValueKind == JsonValueKind.Array)
            {
                foreach (var el in root.EnumerateArray())
                {
                    var item = JsonSerializer.Deserialize<ServerPluginItem>(el.GetRawText());
                    if (item != null)
                    {
                        item.IsInstalled = true;
                        result.Add(item);
                    }
                }
            }
            else if (root.ValueKind == JsonValueKind.Object && root.TryGetProperty("plugins", out var pluginsProp) && pluginsProp.ValueKind == JsonValueKind.Array)
            {
                foreach (var el in pluginsProp.EnumerateArray())
                {
                    var item = JsonSerializer.Deserialize<ServerPluginItem>(el.GetRawText());
                    if (item != null)
                    {
                        item.IsInstalled = true;
                        result.Add(item);
                    }
                }
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[ServerConfigService] FetchInstalledPluginsAsync error: {ex.Message}");
        }

        // If no plugins tracked in DB, trigger scan to discover plugins from .jar files
        if (result.Count == 0)
        {
            try
            {
                string scanRaw = await _client.GetStringAsync($"/api/plugins/scan/{serverId}");
                using var scanDoc = JsonDocument.Parse(scanRaw);
                if (scanDoc.RootElement.TryGetProperty("plugins", out var scanPlugins) && scanPlugins.ValueKind == JsonValueKind.Array)
                {
                    foreach (var el in scanPlugins.EnumerateArray())
                    {
                        var item = JsonSerializer.Deserialize<ServerPluginItem>(el.GetRawText());
                        if (item != null)
                        {
                            item.IsInstalled = true;
                            result.Add(item);
                        }
                    }
                }
            }
            catch
            {
            }
        }

        return result;
    }

    public async Task<List<ServerPluginItem>> SearchPluginsAsync(string query, string platform = "spigot")
    {
        string cleanQuery = string.IsNullOrWhiteSpace(query) ? "world" : query.Trim();
        string encoded = Uri.EscapeDataString(cleanQuery);
        string endpoint = $"/api/plugins/search?query={encoded}&platform={platform}&size=30";

        var result = new List<ServerPluginItem>();
        try
        {
            string raw = await _client.GetStringAsync(endpoint);
            using var doc = JsonDocument.Parse(raw);
            var root = doc.RootElement;

            JsonElement arrayElem = root;
            if (root.ValueKind == JsonValueKind.Object && root.TryGetProperty("data", out var dataElem))
            {
                arrayElem = dataElem;
            }

            if (arrayElem.ValueKind == JsonValueKind.Array)
            {
                foreach (var el in arrayElem.EnumerateArray())
                {
                    var item = JsonSerializer.Deserialize<ServerPluginItem>(el.GetRawText());
                    if (item != null)
                    {
                        item.Platform = platform;
                        result.Add(item);
                    }
                }
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[ServerConfigService] SearchPluginsAsync error: {ex.Message}");
        }

        return result;
    }

    public async Task InstallPluginAsync(string serverId, string pluginId, string platform = "spigot")
    {
        await _client.PostEmptyAsync($"/api/plugins/install/{serverId}", new { pluginId = pluginId.ToString(), platform });
    }

    public async Task UntrackPluginAsync(string serverId, string pluginId, string platform = "modrinth")
    {
        await _client.DeleteWithBodyAsync($"/api/plugins/untrack/{serverId}", new { pluginId = pluginId.ToString(), platform });
    }

    // MARK: - Activity Logs
    public async Task<List<ServerActivityLog>> FetchLogsAsync(string serverId, int page = 1)
    {
        var result = new List<ServerActivityLog>();
        try
        {
            string raw = await _client.GetStringAsync($"/api/server/{serverId}/logs?page={page}&limit=30");
            using var doc = JsonDocument.Parse(raw);
            var root = doc.RootElement;

            JsonElement dataArray = default;
            if (root.ValueKind == JsonValueKind.Object && root.TryGetProperty("data", out var dataProp) && dataProp.ValueKind == JsonValueKind.Array)
            {
                dataArray = dataProp;
            }
            else if (root.ValueKind == JsonValueKind.Array)
            {
                dataArray = root;
            }

            if (dataArray.ValueKind == JsonValueKind.Array)
            {
                foreach (var el in dataArray.EnumerateArray())
                {
                    string id = el.TryGetProperty("id", out var idProp) ? (idProp.ValueKind == JsonValueKind.Number ? idProp.GetInt64().ToString() : idProp.GetString() ?? string.Empty) : string.Empty;
                    string timestamp = el.TryGetProperty("timestamp", out var tsProp) ? tsProp.GetString() ?? string.Empty : string.Empty;
                    string action = el.TryGetProperty("action", out var actProp) ? actProp.GetString() ?? string.Empty : string.Empty;
                    string? username = el.TryGetProperty("username", out var userProp) && userProp.ValueKind == JsonValueKind.String ? userProp.GetString() : null;

                    string? details = null;
                    if (el.TryGetProperty("details", out var detProp))
                    {
                        details = detProp.ValueKind == JsonValueKind.String ? detProp.GetString() : detProp.GetRawText();
                    }

                    result.Add(new ServerActivityLog
                    {
                        Id = id,
                        Timestamp = timestamp,
                        Action = action,
                        Username = username,
                        Details = details
                    });
                }
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[ServerConfigService] FetchLogsAsync error: {ex.Message}");
        }

        return result;
    }
}
