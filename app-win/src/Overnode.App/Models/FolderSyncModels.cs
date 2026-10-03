using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json.Serialization;

namespace Overnode.App.Models;

/// <summary>
/// Configuration représentant l'association entre un dossier distant sur le serveur Overnode
/// et un dossier local sur la machine Windows.
/// </summary>
public class SyncedFolderConfig : IEquatable<SyncedFolderConfig>
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = Guid.NewGuid().ToString("N");

    [JsonPropertyName("serverId")]
    public string ServerId { get; set; } = string.Empty;

    [JsonPropertyName("remotePath")]
    public string RemotePath { get; set; } = string.Empty;

    [JsonPropertyName("localPath")]
    public string LocalPath { get; set; } = string.Empty;

    [JsonPropertyName("isEnabled")]
    public bool IsEnabled { get; set; } = true;

    [JsonPropertyName("lastSyncDate")]
    public DateTime? LastSyncDate { get; set; }

    [JsonIgnore]
    public string FolderName
    {
        get
        {
            if (string.IsNullOrWhiteSpace(RemotePath) || RemotePath == "/")
                return "root";

            string trimmed = RemotePath.TrimEnd('/');
            int lastSlash = trimmed.LastIndexOf('/');
            return lastSlash >= 0 ? trimmed[(lastSlash + 1)..] : trimmed;
        }
    }

    public bool Equals(SyncedFolderConfig? other)
    {
        if (other is null) return false;
        if (ReferenceEquals(this, other)) return true;
        return string.Equals(Id, other.Id, StringComparison.OrdinalIgnoreCase);
    }

    public override bool Equals(object? obj) => Equals(obj as SyncedFolderConfig);

    public override int GetHashCode() => StringComparer.OrdinalIgnoreCase.GetHashCode(Id);
}

/// <summary>
/// Capture instantanée d'un fichier ou sous-dossier local utilisée pour le calcul de diff haute performance.
/// </summary>
public record LocalFileRecord(
    string RelativePath,
    DateTime ModificationDate,
    long Size,
    bool IsDirectory
);

/// <summary>
/// Différences détectées entre deux états successifs du dossier local surveillé.
/// </summary>
public class FolderSyncDiff
{
    public List<string> AddedDirectories { get; init; } = new();
    public List<LocalFileRecord> AddedOrModifiedFiles { get; init; } = new();
    public List<string> DeletedPaths { get; init; } = new();

    public bool HasChanges => AddedDirectories.Count > 0 || AddedOrModifiedFiles.Count > 0 || DeletedPaths.Count > 0;
    public int TotalCount => AddedDirectories.Count + AddedOrModifiedFiles.Count + DeletedPaths.Count;
}

/// <summary>
/// État de la synchronisation d'un dossier.
/// </summary>
public enum FolderSyncStatus
{
    Idle,
    Syncing,
    Success,
    Error
}
