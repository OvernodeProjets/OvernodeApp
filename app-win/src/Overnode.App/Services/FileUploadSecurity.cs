using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Overnode.App.Localization;

namespace Overnode.App.Services;

public record FileUploadItem(
    string LocalPath,
    string RelativePath,
    string FileName,
    bool IsDirectory,
    long Size
);

public record FileUploadPlan(
    List<string> DirectoriesToCreate,
    List<FileUploadItem> FilesToUpload,
    long TotalByteSize
);

public enum FileUploadErrorKind
{
    EmptySelection,
    TooManyFiles,
    SingleFileSizeExceeded,
    InsufficientDiskQuota,
    SecurityViolation,
    UploadFailed
}

public class FileUploadException : Exception
{
    public FileUploadErrorKind Kind { get; }
    public string? TargetItem { get; }

    public FileUploadException(FileUploadErrorKind kind, string message, string? targetItem = null)
        : base(message)
    {
        Kind = kind;
        TargetItem = targetItem;
    }
}

/// <summary>
/// Gestionnaire de sécurité et de conformité des transferts de fichiers et dossiers vers Overnode.
/// Vérifie les traversées de chemin, les limites de taille, le quota disque et filtre les fichiers système/temporaires.
/// </summary>
public sealed class FileUploadSecurity
{
    private static readonly Lazy<FileUploadSecurity> _instance = new(() => new FileUploadSecurity());
    public static FileUploadSecurity Shared => _instance.Value;
    public static FileUploadSecurity Instance => _instance.Value;

    public const int MaxBatchFileCount = 500;
    public const long MaxSingleFileSize = 100L * 1024 * 1024; // 100 Mo

    private static readonly HashSet<string> IgnoredFileNames = new(StringComparer.OrdinalIgnoreCase)
    {
        ".ds_store", "desktop.ini", "thumbs.db", "__macosx", ".localized",
        ".trashes", ".fseventsd", ".spotlight-v100", ".temporaryitems",
        ".git", ".vs", ".idea"
    };

    private FileUploadSecurity() { }

    public bool ShouldIgnore(string fileName)
    {
        if (string.IsNullOrWhiteSpace(fileName)) return true;

        string lower = fileName.Trim().ToLowerInvariant();
        if (lower.StartsWith("._", StringComparison.Ordinal) ||
            lower.StartsWith("~$", StringComparison.Ordinal) ||
            lower.EndsWith(".tmp", StringComparison.Ordinal) ||
            lower.EndsWith(".swp", StringComparison.Ordinal))
        {
            return true;
        }

        return IgnoredFileNames.Contains(lower);
    }

    public void ValidatePathSecurity(string path)
    {
        if (string.IsNullOrWhiteSpace(path))
        {
            throw new FileUploadException(FileUploadErrorKind.SecurityViolation, "Chemin de fichier vide");
        }

        if (path.Contains("..", StringComparison.Ordinal) ||
            path.Contains('\0') ||
            path.Contains("//", StringComparison.Ordinal))
        {
            throw new FileUploadException(FileUploadErrorKind.SecurityViolation, "Tentative de traversée de chemin non autorisée");
        }

        var parts = path.Split(new[] { '/', '\\' }, StringSplitOptions.None);
        foreach (var p in parts)
        {
            if (string.IsNullOrWhiteSpace(p) && parts.Length > 1)
            {
                throw new FileUploadException(FileUploadErrorKind.SecurityViolation, "Nom de dossier ou fichier vide dans le chemin");
            }
        }
    }

