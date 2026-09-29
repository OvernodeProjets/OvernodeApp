using System;
using System.Text.Json.Serialization;

namespace Overnode.App.Models;

public class ResourceBucket
{
    [JsonPropertyName("ram")]
    public double Ram { get; set; }

    [JsonPropertyName("disk")]
    public double Disk { get; set; }

    [JsonPropertyName("cpu")]
    public double Cpu { get; set; }

    [JsonPropertyName("servers")]
    public int Servers { get; set; }

    public ResourceBucket() { }

    public ResourceBucket(double ram, double disk, double cpu, int servers)
    {
        Ram = ram;
        Disk = disk;
        Cpu = cpu;
        Servers = servers;
    }
}

public class ResourcesResponse
{
    [JsonPropertyName("package")]
    public string? Package { get; set; }

    [JsonPropertyName("allowed")]
    public ResourceBucket Allowed { get; set; } = new();

    [JsonPropertyName("remaining")]
    public ResourceBucket Remaining { get; set; } = new();

    [JsonPropertyName("current")]
    public ResourceBucket Current { get; set; } = new();

    [JsonPropertyName("limits")]
    public ResourceBucket Limits { get; set; } = new();

    [JsonIgnore]
    public double RamUsedGB => Current.Ram / 1024.0;

    [JsonIgnore]
    public double RamTotalGB => Limits.Ram / 1024.0;

    [JsonIgnore]
    public double DiskUsedGB => Current.Disk / 1024.0;

    [JsonIgnore]
    public double DiskTotalGB => Limits.Disk / 1024.0;

    [JsonIgnore]
    public double RamPercentage => Limits.Ram > 0 ? Math.Min((Current.Ram / Limits.Ram) * 100.0, 100.0) : 0;

    [JsonIgnore]
    public double CpuPercentage => Limits.Cpu > 0 ? Math.Min((Current.Cpu / Limits.Cpu) * 100.0, 100.0) : 0;

    [JsonIgnore]
    public double DiskPercentage => Limits.Disk > 0 ? Math.Min((Current.Disk / Limits.Disk) * 100.0, 100.0) : 0;

    [JsonIgnore]
    public double ServersPercentage => Limits.Servers > 0 ? Math.Min(((double)Current.Servers / Limits.Servers) * 100.0, 100.0) : 0;

    public static ResourcesResponse Empty => new()
    {
        Package = null,
        Allowed = new ResourceBucket(0, 0, 0, 0),
        Remaining = new ResourceBucket(0, 0, 0, 0),
        Current = new ResourceBucket(0, 0, 0, 0),
        Limits = new ResourceBucket(0, 0, 0, 0)
    };

    public static ResourcesResponse Preview => new()
    {
        Package = "Titanium",
        Allowed = new ResourceBucket(8192, 40960, 250, 3),
        Remaining = new ResourceBucket(4096, 20480, 100, 1),
        Current = new ResourceBucket(4096, 20480, 150, 2),
        Limits = new ResourceBucket(8192, 40960, 250, 3)
    };
}
