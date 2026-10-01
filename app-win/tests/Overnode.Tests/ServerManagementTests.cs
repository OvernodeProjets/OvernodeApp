using System;
using System.Text.Json;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.Services;
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
        var loc = LocalizationManager.Instance;
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

        var subuserLimited = new ServerSubuser
        {
            Email = "helper@overnode.fr",
            Permissions = new() { "control.start", "control.stop" }
        };

        loc.SetLanguage(AppLanguage.Fr);
        Assert.AreEqual("Toutes permissions (Admin)", subuserAdmin.PermissionsSummary);
        Assert.AreEqual("2 permission(s)", subuserLimited.PermissionsSummary);
        Assert.AreEqual("Actif", subdomain.StatusText);
        Assert.AreEqual("2FA activé", subuserAdmin.TwoFactorStatusText);

        loc.SetLanguage(AppLanguage.En);
        Assert.AreEqual("All permissions (Admin)", subuserAdmin.PermissionsSummary);
        Assert.AreEqual("2 permission(s)", subuserLimited.PermissionsSummary);
        Assert.AreEqual("Active", subdomain.StatusText);
        Assert.AreEqual("2FA enabled", subuserAdmin.TwoFactorStatusText);

        loc.SetLanguage(AppLanguage.Fr);
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

    public void Test_FlexibleRenewalStringConverter_ObjectPayload()
    {
        string jsonWithObject = """
        {
            "canRenew": false,
            "timeRemaining": {
                "totalMs": 128919630,
                "totalSeconds": 128919,
                "days": 1,
                "hours": 11,
                "minutes": 48,
                "seconds": 39
            },
            "availableIn": {
                "totalMs": 42519630,
                "totalSeconds": 42519,
                "days": 0,
                "hours": 11,
                "minutes": 48,
                "seconds": 39
            },
            "nextRenewalAt": "2026-10-01T10:30:00.000Z",
            "costCoins": 0
        }
        """;

        var status = JsonSerializer.Deserialize<ServerRenewalStatus>(jsonWithObject);
        Assert.IsNotNull(status);
        Assert.AreEqual(false, status.CanRenew);
        Assert.IsNotNull(status.TimeRemaining);
        Assert.AreEqual("1j 11h", status.TimeRemaining);
        Assert.AreEqual("11h 48min", status.AvailableIn);
        Assert.AreEqual("1j 11h", status.CalculatedTimeRemaining);
        Assert.AreEqual("11h 48min", status.CalculatedAvailableIn);
    }

    public void Test_FlexibleRenewalStringConverter_StringAndNumberPayload()
    {
        string jsonWithString = """
        {
            "canRenew": true,
            "timeRemaining": "3j 5h",
            "availableIn": "0m",
            "costCoins": 15
        }
        """;

        var statusString = JsonSerializer.Deserialize<ServerRenewalStatus>(jsonWithString);
        Assert.IsNotNull(statusString);
        Assert.AreEqual(true, statusString.CanRenew);
        Assert.AreEqual("3j 5h", statusString.TimeRemaining);
        Assert.AreEqual("0m", statusString.AvailableIn);

        string jsonWithNumber = """
        {
            "canRenew": false,
            "timeRemaining": 86400,
            "availableIn": 3660,
            "costCoins": 20
        }
        """;

        var statusNumber = JsonSerializer.Deserialize<ServerRenewalStatus>(jsonWithNumber);
        Assert.IsNotNull(statusNumber);
        Assert.AreEqual("1j 0h", statusNumber.TimeRemaining);
        Assert.AreEqual("1h 1min", statusNumber.AvailableIn);
    }

    public void Test_ServerRenewalActionResponse_ErrorPayload()
    {
        string errorJson = """
        {
            "error": "Le renouvellement n'est pas encore disponible.",
            "availableIn": {
                "totalMs": 42519630,
                "totalSeconds": 42519,
                "days": 0,
                "hours": 11,
                "minutes": 48,
                "seconds": 39
            },
            "renewalData": {
                "canRenew": false,
                "costCoins": 0
            }
        }
        """;

        var response = JsonSerializer.Deserialize<ServerRenewalActionResponse>(errorJson);
        Assert.IsNotNull(response);
        Assert.AreEqual("Le renouvellement n'est pas encore disponible.", response.Error);
        Assert.AreEqual("11h 48min", response.AvailableIn);
        Assert.IsNotNull(response.RenewalData);
        Assert.AreEqual(false, response.RenewalData.CanRenew);
    }

    public void Test_ServerTab_Parity_AllNineTabs()
    {
        var allTabs = Enum.GetValues<ServerTab>();
        Assert.AreEqual(9, allTabs.Length);

        // Verify each tab has valid glyph and localization key
        foreach (var tab in allTabs)
        {
            Assert.IsFalse(string.IsNullOrWhiteSpace(tab.ToGlyph()));
            Assert.IsFalse(string.IsNullOrWhiteSpace(tab.ToKey()));
        }

        Assert.AreEqual("server_tab_package", ServerTab.Package.ToKey());
        Assert.AreEqual("\uE71D", ServerTab.Package.ToGlyph());

        Assert.AreEqual("server_tab_plugins", ServerTab.Plugins.ToKey());
        Assert.AreEqual("\uE74C", ServerTab.Plugins.ToGlyph());

        Assert.AreEqual("server_tab_logs", ServerTab.Logs.ToKey());
        Assert.AreEqual("\uE9D9", ServerTab.Logs.ToGlyph());
    }

    public void Test_InstalledPluginsResponse_Deserialization()
    {
        string json = """
        {
            "plugins": [
                {
                    "id": "essentialsx",
                    "name": "EssentialsX",
                    "description": "Essential commands and features for Spigot/Paper servers.",
                    "version": "2.20.1",
                    "author": "EssentialsX Team"
                },
                {
                    "id": "vault",
                    "name": "Vault",
                    "description": "Economy and permissions abstraction layer.",
                    "version": "1.7.3",
                    "author": "Sleaker"
                }
            ]
        }
        """;

        var response = JsonSerializer.Deserialize<InstalledPluginsResponse>(json);
        Assert.IsNotNull(response);
        Assert.AreEqual(2, response.Plugins.Count);
        Assert.AreEqual("EssentialsX", response.Plugins[0].Name);
        Assert.AreEqual("2.20.1", response.Plugins[0].Version);
        Assert.AreEqual("Vault", response.Plugins[1].Name);
    }

    public void Test_ActivityLogsResponse_Deserialization()
    {
        string json = """
        {
            "data": [
                {
                    "action": "server:power.start",
                    "timestamp": "2026-09-29T20:30:00.000Z",
                    "username": "admin",
                    "ip": "127.0.0.1"
                },
                {
                    "action": "server:file.write",
                    "timestamp": "2026-09-29T20:25:00.000Z",
                    "username": "developer",
                    "ip": "127.0.0.1"
                }
            ]
        }
        """;

        var response = JsonSerializer.Deserialize<ActivityLogsResponse>(json);
        Assert.IsNotNull(response);
        Assert.AreEqual(2, response.Data.Count);
        Assert.AreEqual("server:power.start", response.Data[0].Action);
        Assert.AreEqual("admin", response.Data[0].Username);
    }

    public void Test_QuickActionServerStorage()
    {
        var existing = QuickActionServerStorage.Shared.GetSelectedServerIdentifier();
        try
        {
            QuickActionServerStorage.Shared.SetSelectedServerIdentifier("srv-test-999");
            Assert.AreEqual("srv-test-999", QuickActionServerStorage.Shared.GetSelectedServerIdentifier());

            QuickActionServerStorage.Shared.SetSelectedServerIdentifier(null);
            Assert.IsNull(QuickActionServerStorage.Shared.GetSelectedServerIdentifier());
        }
        finally
        {
            QuickActionServerStorage.Shared.SetSelectedServerIdentifier(existing);
        }
    }

    public void Test_DiscordRPCService_Initialization()
    {
        var rpc = DiscordRPCService.Shared;
        Assert.IsNotNull(rpc);
        Assert.AreEqual(false, rpc.IsConnected);
    }

    public void Test_SpigotPluginSearch_Deserialization_With_NumericId_And_Objects()
    {
        string spigotSearchJson = """
        [
            {
                "id": 2124,
                "name": "WorldEdit",
                "tag": "Fast in-game Minecraft map editor and builder.",
                "version": {
                    "id": "7.3.0"
                },
                "author": {
                    "id": 100,
                    "name": "EngineHub"
                },
                "icon": "https://www.spigotmc.org/data/resource_icons/2/2124.jpg",
                "downloads": 820000,
                "platform": "spigot"
            },
            {
                "id": 9089,
                "name": "EssentialsX",
                "tag": "The essential suite for Spigot and Paper servers.",
                "version": {
                    "id": "2.20.1"
                },
                "author": {
                    "name": "EssentialsX Team"
                },
                "icon": "https://www.spigotmc.org/data/resource_icons/9/9089.jpg",
                "downloads": 1500000,
                "platform": "spigot"
            }
        ]
        """;

        var list = JsonSerializer.Deserialize<List<ServerPluginItem>>(spigotSearchJson);
        Assert.IsNotNull(list);
        Assert.AreEqual(2, list.Count);

        var first = list[0];
        Assert.AreEqual("2124", first.Id);
        Assert.AreEqual("WorldEdit", first.Name);
        Assert.AreEqual("Fast in-game Minecraft map editor and builder.", first.Description);
        Assert.AreEqual("7.3.0", first.Version);
        Assert.AreEqual("EngineHub", first.Author);
        Assert.AreEqual("https://www.spigotmc.org/data/resource_icons/2/2124.jpg", first.IconUrl);
        Assert.AreEqual(820000, first.Downloads);
        Assert.AreEqual("spigot", first.Platform);

        var second = list[1];
        Assert.AreEqual("9089", second.Id);
        Assert.AreEqual("EssentialsX", second.Name);
        Assert.AreEqual("EssentialsX Team", second.Author);
    }

    public void Test_ServerWebSocketManager_Initialization()
    {
        var ws = ServerWebSocketManager.Shared;
        Assert.IsNotNull(ws);
        Assert.AreEqual(false, ws.IsConnected);
        Assert.AreEqual(false, ws.IsAuthenticated);
    }

    public void Test_ServerInstance_IdentifierFallback()
    {
        var server1 = new ServerInstance
        {
            Id = 15,
            Identifier = "cust1234"
        };
        Assert.AreEqual("cust1234", server1.Identifier);

        var server2 = new ServerInstance
        {
            Id = 18,
            Uuid = "83bd49b1-79d3-4809-9f79-99432650882e"
        };
        Assert.AreEqual("83bd49b1", server2.Identifier);

        var server3 = new ServerInstance
        {
            Id = 42
        };
        Assert.AreEqual("42", server3.Identifier);
    }

    public void Test_PteroServerWrapper_UuidFallback()
    {
        string json = """
        {
            "attributes": {
                "id": 99,
                "uuid": "fedcba98-1234-5678-9abc-def012345678",
                "name": "Fallback Test Server",
                "limits": {
                    "memory": 1024,
                    "cpu": 100,
                    "disk": 5120
                }
            }
        }
        """;

        var wrapper = JsonSerializer.Deserialize<PteroServerWrapper>(json);
        Assert.IsNotNull(wrapper);
        var instance = wrapper.ToServerInstance();
        Assert.AreEqual("fedcba98", instance.Identifier);
        Assert.AreEqual(99, instance.Id);
        Assert.AreEqual("Fallback Test Server", instance.Name);
    }

    public void Test_ServerPower_StateTransitions()
    {
        Environment.SetEnvironmentVariable("OVERNODE_DEMO", "1");
        var server = new ServerInstance
        {
            Id = 1,
            Identifier = "test1234",
            Name = "Test Server",
            State = "offline"
        };

        var vm = new ServerDetailViewModel(server);
        Assert.AreEqual("offline", vm.Server.State);

        vm.SendPowerSignalAsync(ServerPowerSignal.Start).GetAwaiter().GetResult();
        Assert.AreEqual("starting", vm.Server.State);

        vm.SendPowerSignalAsync(ServerPowerSignal.Stop).GetAwaiter().GetResult();
        Assert.AreEqual("stopping", vm.Server.State);
    }
}

