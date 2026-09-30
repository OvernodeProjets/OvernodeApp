using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;
using CommunityToolkit.Mvvm.ComponentModel;

namespace Overnode.App.Models;

public class ServerInstance : ObservableObject
{
    private int _id;
    [JsonPropertyName("id")]
    public int Id
    {
        get => _id;
        set => SetProperty(ref _id, value);
    }

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
        set
        {
            if (SetProperty(ref _identifier, value))
            {
                OnPropertyChanged(nameof(Identifier));
            }
        }
    }

    private string? _uuid;
    [JsonPropertyName("uuid")]
    public string? Uuid
    {
        get => _uuid;
        set
        {
            if (SetProperty(ref _uuid, value))
            {
                OnPropertyChanged(nameof(Identifier));
            }
        }
    }

    private string _name = "Server";
    [JsonPropertyName("name")]
    public string Name
    {
        get => _name;
        set => SetProperty(ref _name, value);
    }

    private string? _node;
    [JsonPropertyName("node")]
    public string? Node
    {
        get => _node;
        set => SetProperty(ref _node, value);
    }

    private bool _suspended;
    [JsonPropertyName("suspended")]
    public bool Suspended
    {
        get => _suspended;
        set
        {
            if (SetProperty(ref _suspended, value))
            {
                OnPropertyChanged(nameof(StatusKey));
                OnPropertyChanged(nameof(StatusColorHex));
            }
        }
    }

    private string _state = "offline";
    [JsonPropertyName("state")]
    public string State
    {
        get => _state;
        set
        {
            if (SetProperty(ref _state, value))
            {
                OnPropertyChanged(nameof(IsOnline));
                OnPropertyChanged(nameof(StatusKey));
                OnPropertyChanged(nameof(StatusColorHex));
            }
        }
    }

    private bool _isOwner = true;
    [JsonPropertyName("isOwner")]
    public bool IsOwner
    {
        get => _isOwner;
        set
        {
            if (SetProperty(ref _isOwner, value))
            {
                OnPropertyChanged(nameof(IsShared));
                OnPropertyChanged(nameof(CanDelete));
                OnPropertyChanged(nameof(CanRenew));
            }
        }
    }

    private List<string> _permissions = new() { "*" };
    [JsonPropertyName("permissions")]
    public List<string> Permissions
    {
        get => _permissions;
        set
        {
            if (SetProperty(ref _permissions, value))
            {
                OnPropertyChanged(nameof(CanStart));
                OnPropertyChanged(nameof(CanStop));
                OnPropertyChanged(nameof(CanRestart));
                OnPropertyChanged(nameof(CanConsole));
                OnPropertyChanged(nameof(CanManageFiles));
            }
        }
    }

    private double _memoryUsedMB;
    [JsonPropertyName("memoryUsedMB")]
    public double MemoryUsedMB
    {
        get => _memoryUsedMB;
        set
        {
            if (SetProperty(ref _memoryUsedMB, value))
            {
                OnPropertyChanged(nameof(MemoryPercent));
                OnPropertyChanged(nameof(MemoryPercentValue));
                OnPropertyChanged(nameof(MemoryDisplay));
            }
        }
    }

    private double _memoryLimitMB;
    [JsonPropertyName("memoryLimitMB")]
    public double MemoryLimitMB
    {
        get => _memoryLimitMB;
        set
        {
            if (SetProperty(ref _memoryLimitMB, value))
            {
                OnPropertyChanged(nameof(MemoryPercent));
                OnPropertyChanged(nameof(MemoryPercentValue));
                OnPropertyChanged(nameof(MemoryDisplay));
            }
        }
    }

    private double _cpuUsedPercent;
    [JsonPropertyName("cpuUsedPercent")]
    public double CpuUsedPercent
    {
        get => _cpuUsedPercent;
        set
        {
            if (SetProperty(ref _cpuUsedPercent, value))
            {
                OnPropertyChanged(nameof(CpuPercent));
                OnPropertyChanged(nameof(CpuPercentValue));
                OnPropertyChanged(nameof(CpuDisplay));
            }
        }
    }

    private double _cpuLimitPercent;
    [JsonPropertyName("cpuLimitPercent")]
    public double CpuLimitPercent
    {
        get => _cpuLimitPercent;
        set
        {
            if (SetProperty(ref _cpuLimitPercent, value))
            {
                OnPropertyChanged(nameof(CpuPercent));
                OnPropertyChanged(nameof(CpuPercentValue));
                OnPropertyChanged(nameof(CpuDisplay));
            }
        }
    }

    private double _diskUsedMB;
    [JsonPropertyName("diskUsedMB")]
    public double DiskUsedMB
    {
        get => _diskUsedMB;
        set
        {
            if (SetProperty(ref _diskUsedMB, value))
            {
                OnPropertyChanged(nameof(DiskPercent));
                OnPropertyChanged(nameof(DiskPercentValue));
                OnPropertyChanged(nameof(DiskDisplay));
            }
        }
    }

    private double _diskLimitMB;
    [JsonPropertyName("diskLimitMB")]
    public double DiskLimitMB
    {
        get => _diskLimitMB;
        set
        {
            if (SetProperty(ref _diskLimitMB, value))
            {
                OnPropertyChanged(nameof(DiskPercent));
                OnPropertyChanged(nameof(DiskPercentValue));
                OnPropertyChanged(nameof(DiskDisplay));
            }
        }
    }

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
