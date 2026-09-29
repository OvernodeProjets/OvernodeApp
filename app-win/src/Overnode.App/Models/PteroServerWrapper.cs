using System;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Overnode.App.Models;

public class PteroServerWrapper
{
    public class AttributesPayload
    {
        [JsonPropertyName("id")]
        public object? RawId { get; set; }

        public int Id
        {
            get
            {
                if (RawId is int i) return i;
                if (RawId is long l) return (int)l;
                if (RawId is string s && int.TryParse(s, out var parsed)) return parsed;
                if (RawId is JsonElement elem)
                {
                    if (elem.ValueKind == JsonValueKind.Number && elem.TryGetInt32(out var num)) return num;
                    if (elem.ValueKind == JsonValueKind.String && int.TryParse(elem.GetString(), out var strNum)) return strNum;
                }
                return 0;
            }
        }

        [JsonPropertyName("identifier")]
        public string Identifier { get; set; } = string.Empty;

        [JsonPropertyName("name")]
        public string Name { get; set; } = "Server";

        [JsonPropertyName("node")]
        public object? RawNode { get; set; }

        public string? Node
        {
            get
            {
                if (RawNode is string s) return s;
                if (RawNode is int i) return $"Node {i}";
                if (RawNode is JsonElement elem)
                {
                    if (elem.ValueKind == JsonValueKind.String) return elem.GetString();
                    if (elem.ValueKind == JsonValueKind.Number) return $"Node {elem.GetInt32()}";
                }
                return null;
            }
        }

        [JsonPropertyName("suspended")]
        public bool? Suspended { get; set; }

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

    [JsonPropertyName("attributes")]
    public AttributesPayload Attributes { get; set; } = new();

    public ServerInstance ToServerInstance()
    {
        return new ServerInstance
        {
            Id = Attributes.Id,
            Identifier = Attributes.Identifier,
            Name = Attributes.Name,
            Node = Attributes.Node,
            Suspended = Attributes.Suspended ?? false,
            State = (Attributes.Suspended ?? false) ? "suspended" : "offline",
            IsOwner = true,
            Permissions = new() { "*" },
            MemoryUsedMB = 0,
            MemoryLimitMB = Attributes.Limits?.Memory ?? 0,
            CpuUsedPercent = 0,
            CpuLimitPercent = Attributes.Limits?.Cpu ?? 0,
            DiskUsedMB = 0,
            DiskLimitMB = Attributes.Limits?.Disk ?? 0
        };
    }
}
