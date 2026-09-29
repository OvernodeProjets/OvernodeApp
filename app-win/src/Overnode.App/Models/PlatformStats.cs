using System.Text.Json.Serialization;

namespace Overnode.App.Models;

public class PlatformStatsResponse
{
    [JsonPropertyName("totalUsers")]
    public int? TotalUsers { get; set; }

    [JsonPropertyName("totalServers")]
    public int? TotalServers { get; set; }

    [JsonPropertyName("totalNodes")]
    public int? TotalNodes { get; set; }

    [JsonPropertyName("totalLocations")]
    public int? TotalLocations { get; set; }

    public PlatformStatsResponse() { }

    public PlatformStatsResponse(int totalUsers, int totalServers, int totalNodes, int totalLocations)
    {
        TotalUsers = totalUsers;
        TotalServers = totalServers;
        TotalNodes = totalNodes;
        TotalLocations = totalLocations;
    }
}
