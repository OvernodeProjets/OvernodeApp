using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Overnode.App.Models;

namespace Overnode.App.Services;

/// <summary>
/// Exécuteur des opérations réseau de synchronisation de dossiers (création de dossiers distants,
/// téléversement de fichiers modifiés, suppression distante, et récupération initiale).
/// </summary>
public static class FolderSyncExecutor
{
    public static string JoinPath(string root, string sub)
    {
        string cleanRoot = (root == "/" ? string.Empty : root).TrimEnd('/');
        string cleanSub = sub.TrimStart('/');
        return $"{cleanRoot}/{cleanSub}";
    }

    public static async Task CreateRemoteDirectoriesAsync(
        string serverId,
        string remotePath,
        IEnumerable<string> relDirs)
    {
        var service = ServerFilesService.Shared;
        foreach (var relDir in relDirs)
        {
            string fullPath = JoinPath(remotePath, relDir);
            int lastSlash = fullPath.LastIndexOf('/');
            string parent = lastSlash <= 0 ? "/" : fullPath[..lastSlash];
            string name = lastSlash >= 0 ? fullPath[(lastSlash + 1)..] : fullPath;

            try
            {
                await service.CreateFolderAsync(serverId, parent, name);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[FolderSyncExecutor] Create directory '{fullPath}' warning: {ex.Message}");
            }
        }
    }

    public static async Task UploadChangedFilesAsync(
        string serverId,
        string remotePath,
        string localRoot,
        IEnumerable<LocalFileRecord> files,
        CancellationToken cancellationToken = default)
    {
        var service = ServerFilesService.Shared;
        foreach (var fileRecord in files)
        {
            string fullLocal = Path.Combine(localRoot, fileRecord.RelativePath.Replace('/', Path.DirectorySeparatorChar));
            string fullRemote = JoinPath(remotePath, fileRecord.RelativePath);
            int lastSlash = fullRemote.LastIndexOf('/');
            string parent = lastSlash <= 0 ? "/" : fullRemote[..lastSlash];
            string name = lastSlash >= 0 ? fullRemote[(lastSlash + 1)..] : fullRemote;

            if (!File.Exists(fullLocal)) continue;

            try
            {
                byte[] fileData = await File.ReadAllBytesAsync(fullLocal, cancellationToken);
                string uploadUrl = await service.GetUploadUrlAsync(serverId, parent);
                await service.UploadFileAsync(uploadUrl, parent, name, fileData, cancellationToken);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[FolderSyncExecutor] Upload failed for '{name}': {ex.Message}");
            }
        }
    }

    public static async Task DeleteRemotePathsAsync(
        string serverId,
        string remotePath,
        IEnumerable<string> paths)
    {
        var service = ServerFilesService.Shared;
        var deletionsByParent = new Dictionary<string, List<string>>(StringComparer.OrdinalIgnoreCase);

        foreach (var relPath in paths)
        {
            string fullRemote = JoinPath(remotePath, relPath);
            int lastSlash = fullRemote.LastIndexOf('/');
            string parent = lastSlash <= 0 ? "/" : fullRemote[..lastSlash];
            string name = lastSlash >= 0 ? fullRemote[(lastSlash + 1)..] : fullRemote;

            if (!deletionsByParent.TryGetValue(parent, out var list))
            {
                list = new List<string>();
                deletionsByParent[parent] = list;
            }
            list.Add(name);
        }

        foreach (var (parent, names) in deletionsByParent)
        {
            try
            {
                await service.DeleteFilesAsync(serverId, parent, names);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[FolderSyncExecutor] Delete remote paths in '{parent}' warning: {ex.Message}");
            }
        }
    }

    public static async Task PullRemoteFilesAsync(
        string serverId,
        string remotePath,
        string localRoot,
        Action<string>? onDownloadStarted = null,
        Action<string>? onDownloadCompleted = null,
        CancellationToken cancellationToken = default)
    {
        var service = ServerFilesService.Shared;
        List<ServerFileItem> remoteFiles;
        try
        {
            remoteFiles = await service.ListFilesAsync(serverId, remotePath);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[FolderSyncExecutor] Pull remote files list error: {ex.Message}");
            return;
        }

        foreach (var item in remoteFiles.Where(f => f.IsFile))
        {
            string itemRemotePath = JoinPath(remotePath, item.Name);
            string destLocal = Path.Combine(localRoot, item.Name);

            try
            {
                onDownloadStarted?.Invoke(destLocal);
                await service.DownloadFileAsync(serverId, itemRemotePath, destLocal, cancellationToken);
                onDownloadCompleted?.Invoke(destLocal);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[FolderSyncExecutor] Download file '{item.Name}' failed: {ex.Message}");
            }
        }
    }
}
