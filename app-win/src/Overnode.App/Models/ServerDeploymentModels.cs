using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace Overnode.App.Models;

public class ResourceRequirement
{
    [JsonPropertyName("ram")]
    public double Ram { get; set; }

    [JsonPropertyName("disk")]
    public double Disk { get; set; }

    [JsonPropertyName("cpu")]
    public double Cpu { get; set; }

    public ResourceRequirement() { }

    public ResourceRequirement(double ram, double disk, double cpu)
    {
        Ram = ram;
        Disk = disk;
        Cpu = cpu;
    }
}

public class ServerEgg
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("description")]
    public string Description { get; set; } = string.Empty;

    [JsonPropertyName("category")]
    public string Category { get; set; } = "other";

    [JsonPropertyName("minimum")]
    public ResourceRequirement Minimum { get; set; } = new();

    [JsonPropertyName("maximum")]
    public ResourceRequirement? Maximum { get; set; }

    public ServerEgg() { }

    public ServerEgg(string id, string name, string description, string category, ResourceRequirement min, ResourceRequirement? max = null)
    {
        Id = id;
        Name = name;
        Description = description;
        Category = category;
        Minimum = min;
        Maximum = max;
    }

    [JsonIgnore]
    public string IconGlyph => Category.ToLowerInvariant() switch
    {
        "minecraft" => "\uE7FC",     // GameController
        "discord" or "bot" or "bots" => "\uE8BD", // Chat
        "web" or "databases" => "\uE774", // Globe
        "game" or "games" => "\uE7FC",    // GameController
        _ => "\uE7B8"                     // Package
    };
}

public class EggCategory
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("icon")]
    public string Icon { get; set; } = "package";

    public EggCategory() { }

    public EggCategory(string id, string name, string icon = "package")
    {
        Id = id;
        Name = name;
        Icon = icon;
    }

    [JsonIgnore]
    public string IconGlyph => Id.ToLowerInvariant() switch
    {
        "all" => "\uE80A",        // Grid
        "minecraft" => "\uE7FC",  // GameController
        "discord" => "\uE8BD",    // Chat
        "web" => "\uE774",        // Globe
        "game" => "\uE7FC",       // GameController
        _ => "\uE7B8"             // Package
    };
}

public class ServerLocation
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("description")]
    public string Description { get; set; } = string.Empty;

    [JsonPropertyName("flags")]
    public List<string> Flags { get; set; } = new();

    [JsonPropertyName("full")]
    public bool Full { get; set; }

    public ServerLocation() { }

    public ServerLocation(string id, string name, string description = "", List<string>? flags = null, bool full = false)
    {
        Id = id;
        Name = name;
        Description = description;
        Flags = flags ?? new List<string>();
        Full = full;
    }
}

public class ServerNode
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("locationId")]
    public string LocationId { get; set; } = string.Empty;

    public ServerNode() { }

    public ServerNode(int id, string name, string locationId)
    {
        Id = id;
        Name = name;
        LocationId = locationId;
    }
}

public class DeployResourcesInfo
{
    [JsonPropertyName("current")]
    public ResourceBucket Current { get; set; } = new();

    [JsonPropertyName("allowed")]
    public ResourceBucket Allowed { get; set; } = new();

    [JsonPropertyName("remaining")]
    public ResourceBucket Remaining { get; set; } = new();

    public DeployResourcesInfo() { }

    public DeployResourcesInfo(ResourceBucket current, ResourceBucket allowed, ResourceBucket remaining)
    {
        Current = current;
        Allowed = allowed;
        Remaining = remaining;
    }
}

public class DeployOptionsResponse
{
    [JsonPropertyName("categories")]
    public List<EggCategory> Categories { get; set; } = new();

    [JsonPropertyName("eggs")]
    public List<ServerEgg> Eggs { get; set; } = new();

    [JsonPropertyName("locations")]
    public List<ServerLocation> Locations { get; set; } = new();

    [JsonPropertyName("nodes")]
    public List<ServerNode> Nodes { get; set; } = new();

    [JsonPropertyName("resources")]
    public DeployResourcesInfo Resources { get; set; } = new();

    public DeployOptionsResponse() { }

    public DeployOptionsResponse(
        List<EggCategory> categories,
        List<ServerEgg> eggs,
        List<ServerLocation> locations,
        List<ServerNode> nodes,
        DeployResourcesInfo resources)
    {
        Categories = categories;
        Eggs = eggs;
        Locations = locations;
        Nodes = nodes;
        Resources = resources;
    }
}

public class CreateServerPayload
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("egg")]
    public string Egg { get; set; } = string.Empty;

    [JsonPropertyName("nodeId")]
    public int NodeId { get; set; }

    [JsonPropertyName("ram")]
    public int Ram { get; set; }

    [JsonPropertyName("disk")]
    public int Disk { get; set; }

    [JsonPropertyName("cpu")]
    public int Cpu { get; set; }
}

public class CreateServerResult
{
    [JsonPropertyName("object")]
    public string? Object { get; set; }

    [JsonPropertyName("error")]
    public string? Error { get; set; }

    [JsonPropertyName("message")]
    public string? Message { get; set; }

    [JsonPropertyName("attributes")]
    public PteroServerWrapper.AttributesPayload? Attributes { get; set; }

    public ServerInstance ToServerInstance(string fallbackName, int fallbackRam, int fallbackDisk, int fallbackCpu, string? fallbackNode)
    {
        if (Attributes != null)
        {
            return new ServerInstance
            {
                Id = Attributes.Id,
                Identifier = string.IsNullOrEmpty(Attributes.Identifier) ? Guid.NewGuid().ToString("N")[..8] : Attributes.Identifier,
                Name = string.IsNullOrEmpty(Attributes.Name) ? fallbackName : Attributes.Name,
                Node = Attributes.Node ?? fallbackNode,
                Suspended = Attributes.Suspended ?? false,
                State = "installing",
                IsOwner = true,
                MemoryUsedMB = 0,
                MemoryLimitMB = Attributes.Limits?.Memory ?? fallbackRam,
                CpuUsedPercent = 0,
                CpuLimitPercent = Attributes.Limits?.Cpu ?? fallbackCpu,
                DiskUsedMB = 0,
                DiskLimitMB = Attributes.Limits?.Disk ?? fallbackDisk
            };
        }

        return new ServerInstance
        {
            Id = new Random().Next(1000, 9999),
            Identifier = Guid.NewGuid().ToString("N")[..8],
            Name = fallbackName,
            Node = fallbackNode,
            Suspended = false,
            State = "installing",
            IsOwner = true,
            MemoryUsedMB = 0,
            MemoryLimitMB = fallbackRam,
            CpuUsedPercent = 0,
            CpuLimitPercent = fallbackCpu,
            DiskUsedMB = 0,
            DiskLimitMB = fallbackDisk
        };
    }
}
