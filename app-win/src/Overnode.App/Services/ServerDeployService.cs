using System;
using System.Collections.Generic;
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
            var eggsTask = FetchSafeAsync<List<ServerEgg>>("/api/v5/eggs");
            var locsTask = FetchSafeAsync<List<ServerLocation>>("/api/v5/locations");
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

            return new DeployOptionsResponse(
                categories,
                rawEggs.Count > 0 ? rawEggs : demo.Eggs,
                rawLocs.Count > 0 ? rawLocs : demo.Locations,
                rawNodes.Count > 0 ? rawNodes : demo.Nodes,
                deployRes
            );
        }
        catch
        {
            return DemoDeployOptions();
        }
    }

    private async Task<T?> FetchSafeAsync<T>(string endpoint) where T : class
    {
        try
        {
            return await _client.GetAsync<T>(endpoint);
        }
        catch
        {
            return null;
        }
    }

    private async Task<List<ServerNode>> FetchRealNodesAsync()
    {
        try
        {
            var nodes = await _client.GetAsync<List<ServerNode>>("/api/v5/nodes");
            if (nodes != null && nodes.Count > 0) return nodes;
        }
        catch { }

        try
        {
            var nodes = await _client.GetAsync<List<ServerNode>>("/api/nodes");
            if (nodes != null && nodes.Count > 0) return nodes;
        }
        catch { }

        return new List<ServerNode>();
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
