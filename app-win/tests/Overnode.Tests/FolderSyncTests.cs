using System;
using System.IO;
using System.Text.Json;
using System.Threading.Tasks;
using Overnode.App.Models;
using Overnode.App.Services;

namespace Overnode.Tests;

public static class FolderSyncTests
{
    public static void RunAll(Action<string, Action> run)
    {
        run("FolderSync Config Serialization & Deserialization", TestConfigSerialization);
        run("FolderSync Snapshot Creation & Ignored Files", TestFolderSnapshotCreation);
        run("FolderSync Diff Calculation (Add, Modify, Nested)", TestFolderDiffCalculation);
        run("FolderSyncManager Register, Status & Stop", () => TestFolderSyncManagerRegistration().GetAwaiter().GetResult());
    }

    private static void TestConfigSerialization()
    {
        var config = new SyncedFolderConfig
        {
            Id = "sync-123",
            ServerId = "srv-abc-456",
            LocalPath = @"C:\Users\Test\OvernodeSync\plugins",
            RemotePath = "/plugins",
            IsEnabled = true,
            LastSyncDate = DateTime.UtcNow
        };

        var json = JsonSerializer.Serialize(config);
        Assert.IsTrue(!string.IsNullOrEmpty(json), "Serialized JSON should not be empty");

        var deserialized = JsonSerializer.Deserialize<SyncedFolderConfig>(json);
        Assert.IsNotNull(deserialized, "Deserialized config should not be null");
        Assert.AreEqual(config.Id, deserialized!.Id, "Id must match");
        Assert.AreEqual(config.ServerId, deserialized.ServerId, "ServerId must match");
        Assert.AreEqual(config.LocalPath, deserialized.LocalPath, "LocalPath must match");
        Assert.AreEqual(config.RemotePath, deserialized.RemotePath, "RemotePath must match");
        Assert.IsTrue(deserialized.IsEnabled, "IsEnabled must match");
    }

    private static void TestFolderSnapshotCreation()
    {
        var tempDir = Path.Combine(Path.GetTempPath(), "overnode_sync_snap_" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(tempDir);
        var subDir = Path.Combine(tempDir, "sub");
        Directory.CreateDirectory(subDir);

        try
        {
            File.WriteAllText(Path.Combine(tempDir, "file1.txt"), "hello world");
            File.WriteAllText(Path.Combine(subDir, "file2.txt"), "sub world");
            File.WriteAllText(Path.Combine(tempDir, ".ds_store"), "ignore me");
            File.WriteAllText(Path.Combine(tempDir, "desktop.ini"), "ignore me too");

            var snapshot = FolderSyncScanner.Scan(tempDir);
            // Scan indexes valid files AND subdirectories
            Assert.IsTrue(snapshot.ContainsKey("file1.txt"), "file1.txt should be indexed");
            Assert.IsTrue(snapshot.ContainsKey("sub/file2.txt"), "sub/file2.txt should be indexed with normalized slashes");
            Assert.IsTrue(snapshot.ContainsKey("sub"), "sub directory should be indexed");
            Assert.IsFalse(snapshot.ContainsKey(".ds_store"), ".ds_store must not be indexed");
            Assert.IsFalse(snapshot.ContainsKey("desktop.ini"), "desktop.ini must not be indexed");
            Assert.AreEqual(11, snapshot["file1.txt"].Size, "file1 size should match");
        }
        finally
        {
            if (Directory.Exists(tempDir))
            {
                Directory.Delete(tempDir, true);
            }
        }
    }

    private static void TestFolderDiffCalculation()
    {
        var tempDir = Path.Combine(Path.GetTempPath(), "overnode_sync_diff_" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(tempDir);

        try
        {
            var f1 = Path.Combine(tempDir, "unchanged.txt");
            var f2 = Path.Combine(tempDir, "modified.txt");
            File.WriteAllText(f1, "same");
            File.WriteAllText(f2, "original");

            // Base snapshot
            var baseSnapshot = FolderSyncScanner.Scan(tempDir);

            // Now perform changes:
            // 1. modify f2
            System.Threading.Thread.Sleep(50); // Ensure timestamp differs
            File.WriteAllText(f2, "updated content with more bytes");

            // 2. add f3
            var f3 = Path.Combine(tempDir, "newfile.txt");
            File.WriteAllText(f3, "brand new");

            // 3. create a new directory
            var newSub = Path.Combine(tempDir, "newdir");
            Directory.CreateDirectory(newSub);
            var f4 = Path.Combine(newSub, "nested.txt");
            File.WriteAllText(f4, "nested");

            var currentSnapshot = FolderSyncScanner.Scan(tempDir);
            var diff = FolderSyncScanner.Diff(baseSnapshot, currentSnapshot);

            Assert.IsTrue(diff.HasChanges, "Diff should report changes");
            Assert.AreEqual(3, diff.AddedOrModifiedFiles.Count, "Should detect 3 added or modified files (modified.txt, newfile.txt, and newdir/nested.txt)");
            Assert.AreEqual(0, diff.DeletedPaths.Count, "Should detect 0 removed files");
            Assert.IsTrue(diff.AddedDirectories.Contains("newdir"), "Should detect new directory newdir");
        }
        finally
        {
            if (Directory.Exists(tempDir))
            {
                Directory.Delete(tempDir, true);
            }
        }
    }

    private static async Task TestFolderSyncManagerRegistration()
    {
        var tempDir = Path.Combine(Path.GetTempPath(), "overnode_sync_mgr_" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(tempDir);

        try
        {
            var manager = FolderSyncManager.Shared;
            var serverId = "test_server_" + Guid.NewGuid().ToString("N")[..8];
            var remoteDir = "/plugins";

            Assert.IsFalse(manager.IsFolderSynced(serverId, remoteDir), "Initially should not be synced");

            var config = await manager.RegisterSyncedFolderAsync(serverId, remoteDir, tempDir, initialPull: false);
            Assert.IsNotNull(config, "Registered config should not be null");
            Assert.IsTrue(manager.IsFolderSynced(serverId, remoteDir), "Folder should now be reported as synced");

            var retrieved = manager.GetConfigFor(serverId, remoteDir);
            Assert.IsNotNull(retrieved, "Should be able to retrieve config");
            Assert.AreEqual(Path.GetFullPath(tempDir), retrieved!.LocalPath, "Local path should match");

            // Stop sync
            manager.StopSync(config.Id);
            Assert.IsFalse(manager.IsFolderSynced(serverId, remoteDir), "After stop, should not be synced");
        }
        finally
        {
            if (Directory.Exists(tempDir))
            {
                Directory.Delete(tempDir, true);
            }
        }
    }
}
