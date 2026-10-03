using System;
using System.Collections.Generic;
using System.IO;
using Overnode.App.Services;

namespace Overnode.Tests;

public static class FileUploadSecurityTests
{
    public static void RunAll(Action<string, Action> run)
    {
        run("FileUploadSecurity Filter Ignored Files", TestFilterIgnoredFiles);
        run("FileUploadSecurity Path Traversal Prevention", TestSecurityPathValidation);
        run("FileUploadSecurity Max File Count Limit (500)", TestFileCountLimit);
        run("FileUploadSecurity Max File Size Limit (100MB)", TestFileSizeLimit);
        run("FileUploadSecurity Disk Quota Enforcement", TestDiskQuotaCheck);
        run("FileUploadSecurity Plan Hierarchy Ordering", TestUploadPlanDirectoryOrdering);
    }

    private static void TestFilterIgnoredFiles()
    {
        var sec = FileUploadSecurity.Shared;
        Assert.IsTrue(sec.ShouldIgnore(".ds_store"), ".ds_store should be ignored");
        Assert.IsTrue(sec.ShouldIgnore("desktop.ini"), "desktop.ini should be ignored");
        Assert.IsTrue(sec.ShouldIgnore("thumbs.db"), "thumbs.db should be ignored");
        Assert.IsTrue(sec.ShouldIgnore("~$temp.docx"), "Word temp files should be ignored");
        Assert.IsTrue(sec.ShouldIgnore("cache.tmp"), ".tmp files should be ignored");
        Assert.IsTrue(sec.ShouldIgnore(".git"), ".git should be ignored");

        Assert.IsFalse(sec.ShouldIgnore("server.properties"), "server.properties must not be ignored");
        Assert.IsFalse(sec.ShouldIgnore("spigot.jar"), "spigot.jar must not be ignored");
        Assert.IsFalse(sec.ShouldIgnore("config.yml"), "config.yml must not be ignored");
    }

