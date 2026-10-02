using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using Overnode.App.Models;

namespace Overnode.App.Services;

public class ServerFilesService
{
    private static readonly Lazy<ServerFilesService> _instance = new(() => new ServerFilesService());
    public static ServerFilesService Shared => _instance.Value;
    public static ServerFilesService Instance => _instance.Value;

    private readonly APIClient _client;

    public ServerFilesService(APIClient? client = null)
    {
        _client = client ?? APIClient.Shared;
    }

    /// <summary>
    /// Normalise un chemin de fichier distant pour Pterodactyl.
    /// Pterodactyl Panel / Wings rejette les chemins débutant par un slash ('/') avec une erreur HTTP 400 Bad Request.
    /// Cette méthode convertit également les antislashs Windows ('\') en slashs ('/') et élimine les slashs consécutifs.
    /// </summary>
    public static string NormalizeServerFilePath(string? filePath)
    {
        if (string.IsNullOrWhiteSpace(filePath))
            return string.Empty;

        // Normalise les antislashs Windows en slashs
        string normalized = filePath.Trim().Replace('\\', '/');

        // Réduit les slashs consécutifs
        while (normalized.Contains("//", StringComparison.Ordinal))
        {
            normalized = normalized.Replace("//", "/");
        }

        // Pterodactyl exige un chemin relatif à la racine du serveur (aucun slash de début ou de fin)
        normalized = normalized.Trim('/');

        return normalized;
    }

    public async Task<List<ServerFileItem>> ListFilesAsync(string serverId, string directory = "/")
    {
        string encodedDir = WebUtility.UrlEncode(directory) ?? "/";
        string endpoint = $"/api/server/{serverId}/files/list?directory={encodedDir}";

        var response = await _client.GetAsync<PteroFileListResponse>(endpoint);
        var result = response.Data.Select(d =>
        {
            var attr = d.Attributes;
            return new ServerFileItem
            {
                Name = attr?.Name ?? string.Empty,
                Mode = attr?.Mode,
                Size = attr?.Size ?? 0,
                IsFile = attr?.IsFile ?? true,
                IsSymlink = attr?.IsSymlink ?? false,
                IsEditable = attr?.IsEditable ?? true,
                Mimetype = attr?.Mimetype,
                ModifiedAt = attr?.ModifiedAt
            };
        }).ToList();

        // Folders first, then alphabetically
        return result
            .OrderBy(f => f.IsFile)
            .ThenBy(f => f.Name, StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    public async Task<string> ReadFileAsync(string serverId, string filePath)
    {
        string normalized = NormalizeServerFilePath(filePath);
        if (string.IsNullOrWhiteSpace(normalized))
        {
            throw new ArgumentException("Chemin de fichier serveur invalide.", nameof(filePath));
        }
        string encodedPath = Uri.EscapeDataString(normalized);
        return await _client.GetStringAsync($"/api/server/{serverId}/files/contents?file={encodedPath}");
    }

    public async Task WriteFileAsync(string serverId, string filePath, string content)
    {
        string normalized = NormalizeServerFilePath(filePath);
        if (string.IsNullOrWhiteSpace(normalized))
        {
            throw new ArgumentException("Chemin de fichier serveur invalide.", nameof(filePath));
        }
        string encodedPath = Uri.EscapeDataString(normalized);
        await _client.PostTextAsync($"/api/server/{serverId}/files/write?file={encodedPath}", content);
    }

    public async Task CreateFolderAsync(string serverId, string root, string name)
    {
        await _client.PostEmptyAsync($"/api/server/{serverId}/files/create-folder", new { root, name });
    }

    public async Task DeleteFilesAsync(string serverId, string root, IEnumerable<string> files)
    {
        await _client.PostEmptyAsync($"/api/server/{serverId}/files/delete", new { root, files });
    }

    public async Task RenameFileAsync(string serverId, string root, string from, string to)
    {
        await _client.PutEmptyAsync($"/api/server/{serverId}/files/rename", new
        {
            root,
            files = new[] { new { from, to } }
        });
    }
}
