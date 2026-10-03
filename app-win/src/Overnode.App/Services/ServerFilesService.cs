using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text.Json.Serialization;
using System.Threading;
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

    private static readonly HttpClient _directTransferClient = new()
    {
        Timeout = TimeSpan.FromMinutes(10)
    };

    public async Task<string> GetUploadUrlAsync(string serverId, string directory = "/")
    {
        string encodedDir = WebUtility.UrlEncode(directory) ?? "/";
        var resp = await _client.GetAsync<PteroUploadUrlResponse>($"/api/server/{serverId}/files/upload?directory={encodedDir}");
        string? url = resp.Attributes?.Url ?? resp.Url;
        if (string.IsNullOrWhiteSpace(url))
        {
            throw new InvalidOperationException("URL de téléversement invalide reçue du serveur.");
        }
        return url;
    }

    public async Task UploadFileAsync(
        string uploadUrl,
        string directory,
        string fileName,
        byte[] fileData,
        CancellationToken cancellationToken = default)
    {
        string targetUrl = uploadUrl;
        if (!targetUrl.Contains("directory=", StringComparison.OrdinalIgnoreCase))
        {
            string separator = targetUrl.Contains('?') ? "&" : "?";
            string encodedDir = WebUtility.UrlEncode(directory) ?? directory;
            targetUrl += $"{separator}directory={encodedDir}";
        }

        string boundary = $"----OvernodeUploadBoundary{Guid.NewGuid():N}";
        using var content = new MultipartFormDataContent(boundary);

        var byteContent = new ByteArrayContent(fileData);
        byteContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("application/octet-stream");
        content.Add(byteContent, "files", fileName);

        using var request = new HttpRequestMessage(HttpMethod.Post, targetUrl)
        {
            Content = content
        };
        request.Headers.Add("User-Agent", "Overnode-Windows-Native/1.0");

        using var response = await _directTransferClient.SendAsync(request, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            string err = await response.Content.ReadAsStringAsync(cancellationToken);
            throw new HttpRequestException($"Échec du téléversement vers le serveur (HTTP {(int)response.StatusCode}): {err}", null, response.StatusCode);
        }
    }

    public async Task<string> GetDownloadUrlAsync(string serverId, string filePath)
    {
        string normalized = NormalizeServerFilePath(filePath);
        string encodedPath = Uri.EscapeDataString(normalized);
        var resp = await _client.GetAsync<PteroDownloadUrlResponse>($"/api/server/{serverId}/files/download?file={encodedPath}");
        string? url = resp.Attributes?.Url ?? resp.Url;
        if (string.IsNullOrWhiteSpace(url))
        {
            throw new InvalidOperationException("URL de téléchargement invalide reçue du serveur.");
        }
        return url;
    }

    public async Task DownloadFileAsync(
        string serverId,
        string filePath,
        string destinationLocalPath,
        CancellationToken cancellationToken = default)
    {
        string downloadUrl = await GetDownloadUrlAsync(serverId, filePath);
        using var response = await _directTransferClient.GetAsync(downloadUrl, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new HttpRequestException($"Échec du téléchargement du fichier (HTTP {(int)response.StatusCode})", null, response.StatusCode);
        }

        string? dir = Path.GetDirectoryName(destinationLocalPath);
        if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
        {
            Directory.CreateDirectory(dir);
        }

        using var fs = new FileStream(destinationLocalPath, FileMode.Create, FileAccess.Write, FileShare.None);
        await response.Content.CopyToAsync(fs, cancellationToken);
    }

    private class PteroUploadUrlResponse
    {
        [JsonPropertyName("object")]
        public string? Object { get; set; }

        [JsonPropertyName("attributes")]
        public PteroUploadUrlAttributes? Attributes { get; set; }

        [JsonPropertyName("url")]
        public string? Url { get; set; }
    }

    private class PteroUploadUrlAttributes
    {
        [JsonPropertyName("url")]
        public string? Url { get; set; }
    }

    private class PteroDownloadUrlResponse
    {
        [JsonPropertyName("object")]
        public string? Object { get; set; }

        [JsonPropertyName("attributes")]
        public PteroDownloadUrlAttributes? Attributes { get; set; }

        [JsonPropertyName("url")]
        public string? Url { get; set; }
    }

    private class PteroDownloadUrlAttributes
    {
        [JsonPropertyName("url")]
        public string? Url { get; set; }
    }
}
