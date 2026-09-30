using System;
using System.Collections.Generic;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.Services;

namespace Overnode.Tests;

public class MockTrayTarget : ITrayTarget
{
    public bool RestoreCalled { get; private set; }
    public bool SettingsCalled { get; private set; }
    public bool QuitCalled { get; private set; }
    public int EnqueuedActionsCount { get; private set; }

    public IntPtr GetWindowHandle() => IntPtr.Zero;

    public void RestoreWindow()
    {
        RestoreCalled = true;
    }

    public void NavigateToSettings()
    {
        SettingsCalled = true;
    }

    public void QuitApplication()
    {
        QuitCalled = true;
    }

    public void EnqueueOnUIThread(Action action)
    {
        EnqueuedActionsCount++;
        action();
    }
}

public class TrayQuickActionTests
{
    public void Test_QuickActionServerStorage_Basic()
    {
        var storage = QuickActionServerStorage.Shared;
        storage.SetSelectedServerIdentifier(null);
        Assert.IsNull(storage.GetSelectedServerIdentifier());

        storage.SetSelectedServerIdentifier("srv-12345");
        Assert.AreEqual("srv-12345", storage.GetSelectedServerIdentifier());

        storage.SetSelectedServerIdentifier("  srv-67890  ");
        Assert.AreEqual("srv-67890", storage.GetSelectedServerIdentifier());

        storage.SetSelectedServerIdentifier(null);
        Assert.IsNull(storage.GetSelectedServerIdentifier());
    }

    public void Test_QuickActionServerStorage_Notification()
    {
        var storage = QuickActionServerStorage.Shared;
        bool fired = false;
        EventHandler handler = (s, e) => { fired = true; };

        storage.DidChange += handler;
        try
        {
            storage.SetSelectedServerIdentifier("notif-test");
            Assert.IsTrue(fired);
        }
        finally
        {
            storage.DidChange -= handler;
            storage.SetSelectedServerIdentifier(null);
        }
    }

    public void Test_TrayIconManager_UpdateServersAndActiveServer()
    {
        var manager = TrayIconManager.Shared;
        var testServers = new List<ServerInstance>
        {
            new()
            {
                Id = 1,
                Identifier = "srv-alpha",
                Name = "VPS Production",
                State = "running",
                MemoryUsedMB = 1024,
                MemoryLimitMB = 4096,
                CpuUsedPercent = 25.5
            },
            new()
            {
                Id = 2,
                Identifier = "srv-beta",
                Name = "Backup Server",
                State = "offline",
                MemoryUsedMB = 0,
                MemoryLimitMB = 2048,
                CpuUsedPercent = 0.0
            }
        };

        QuickActionServerStorage.Shared.SetSelectedServerIdentifier(null);
        manager.UpdateServers(testServers);
        Assert.IsNull(manager.ActiveServer);

        QuickActionServerStorage.Shared.SetSelectedServerIdentifier("srv-alpha");
        Assert.IsNotNull(manager.ActiveServer);
        Assert.AreEqual("srv-alpha", manager.ActiveServer.Identifier);
        Assert.AreEqual("VPS Production", manager.ActiveServer.Name);

        QuickActionServerStorage.Shared.SetSelectedServerIdentifier("srv-beta");
        Assert.IsNotNull(manager.ActiveServer);
        Assert.AreEqual("srv-beta", manager.ActiveServer.Identifier);

        QuickActionServerStorage.Shared.SetSelectedServerIdentifier(null);
        Assert.IsNull(manager.ActiveServer);
    }

    public void Test_TrayIconManager_TooltipFormatting()
    {
        var manager = TrayIconManager.Shared;
        QuickActionServerStorage.Shared.SetSelectedServerIdentifier(null);
        manager.RefreshSelectedServer();

        string fallbackTip = manager.BuildTooltipText();
        Assert.AreEqual("Overnode - Quick Actions", fallbackTip);

        var testServers = new List<ServerInstance>
        {
            new()
            {
                Id = 10,
                Identifier = "srv-live",
                Name = "Node Hub",
                State = "running"
            }
        };
        manager.UpdateServers(testServers);
        QuickActionServerStorage.Shared.SetSelectedServerIdentifier("srv-live");

        string liveTip = manager.BuildTooltipText();
        Assert.IsTrue(liveTip.Contains("Node Hub"));
        Assert.IsTrue(liveTip.Contains("Overnode -"));

        QuickActionServerStorage.Shared.SetSelectedServerIdentifier(null);
    }

    public void Test_TrayIconManager_LocalizedServerStates()
    {
        var manager = TrayIconManager.Shared;
        var loc = LocalizationManager.Instance;

        loc.SetLanguage(AppLanguage.Fr);
        Assert.AreEqual("En ligne", manager.LocalizedServerState("running"));
        Assert.AreEqual("Démarrage...", manager.LocalizedServerState("starting"));
        Assert.AreEqual("Arrêt...", manager.LocalizedServerState("stopping"));
        Assert.AreEqual("Suspendu", manager.LocalizedServerState("suspended"));
        Assert.AreEqual("Hors ligne", manager.LocalizedServerState("offline"));

        loc.SetLanguage(AppLanguage.En);
        Assert.AreEqual("Running", manager.LocalizedServerState("running"));
        Assert.AreEqual("Starting...", manager.LocalizedServerState("starting"));
        Assert.AreEqual("Stopping...", manager.LocalizedServerState("stopping"));
        Assert.AreEqual("Suspended", manager.LocalizedServerState("suspended"));
        Assert.AreEqual("Offline", manager.LocalizedServerState("offline"));
    }

    public void Test_TrayIconManager_MenuCommandExecution()
    {
        var manager = TrayIconManager.Shared;
        var mockTarget = new MockTrayTarget();
        manager.Initialize(mockTarget);

        manager.HandleMenuCommand(TrayIconManager.CMD_SETTINGS);
        Assert.IsTrue(mockTarget.SettingsCalled);

        manager.HandleMenuCommand(TrayIconManager.CMD_OPEN);
        Assert.IsTrue(mockTarget.RestoreCalled);

        manager.HandleMenuCommand(TrayIconManager.CMD_QUIT);
        Assert.IsTrue(mockTarget.QuitCalled);
    }

    public void Test_QuickActionTranslationsExist_FrenchAndEnglish()
    {
        var loc = LocalizationManager.Instance;

        string[] requiredKeys = new[]
        {
            "settings_quickaction_title",
            "settings_quickaction_desc",
            "settings_quickaction_select_label",
            "settings_quickaction_none",
            "settings_quickaction_status_label",
            "menubar_quickactions_title",
            "menubar_no_server_configured",
            "menubar_open_settings",
            "menubar_server_offline",
            "menubar_server_running",
            "menubar_server_starting",
            "menubar_server_stopping",
            "menubar_server_suspended",
            "menubar_action_start",
            "menubar_action_stop",
            "menubar_action_restart",
            "menubar_action_kill",
            "menubar_action_kill_confirm",
            "menubar_open_app",
            "menubar_quit"
        };

        loc.SetLanguage(AppLanguage.Fr);
        foreach (var key in requiredKeys)
        {
            string val = loc.GetString(key);
            Assert.IsFalse(string.IsNullOrWhiteSpace(val), $"Missing FR key: {key}");
        }

        loc.SetLanguage(AppLanguage.En);
        foreach (var key in requiredKeys)
        {
            string val = loc.GetString(key);
            Assert.IsFalse(string.IsNullOrWhiteSpace(val), $"Missing EN key: {key}");
        }
    }
}
