using System.Text.Json.Serialization;

namespace Overnode.App.Models;

public sealed class UpdateCheckResponse
{
    [JsonPropertyName("updateAvailable")]
    public bool UpdateAvailable { get; set; }

    [JsonPropertyName("clientVersion")]
    public string ClientVersion { get; set; } = "1.0.0";

    [JsonPropertyName("latestVersion")]
    public string LatestVersion { get; set; } = "1.0.0";

    [JsonPropertyName("downloadUrl")]
    public string DownloadUrl { get; set; } = string.Empty;

    [JsonPropertyName("rawDownloadUrl")]
    public string RawDownloadUrl { get; set; } = string.Empty;

    [JsonPropertyName("releaseNotes")]
    public string ReleaseNotes { get; set; } = string.Empty;

    [JsonPropertyName("mandatory")]
    public bool Mandatory { get; set; }

    [JsonPropertyName("sha256")]
    public string? Sha256 { get; set; }

    [JsonPropertyName("publishedAt")]
    public string? PublishedAt { get; set; }

    [JsonPropertyName("platform")]
    public string? Platform { get; set; }
}

public enum UpdateStatus
{
    Idle,
    Checking,
    UpToDate,
    Available,
    Downloading,
    ReadyToRestart,
    Failed
}
