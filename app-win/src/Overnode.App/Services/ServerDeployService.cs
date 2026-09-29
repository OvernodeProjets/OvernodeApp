using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using Overnode.App.Models;

namespace Overnode.App.Services;

public sealed class ServerDeployService
{
    private static readonly Lazy<ServerDeployService> _instance = new(() => new ServerDeployService());
    public static ServerDeployService Instance => _instance.Value;
    public static ServerDeployService Shared => _instance.Value;

    private readonly APIClient _client = APIClient.Instance;

    private ServerDeployService() { }

    public async Task<DeployOptionsResponse> FetchDeployOptionsAsync()
    {
        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1")
        {
            return DemoDeployOptions();
        }

        try
        {
            var eggsTask = FetchRealEggsAsync();
            var locsTask = FetchRealLocationsAsync();
            var nodesTask = FetchRealNodesAsync();
            var resTask = FetchSafeAsync<ResourcesResponse>("/api/v5/resources");

            await Task.WhenAll(eggsTask, locsTask, nodesTask, resTask);

            var rawEggs = await eggsTask ?? new();
            var rawLocs = await locsTask ?? new();
            var rawNodes = await nodesTask ?? new();
            var rawRes = await resTask ?? new();

            var categories = new List<EggCategory>
            {
                new("all", "All", "square.grid.2x2"),
                new("minecraft", "Minecraft", "cube"),
                new("discord", "Discord Bots", "message"),
                new("web", "Web & DB", "globe"),
                new("game", "Games", "gamecontroller"),
                new("other", "Other", "shippingbox")
            };

            var demo = DemoDeployOptions();
            var deployRes = new DeployResourcesInfo(
                rawRes.Current ?? demo.Resources.Current,
                rawRes.Limits ?? demo.Resources.Allowed,
                rawRes.Remaining ?? demo.Resources.Remaining
            );

            Debug.WriteLine($"[ServerDeployService] Real data loaded: Eggs={rawEggs.Count}, Locations={rawLocs.Count}, Nodes={rawNodes.Count}");

            return new DeployOptionsResponse(
                categories,
                rawEggs.Count > 0 ? rawEggs : demo.Eggs,
                rawLocs.Count > 0 ? rawLocs : demo.Locations,
                rawNodes.Count > 0 ? rawNodes : demo.Nodes,
                deployRes
            );
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"[ServerDeployService] Error in FetchDeployOptionsAsync: {ex}");
            return DemoDeployOptions();
        }
    }

    private async Task<T?> FetchSafeAsync<T>(string endpoint) where T : class
    {
        try
        {
            return await _client.GetAsync<T>(endpoint);
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"[ServerDeployService] FetchSafeAsync failed for {endpoint}: {ex.Message}");
            return null;
        }
    }

    private async Task<List<ServerEgg>> FetchRealEggsAsync()
    {
        string[] endpoints = { "/api/v5/eggs", "/api/eggs" };
        foreach (var endpoint in endpoints)
        {
            try
            {
                var json = await _client.GetStringAsync(endpoint);
                if (string.IsNullOrWhiteSpace(json)) continue;

                var eggs = ParseArrayFromJson<ServerEgg>(json);
                if (eggs.Count > 0)
                {
                    Debug.WriteLine($"[ServerDeployService] Fetched {eggs.Count} eggs from {endpoint}");
                    return eggs;
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"[ServerDeployService] Failed fetching eggs from {endpoint}: {ex.Message}");
            }
        }

        return new List<ServerEgg>();
    }

    private async Task<List<ServerLocation>> FetchRealLocationsAsync()
    {
        string[] endpoints = { "/api/v5/locations", "/api/locations" };
        foreach (var endpoint in endpoints)
        {
            try
            {
                var json = await _client.GetStringAsync(endpoint);
                if (string.IsNullOrWhiteSpace(json)) continue;

                var locs = ParseArrayFromJson<ServerLocation>(json);
                if (locs.Count > 0)
                {
                    Debug.WriteLine($"[ServerDeployService] Fetched {locs.Count} locations from {endpoint}");
                    return locs;
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"[ServerDeployService] Failed fetching locations from {endpoint}: {ex.Message}");
            }
        }

        return new List<ServerLocation>();
    }

    private async Task<List<ServerNode>> FetchRealNodesAsync()
    {
        string[] endpoints = { "/api/v5/nodes", "/api/nodes" };
        foreach (var endpoint in endpoints)
        {
            try
            {
                var json = await _client.GetStringAsync(endpoint);
                if (string.IsNullOrWhiteSpace(json)) continue;

                var nodes = ParseArrayFromJson<ServerNode>(json);
                if (nodes.Count > 0)
                {
                    Debug.WriteLine($"[ServerDeployService] Fetched {nodes.Count} real nodes from {endpoint}");
                    return nodes;
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"[ServerDeployService] Failed fetching nodes from {endpoint}: {ex.Message}");
            }
        }

        return new List<ServerNode>();
    }

    private static List<T> ParseArrayFromJson<T>(string json)
    {
        var options = new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true,
            NumberHandling = JsonNumberHandling.AllowReadingFromString
        };

        try
        {
            using var doc = JsonDocument.Parse(json);
            JsonElement root = doc.RootElement;

            if (root.ValueKind == JsonValueKind.Array)
            {
                return JsonSerializer.Deserialize<List<T>>(json, options) ?? new();
            }

            if (root.ValueKind == JsonValueKind.Object)
            {
                if (root.TryGetProperty("data", out var dataElem) && dataElem.ValueKind == JsonValueKind.Array)
                {
                    return JsonSerializer.Deserialize<List<T>>(dataElem.GetRawText(), options) ?? new();
                }

                string keyName = typeof(T) == typeof(ServerNode) ? "nodes" :
                                 typeof(T) == typeof(ServerLocation) ? "locations" :
                                 typeof(T) == typeof(ServerEgg) ? "eggs" : "";

                if (!string.IsNullOrEmpty(keyName) && root.TryGetProperty(keyName, out var namedElem) && namedElem.ValueKind == JsonValueKind.Array)
                {
                    return JsonSerializer.Deserialize<List<T>>(namedElem.GetRawText(), options) ?? new();
                }
            }
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"[ServerDeployService] ParseArrayFromJson<{typeof(T).Name}> failed: {ex.Message}");
        }

        return new();
    }

    public async Task<CreateServerResult> CreateServerAsync(CreateServerPayload payload)
    {
        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1")
        {
            await Task.Delay(600);
            return new CreateServerResult
            {
                Object = "server",
                Error = null,
                Message = "Server created successfully"
            };
        }

        return await _client.PostAsync<CreateServerResult>("/api/v5/servers", payload);
    }

    public DeployOptionsResponse DemoDeployOptions()
    {
        var categories = new List<EggCategory>
        {
            new("all", "All", "square.grid.2x2"),
            new("minecraft", "Minecraft", "cube"),
            new("discord", "Discord Bots", "message"),
            new("web", "Web & DB", "globe"),
            new("game", "Games", "gamecontroller")
        };

        var eggs = new List<ServerEgg>
        {
            new("minecraft_paper", "Paper Minecraft", "High-performance Spigot fork for Minecraft servers", "minecraft", new ResourceRequirement(1024, 2048, 100)),
            new("minecraft_purpur", "Purpur Minecraft", "Configurable and optimized gameplay fork of Paper", "minecraft", new ResourceRequirement(1024, 2048, 100)),
            new("minecraft_forge", "Forge Modded", "Minecraft modded server support with Forge", "minecraft", new ResourceRequirement(2048, 4096, 150)),
            new("nodejs", "Node.js", "Node.js runtime for JavaScript & TypeScript bots", "discord", new ResourceRequirement(256, 512, 20)),
            new("python", "Python", "Python 3 runtime for Discord bots and automation", "discord", new ResourceRequirement(256, 512, 20))
        };

        var locations = new List<ServerLocation>
        {
            new("1", "France (Paris)", "Low-latency EU West datacenter with anti-DDoS protection", new() { "FR" }, false),
            new("2", "Germany (Frankfurt)", "Central Europe high-speed network hub", new() { "DE" }, false)
        };

        var nodes = new List<ServerNode>
        {
            new(1, "Node FR-01", "1"),
            new(2, "Node FR-02", "1"),
            new(3, "Node DE-01", "2")
        };

        var res = new DeployResourcesInfo(
            new ResourceBucket(3260, 9320, 141, 2),
            new ResourceBucket(8192, 40960, 400, 4),
            new ResourceBucket(4932, 31640, 259, 2)
        );

        return new DeployOptionsResponse(categories, eggs, locations, nodes, res);
    }
}
