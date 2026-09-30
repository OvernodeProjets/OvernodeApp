using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace Overnode.App.Models;

public class ServerInstance
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    private string _identifier = string.Empty;

    [JsonPropertyName("identifier")]
    public string Identifier
    {
        get
        {
            if (!string.IsNullOrWhiteSpace(_identifier)) return _identifier;
            if (!string.IsNullOrWhiteSpace(Uuid) && Uuid.Length >= 8) return Uuid[..8];
            if (Id > 0) return Id.ToString();
            return string.Empty;
        }
        set => _identifier = value;
    }

    [JsonPropertyName("uuid")]
    public string? Uuid { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = "Server";

    [JsonPropertyName("node")]
    public string? Node { get; set; }

    [JsonPropertyName("suspended")]
    public bool Suspended { get; set; }

    [JsonPropertyName("state")]
    public string State { get; set; } = "offline";

    [JsonPropertyName("isOwner")]
    public bool IsOwner { get; set; } = true;

    [JsonPropertyName("permissions")]
    public List<string> Permissions { get; set; } = new() { "*" };

    [JsonPropertyName("memoryUsedMB")]
    public double MemoryUsedMB { get; set; }

    [JsonPropertyName("memoryLimitMB")]
    public double MemoryLimitMB { get; set; }

    [JsonPropertyName("cpuUsedPercent")]
    public double CpuUsedPercent { get; set; }

    [JsonPropertyName("cpuLimitPercent")]
    public double CpuLimitPercent { get; set; }

    [JsonPropertyName("diskUsedMB")]
    public double DiskUsedMB { get; set; }

    [JsonPropertyName("diskLimitMB")]
    public double DiskLimitMB { get; set; }

    // Helpers
    [JsonIgnore]
    public bool IsOnline => string.Equals(State, "running", StringComparison.OrdinalIgnoreCase);

    [JsonIgnore]
    public bool IsShared => !IsOwner;

    public bool HasPermission(string perm)
    {
        if (IsOwner) return true;
        if (Permissions.Contains("*")) return true;
        return Permissions.Contains(perm);
    }

    [JsonIgnore]
    public bool CanStart => HasPermission("control.start");

    [JsonIgnore]
    public bool CanStop => HasPermission("control.stop");

    [JsonIgnore]
    public bool CanRestart => HasPermission("control.restart");

    [JsonIgnore]
    public bool CanConsole => HasPermission("control.console");

    [JsonIgnore]
    public bool CanManageFiles => HasPermission("file.read") || HasPermission("file.create");

    [JsonIgnore]
    public bool CanDelete => IsOwner;

    [JsonIgnore]
    public bool CanRenew => IsOwner;

    // Formatting helpers for WinUI 3
    [JsonIgnore]
    public string StatusColorHex
    {
        get
        {
            if (Suspended) return "#EF4444"; // Red
            return State.ToLowerInvariant() switch
            {
                "running" => "#22C55E", // Emerald Green
                "starting" or "stopping" => "#F59E0B", // Amber
                _ => "#737A8C" // Gray
            };
        }
    }

    [JsonIgnore]
    public string StatusKey
    {
        get
        {
            if (Suspended) return "server_status_suspended";
            return State.ToLowerInvariant() switch
            {
                "running" => "server_status_online",
                "starting" => "server_status_starting",
                "stopping" => "server_status_stopping",
                _ => "server_status_offline"
            };
        }
    }

    [JsonIgnore]
    public double MemoryPercent => MemoryLimitMB > 0 ? Math.Clamp(MemoryUsedMB / MemoryLimitMB, 0, 1.0) : 0;

    [JsonIgnore]
    public double MemoryPercentValue => MemoryPercent * 100.0;

    [JsonIgnore]
    public string MemoryDisplay => $"{MemoryUsedMB:F0} / {MemoryLimitMB:F0} MB";

    [JsonIgnore]
    public double CpuPercent => CpuLimitPercent > 0 ? Math.Clamp(CpuUsedPercent / CpuLimitPercent, 0, 1.0) : 0;

    [JsonIgnore]
    public double CpuPercentValue => CpuPercent * 100.0;

    [JsonIgnore]
    public string CpuDisplay => $"{CpuUsedPercent:F1} / {CpuLimitPercent:F0}%";

    [JsonIgnore]
    public double DiskPercent => DiskLimitMB > 0 ? Math.Clamp(DiskUsedMB / DiskLimitMB, 0, 1.0) : 0;

    [JsonIgnore]
    public double DiskPercentValue => DiskPercent * 100.0;

    [JsonIgnore]
    public string DiskDisplay
    {
        get
        {
            var usedStr = DiskUsedMB >= 1024 ? $"{DiskUsedMB / 1024.0:F2} GB" : $"{DiskUsedMB:F0} MB";
            var limitStr = DiskLimitMB >= 1024 ? $"{DiskLimitMB / 1024.0:F0} GB" : $"{DiskLimitMB:F0} MB";
            return $"{usedStr} / {limitStr}";
        }
    }
}
