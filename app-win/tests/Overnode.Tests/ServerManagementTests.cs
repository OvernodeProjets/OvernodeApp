using System;
using System.Text.Json;
using Overnode.App.Models;
using Overnode.App.ViewModels;

namespace Overnode.Tests;

public class ServerManagementTests
{
    public void Test_ServerPowerSignal_Extensions()
    {
        Assert.AreEqual("start", ServerPowerSignal.Start.ToSignalString());
        Assert.AreEqual("stop", ServerPowerSignal.Stop.ToSignalString());
        Assert.AreEqual("restart", ServerPowerSignal.Restart.ToSignalString());
        Assert.AreEqual("kill", ServerPowerSignal.Kill.ToSignalString());

        Assert.AreEqual("\uE768", ServerPowerSignal.Start.ToGlyph());
        Assert.AreEqual("\uE71A", ServerPowerSignal.Stop.ToGlyph());
    }

    public void Test_ServerRenewalStatus_TimeCalculation()
    {
        var statusExplicit = new ServerRenewalStatus
        {
            TimeRemaining = "14j 2h"
        };
        Assert.AreEqual("14j 2h", statusExplicit.CalculatedTimeRemaining);

        var futureDate = DateTime.UtcNow.AddDays(5).AddHours(3).ToString("o");
        var statusCalculated = new ServerRenewalStatus
        {
            NextRenewalAt = futureDate
        };
        Assert.IsTrue(statusCalculated.CalculatedTimeRemaining.Contains("5j"));

        var pastDate = DateTime.UtcNow.AddDays(-2).ToString("o");
        var statusExpired = new ServerRenewalStatus
        {
            NextRenewalAt = pastDate
        };
        Assert.AreEqual("Expiré", statusExpired.CalculatedTimeRemaining);
    }

    public void Test_ServerFileItem_Formatting()
    {
        var folder = new ServerFileItem
        {
            Name = "plugins",
            IsFile = false,
            Size = 0
        };
        Assert.AreEqual("—", folder.FormattedSize);
        Assert.AreEqual("\uE8B7", folder.IconGlyph);

        var fileBytes = new ServerFileItem
        {
            Name = "small.txt",
            IsFile = true,
            Size = 512
        };
        Assert.AreEqual("512 B", fileBytes.FormattedSize);
        Assert.AreEqual("\uE8A5", fileBytes.IconGlyph);

        var fileKB = new ServerFileItem
        {
            Name = "config.yml",
            IsFile = true,
            Size = 2048
        };
        Assert.AreEqual("2.0 KB", fileKB.FormattedSize);

        var fileMB = new ServerFileItem
        {
            Name = "server.jar",
            IsFile = true,
            Size = 45 * 1024 * 1024
        };
        Assert.AreEqual("45.0 MB", fileMB.FormattedSize);
    }

    public void Test_PteroFileList_Deserialization()
    {
        string json = """
        {
            "data": [
                {
                    "attributes": {
                        "name": "server.properties",
                        "size": 1024,
                        "is_file": true,
                        "is_editable": true
                    }
                },
                {
                    "attributes": {
                        "name": "plugins",
                        "size": 0,
                        "is_file": false
                    }
                }
            ]
        }
        """;

        var response = JsonSerializer.Deserialize<PteroFileListResponse>(json);
        Assert.IsNotNull(response);
        Assert.AreEqual(2, response.Data.Count);

        var first = response.Data[0].Attributes;
        Assert.IsNotNull(first);
        Assert.AreEqual("server.properties", first.Name);
        Assert.IsTrue(first.IsFile == true);

        var second = response.Data[1].Attributes;
        Assert.IsNotNull(second);
        Assert.AreEqual("plugins", second.Name);
        Assert.IsTrue(second.IsFile == false);
    }

    public void Test_ServerSubdomain_And_Subuser()
    {
        var subdomain = new ServerSubdomain
        {
            Subdomain = "play",
            DomainName = "overnode.fr"
        };
        Assert.AreEqual("play.overnode.fr", subdomain.Fqdn);

        var subuserAdmin = new ServerSubuser
        {
            Email = "admin@overnode.fr",
            Permissions = new() { "*" }
        };
        Assert.AreEqual("Toutes permissions (Admin)", subuserAdmin.PermissionsSummary);

        var subuserLimited = new ServerSubuser
        {
            Email = "helper@overnode.fr",
            Permissions = new() { "control.start", "control.stop" }
        };
        Assert.AreEqual("2 permission(s)", subuserLimited.PermissionsSummary);
    }

    public void Test_ServerDetailViewModel_DemoMode()
    {
        Environment.SetEnvironmentVariable("OVERNODE_DEMO", "1");
        try
        {
            var server = new ServerInstance
            {
                Id = 1,
                Identifier = "srv-test-1",
                Name = "Test Server",
                State = "running",
                MemoryLimitMB = 2048,
                CpuLimitPercent = 100,
                DiskLimitMB = 5120
            };

            var vm = new ServerDetailViewModel(server);
            Assert.AreEqual("Test Server", vm.Server.Name);
            Assert.AreEqual(ServerTab.Console, vm.SelectedTab);
            Assert.IsTrue(vm.ConsoleLines.Count >= 3);
            Assert.IsNotNull(vm.RenewalStatus);
            Assert.IsTrue(vm.Files.Count > 0);
            Assert.IsTrue(vm.Subdomains.Count > 0);
            Assert.IsTrue(vm.Subusers.Count > 0);
            Assert.IsTrue(vm.StartupVariables.Count > 0);
        }
        finally
        {
            Environment.SetEnvironmentVariable("OVERNODE_DEMO", null);
        }
    }
}