    public FileUploadPlan BuildPlan(IEnumerable<string> paths, double diskLimitMB = 0, double diskUsedMB = 0)
    {
        var inputList = paths?.ToList() ?? new List<string>();
        if (inputList.Count == 0)
        {
            throw new FileUploadException(FileUploadErrorKind.EmptySelection,
                LocalizationManager.Instance.GetString("files_upload_error_empty"));
        }

        var directories = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var files = new List<FileUploadItem>();
        long totalBytes = 0;

        foreach (var rootPath in inputList)
        {
            if (string.IsNullOrWhiteSpace(rootPath)) continue;

            if (Directory.Exists(rootPath))
            {
                string dirName = Path.GetFileName(rootPath.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar));
                if (string.IsNullOrEmpty(dirName) || ShouldIgnore(dirName)) continue;

                ValidatePathSecurity(dirName);
                directories.Add(dirName);

                ScanDirectory(rootPath, dirName, directories, files, ref totalBytes);
            }
            else if (File.Exists(rootPath))
            {
                string fileName = Path.GetFileName(rootPath);
                if (ShouldIgnore(fileName)) continue;

                ValidatePathSecurity(fileName);

                long size = new FileInfo(rootPath).Length;
                if (size > MaxSingleFileSize)
                {
                    int maxMB = (int)(MaxSingleFileSize / (1024 * 1024));
                    throw new FileUploadException(FileUploadErrorKind.SingleFileSizeExceeded,
                        LocalizationManager.Instance.Format("files_upload_error_filesize", fileName, maxMB),
                        fileName);
                }

                totalBytes += size;
                files.Add(new FileUploadItem(rootPath, fileName, fileName, false, size));
            }

            if (files.Count + directories.Count > MaxBatchFileCount)
            {
                throw new FileUploadException(FileUploadErrorKind.TooManyFiles,
                    LocalizationManager.Instance.Format("files_upload_error_maxcount", files.Count + directories.Count, MaxBatchFileCount));
            }
        }

        if (files.Count == 0 && directories.Count == 0)
        {
            throw new FileUploadException(FileUploadErrorKind.EmptySelection,
                LocalizationManager.Instance.GetString("files_upload_error_empty"));
        }

        if (diskLimitMB > 0)
        {
            double availableMB = Math.Max(0, diskLimitMB - diskUsedMB);
            double requiredMB = totalBytes / (1024.0 * 1024.0);
            if (requiredMB > availableMB)
            {
                throw new FileUploadException(FileUploadErrorKind.InsufficientDiskQuota,
                    LocalizationManager.Instance.Format("files_upload_error_quota", availableMB, requiredMB));
            }
        }

        // Trier les sous-dossiers par profondeur (moins de slashs en premier pour créer les parents d'abord)
        var sortedDirs = directories
            .OrderBy(d => d.Count(c => c == '/' || c == '\\'))
            .ThenBy(d => d, StringComparer.OrdinalIgnoreCase)
            .Select(d => d.Replace('\\', '/'))
            .ToList();

        return new FileUploadPlan(sortedDirs, files, totalBytes);
    }

    private void ScanDirectory(
        string rootDir,
        string baseRelPath,
        HashSet<string> directories,
        List<FileUploadItem> files,
        ref long totalBytes)
    {
        var dirInfo = new DirectoryInfo(rootDir);

        // Sous-dossiers
        foreach (var subDir in dirInfo.EnumerateDirectories())
        {
            if (ShouldIgnore(subDir.Name) || subDir.Attributes.HasFlag(FileAttributes.ReparsePoint))
                continue;

            string rel = $"{baseRelPath}/{subDir.Name}";
            ValidatePathSecurity(rel);
            directories.Add(rel);

            ScanDirectory(subDir.FullName, rel, directories, files, ref totalBytes);

            if (files.Count + directories.Count > MaxBatchFileCount)
            {
                throw new FileUploadException(FileUploadErrorKind.TooManyFiles,
                    LocalizationManager.Instance.Format("files_upload_error_maxcount", files.Count + directories.Count, MaxBatchFileCount));
            }
        }

        // Fichiers
        foreach (var file in dirInfo.EnumerateFiles())
        {
            if (ShouldIgnore(file.Name) || file.Attributes.HasFlag(FileAttributes.ReparsePoint))
                continue;

            string rel = $"{baseRelPath}/{file.Name}";
            ValidatePathSecurity(rel);

            long size = file.Length;
            if (size > MaxSingleFileSize)
            {
                int maxMB = (int)(MaxSingleFileSize / (1024 * 1024));
                throw new FileUploadException(FileUploadErrorKind.SingleFileSizeExceeded,
                    LocalizationManager.Instance.Format("files_upload_error_filesize", file.Name, maxMB),
                    file.Name);
            }

            totalBytes += size;
            files.Add(new FileUploadItem(file.FullName, rel, file.Name, false, size));

            if (files.Count + directories.Count > MaxBatchFileCount)
            {
                throw new FileUploadException(FileUploadErrorKind.TooManyFiles,
                    LocalizationManager.Instance.Format("files_upload_error_maxcount", files.Count + directories.Count, MaxBatchFileCount));
            }
        }
    }
}