    private static void TestSecurityPathValidation()
    {
        var sec = FileUploadSecurity.Shared;
        var tempDir = Path.Combine(Path.GetTempPath(), "overnode_sec_test_" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(tempDir);
        try
        {
            var validFile = Path.Combine(tempDir, "valid.txt");
            File.WriteAllText(validFile, "hello");

            var plan = sec.BuildPlan(new[] { validFile });
            Assert.IsNotNull(plan, "Valid file should produce valid plan");
            Assert.AreEqual(1, plan.FilesToUpload.Count, "Should have 1 file");
            Assert.AreEqual("valid.txt", plan.FilesToUpload[0].FileName, "File name should match");

            // Path traversal attempt in validation
            bool thrown = false;
            try
            {
                sec.ValidatePathSecurity("../etc/passwd");
            }
            catch (FileUploadException ex) when (ex.Kind == FileUploadErrorKind.SecurityViolation)
            {
                thrown = true;
            }
            Assert.IsTrue(thrown, "Path traversal should throw SecurityViolation exception");
        }
        finally
        {
            if (Directory.Exists(tempDir))
            {
                Directory.Delete(tempDir, true);
            }
        }
    }

    private static void TestFileCountLimit()
    {
        var sec = FileUploadSecurity.Shared;
        var tempDir = Path.Combine(Path.GetTempPath(), "overnode_count_test_" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(tempDir);
        try
        {
            var filePaths = new List<string>();
            // Create 501 empty files
            for (int i = 0; i <= FileUploadSecurity.MaxBatchFileCount; i++)
            {
                var fp = Path.Combine(tempDir, $"file_{i}.txt");
                File.WriteAllText(fp, "a");
                filePaths.Add(fp);
            }

            bool thrown = false;
            try
            {
                sec.BuildPlan(filePaths);
            }
            catch (FileUploadException ex) when (ex.Kind == FileUploadErrorKind.TooManyFiles)
            {
                thrown = true;
            }
            Assert.IsTrue(thrown, "Over 500 files should throw TooManyFiles exception");
        }
        finally
        {
            if (Directory.Exists(tempDir))
            {
                Directory.Delete(tempDir, true);
            }
        }
    }

    private static void TestFileSizeLimit()
    {
        var sec = FileUploadSecurity.Shared;
        var tempDir = Path.Combine(Path.GetTempPath(), "overnode_size_test_" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(tempDir);
        try
        {
            var file = Path.Combine(tempDir, "huge.dat");
            using (var fs = new FileStream(file, FileMode.Create, FileAccess.Write))
            {
                // Set length virtual to exceed 100MB
                fs.SetLength(FileUploadSecurity.MaxSingleFileSize + 1024);
            }

            bool thrown = false;
            try
            {
                sec.BuildPlan(new[] { file });
            }
            catch (FileUploadException ex) when (ex.Kind == FileUploadErrorKind.SingleFileSizeExceeded)
            {
                thrown = true;
            }
            Assert.IsTrue(thrown, "File > 100MB should throw SingleFileSizeExceeded exception");
        }
        finally
        {
            if (Directory.Exists(tempDir))
            {
                Directory.Delete(tempDir, true);
            }
        }
    }

    private static void TestDiskQuotaCheck()
    {
        var sec = FileUploadSecurity.Shared;
        var tempDir = Path.Combine(Path.GetTempPath(), "overnode_quota_test_" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(tempDir);
        try
        {
            var file = Path.Combine(tempDir, "data.bin");
            File.WriteAllBytes(file, new byte[5 * 1024 * 1024]); // 5 MB

            // Quota limit 10 MB, used 9 MB -> available 1 MB
            bool thrown = false;
            try
            {
                sec.BuildPlan(new[] { file }, diskLimitMB: 10, diskUsedMB: 9);
            }
            catch (FileUploadException ex) when (ex.Kind == FileUploadErrorKind.InsufficientDiskQuota)
            {
                thrown = true;
            }
            Assert.IsTrue(thrown, "Upload exceeding available disk quota must throw InsufficientDiskQuota");

            // Quota limit 10 MB, used 2 MB -> available 8 MB
            var validPlan = sec.BuildPlan(new[] { file }, diskLimitMB: 10, diskUsedMB: 2);
            Assert.IsNotNull(validPlan, "Upload within available disk quota should succeed");
        }
        finally
        {
            if (Directory.Exists(tempDir))
            {
                Directory.Delete(tempDir, true);
            }
        }
    }

    private static void TestUploadPlanDirectoryOrdering()
    {
        var sec = FileUploadSecurity.Shared;
        var tempDir = Path.Combine(Path.GetTempPath(), "overnode_tree_test_" + Guid.NewGuid().ToString("N"));
        var subDir1 = Path.Combine(tempDir, "plugins");
        var subDir2 = Path.Combine(subDir1, "WorldEdit");
        Directory.CreateDirectory(subDir2);

        try
        {
            var f1 = Path.Combine(tempDir, "server.jar");
            var f2 = Path.Combine(subDir1, "plugin.jar");
            var f3 = Path.Combine(subDir2, "config.yml");
            File.WriteAllText(f1, "1");
            File.WriteAllText(f2, "2");
            File.WriteAllText(f3, "3");

            var plan = sec.BuildPlan(new[] { tempDir });
            Assert.IsNotNull(plan, "Directory hierarchy plan should be non-null");
            Assert.AreEqual(3, plan.FilesToUpload.Count, "Should collect all 3 files");

            // Verify directories are ordered shallowest to deepest
            Assert.IsTrue(plan.DirectoriesToCreate.Count >= 2, "Should create directories");
            for (int i = 0; i < plan.DirectoriesToCreate.Count - 1; i++)
            {
                var currentDepth = plan.DirectoriesToCreate[i].Split(new[] { '/', '\\' }, StringSplitOptions.RemoveEmptyEntries).Length;
                var nextDepth = plan.DirectoriesToCreate[i + 1].Split(new[] { '/', '\\' }, StringSplitOptions.RemoveEmptyEntries).Length;
                Assert.IsTrue(currentDepth <= nextDepth, "Parent directories must come before child directories");
            }
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
