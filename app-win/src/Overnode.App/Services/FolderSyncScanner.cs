using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Overnode.App.Models;

namespace Overnode.App.Services;

/// <summary>
/// Analyseur et moteur de diff haute performance pour les dossiers locaux synchronisés avec Overnode.
/// Détecte instantanément les fichiers créés, modifiés ou supprimés.
/// </summary>
public static class FolderSyncScanner
{
    public static Dictionary<string, LocalFileRecord> Scan(string rootPath)
    {
        var records = new Dictionary<string, LocalFileRecord>(StringComparer.OrdinalIgnoreCase);
        if (string.IsNullOrWhiteSpace(rootPath) || !Directory.Exists(rootPath))
        {
            return records;
        }

        string resolvedRoot = Path.GetFullPath(rootPath).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
        var dirInfo = new DirectoryInfo(resolvedRoot);

        try
        {
            ScanRecursive(dirInfo, resolvedRoot, records);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[FolderSyncScanner] Scan warning for {rootPath}: {ex.Message}");
        }

        return records;
    }

    private static void ScanRecursive(DirectoryInfo currentDir, string rootPath, Dictionary<string, LocalFileRecord> records)
    {
        // Traiter les sous-dossiers
        foreach (var subDir in currentDir.EnumerateDirectories())
        {
            if (FileUploadSecurity.Shared.ShouldIgnore(subDir.Name) ||
                subDir.Name.StartsWith('.') ||
                subDir.Attributes.HasFlag(FileAttributes.ReparsePoint))
            {
                continue;
            }

            string relPath = GetRelativePath(rootPath, subDir.FullName);
            if (!string.IsNullOrEmpty(relPath))
            {
                records[relPath] = new LocalFileRecord(
                    RelativePath: relPath,
                    ModificationDate: subDir.LastWriteTimeUtc,
                    Size: 0,
                    IsDirectory: true
                );
            }

            ScanRecursive(subDir, rootPath, records);
        }

        // Traiter les fichiers
        foreach (var file in currentDir.EnumerateFiles())
        {
            if (FileUploadSecurity.Shared.ShouldIgnore(file.Name) ||
                file.Name.StartsWith('.') ||
                file.Attributes.HasFlag(FileAttributes.ReparsePoint))
            {
                continue;
            }

            string relPath = GetRelativePath(rootPath, file.FullName);
            if (!string.IsNullOrEmpty(relPath))
            {
                records[relPath] = new LocalFileRecord(
                    RelativePath: relPath,
                    ModificationDate: file.LastWriteTimeUtc,
                    Size: file.Length,
                    IsDirectory: false
                );
            }
        }
    }

    private static string GetRelativePath(string rootPath, string fullPath)
    {
        string normRoot = Path.GetFullPath(rootPath).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
        string normFull = Path.GetFullPath(fullPath);

        if (!normFull.StartsWith(normRoot, StringComparison.OrdinalIgnoreCase))
        {
            return string.Empty;
        }

        string sub = normFull[normRoot.Length..].TrimStart(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
        return sub.Replace('\\', '/');
    }

    public static FolderSyncDiff Diff(
        Dictionary<string, LocalFileRecord> oldSnapshot,
        Dictionary<string, LocalFileRecord> newSnapshot)
    {
        var addedDirs = new List<string>();
        var addedOrModified = new List<LocalFileRecord>();
        var deleted = new List<string>();

        // Nouveaux éléments ou modifiés
        foreach (var (relPath, newRec) in newSnapshot)
        {
            if (oldSnapshot.TryGetValue(relPath, out var oldRec))
            {
                if (!newRec.IsDirectory && (newRec.ModificationDate > oldRec.ModificationDate || newRec.Size != oldRec.Size))
                {
                    addedOrModified.Add(newRec);
                }
            }
            else
            {
                if (newRec.IsDirectory)
                {
                    addedDirs.Add(relPath);
                }
                else
                {
                    addedOrModified.Add(newRec);
                }
            }
        }

        // Éléments supprimés
        foreach (var (relPath, _) in oldSnapshot)
        {
            if (!newSnapshot.ContainsKey(relPath))
            {
                deleted.Add(relPath);
            }
        }

        // Trier les sous-dossiers par profondeur (pour créer les dossiers parents avant les enfants)
        addedDirs = addedDirs
            .OrderBy(d => d.Count(c => c == '/'))
            .ThenBy(d => d, StringComparer.OrdinalIgnoreCase)
            .ToList();

        return new FolderSyncDiff
        {
            AddedDirectories = addedDirs,
            AddedOrModifiedFiles = addedOrModified,
            DeletedPaths = deleted
        };
    }
}
