using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using Overnode.App.Localization;
using Overnode.App.Models;

namespace Overnode.Tests;

public class LocalizationTests
{
    private string GetLocalizationFilePath(string fileName)
    {
        string baseDir = AppContext.BaseDirectory;
        string[] candidates = new[]
        {
            Path.Combine(baseDir, "Localization", fileName),
            Path.Combine(baseDir, "..", "..", "..", "..", "src", "Overnode.App", "Localization", fileName),
            Path.Combine(baseDir, "..", "..", "..", "src", "Overnode.App", "Localization", fileName),
            Path.Combine(Directory.GetCurrentDirectory(), "src", "Overnode.App", "Localization", fileName),
            Path.Combine(Directory.GetCurrentDirectory(), "..", "src", "Overnode.App", "Localization", fileName)
        };

        foreach (var c in candidates)
        {
            if (File.Exists(c)) return Path.GetFullPath(c);
        }

        throw new FileNotFoundException($"Localization file {fileName} not found.");
    }

    public void Test_FrEn_KeyParity_And_No_Duplicates()
    {
        string frPath = GetLocalizationFilePath("fr.json");
        string enPath = GetLocalizationFilePath("en.json");

        var frContent = File.ReadAllText(frPath);
        var enContent = File.ReadAllText(enPath);

        var frDict = JsonSerializer.Deserialize<Dictionary<string, string>>(frContent)!;
        var enDict = JsonSerializer.Deserialize<Dictionary<string, string>>(enContent)!;

        Assert.IsTrue(frDict.Count >= 460, $"Expected >= 460 keys in fr.json, got {frDict.Count}");
        Assert.IsTrue(enDict.Count >= 460, $"Expected >= 460 keys in en.json, got {enDict.Count}");

        var missingInEn = new List<string>();
        foreach (var key in frDict.Keys)
        {
            if (!enDict.ContainsKey(key))
            {
                missingInEn.Add(key);
            }
        }

        var missingInFr = new List<string>();
        foreach (var key in enDict.Keys)
        {
            if (!frDict.ContainsKey(key))
            {
                missingInFr.Add(key);
            }
        }

        Assert.AreEqual(0, missingInEn.Count, $"Keys in FR missing in EN: {string.Join(", ", missingInEn)}");
        Assert.AreEqual(0, missingInFr.Count, $"Keys in EN missing in FR: {string.Join(", ", missingInFr)}");
        Assert.AreEqual(frDict.Count, enDict.Count, "FR and EN dictionary key count must be strictly identical");

        // Verify no empty values
        foreach (var kvp in frDict)
        {
            Assert.IsFalse(string.IsNullOrWhiteSpace(kvp.Value), $"Empty translation in fr.json for key '{kvp.Key}'");
        }
        foreach (var kvp in enDict)
        {
            Assert.IsFalse(string.IsNullOrWhiteSpace(kvp.Value), $"Empty translation in en.json for key '{kvp.Key}'");
        }
    }

    public void Test_NoConsoleOvernodeFrInTranslations()
    {
        string frPath = GetLocalizationFilePath("fr.json");
        string enPath = GetLocalizationFilePath("en.json");

        var frDict = JsonSerializer.Deserialize<Dictionary<string, string>>(File.ReadAllText(frPath))!;
        var enDict = JsonSerializer.Deserialize<Dictionary<string, string>>(File.ReadAllText(enPath))!;

        foreach (var kvp in frDict)
        {
            Assert.IsFalse(kvp.Value.Contains("console.overnode.fr", StringComparison.OrdinalIgnoreCase),
                $"Universal Rule Violation: fr.json contains 'console.overnode.fr' for key '{kvp.Key}'");
        }

        foreach (var kvp in enDict)
        {
            Assert.IsFalse(kvp.Value.Contains("console.overnode.fr", StringComparison.OrdinalIgnoreCase),
                $"Universal Rule Violation: en.json contains 'console.overnode.fr' for key '{kvp.Key}'");
        }
    }

    public void Test_AllCriticalKeysExist()
    {
        var loc = LocalizationManager.Instance;

        string[] requiredKeys = new[]
        {
            "settings_rename_success", "generic_close", "generic_save", "generic_invite",
            "servers_loading", "settings_subtitle", "settings_language_desc", "settings_security_notice",
            "settings_editor_auto", "settings_role_member", "settings_var_updated", "settings_reinstall_initiated",
            "store_buy", "store_bundle_monthly", "store_bundle_auto_renew",
            "support_recent_tickets", "support_cat_billing", "support_cat_servers", "support_status_open", "support_status_closed",
            "daily_reward_streak_active", "daily_reward_streak_history", "daily_reward_streak_leaderboard",
            "afk_session_active",
            "console_context_copy", "console_context_select_all", "console_context_clear",
            "files_context_open", "files_context_open_external", "files_context_delete", "files_folder_placeholder",
            "files_synced_success", "files_opening_external", "files_sync_failed", "files_saved_success", "files_editor_error",
            "subdomains_status_active",
            "subusers_2fa_active", "subusers_all_permissions", "subusers_count_permissions",
            "settings_update_btn", "plugins_install_btn", "plugins_uninstall_btn",
            "logs_by_prefix", "twofactor_code_hint", "twofactor_invalid_error",
            "header_refresh_tooltip", "dashboard_gauge_memory", "dashboard_gauge_cpu", "dashboard_gauge_disk",
            "discord_rpc_details", "discord_rpc_state", "discord_rpc_site"
        };

        foreach (var key in requiredKeys)
        {
            loc.SetLanguage(AppLanguage.Fr);
            string frVal = loc.GetString(key);
            Assert.IsFalse(string.IsNullOrEmpty(frVal), $"Key '{key}' missing or empty in French");
            Assert.IsFalse(frVal == key, $"Key '{key}' was not found in fr dictionary (returned fallback key)");

            loc.SetLanguage(AppLanguage.En);
            string enVal = loc.GetString(key);
            Assert.IsFalse(string.IsNullOrEmpty(enVal), $"Key '{key}' missing or empty in English");
            Assert.IsFalse(enVal == key, $"Key '{key}' was not found in en dictionary (returned fallback key)");
        }

        loc.SetLanguage(AppLanguage.Fr);
    }

    public void Test_Formatting_And_Persistence()
    {
        var loc = LocalizationManager.Instance;

        loc.SetLanguage(AppLanguage.Fr);
        string formattedFr = loc.Format("files_synced_success", "server.properties");
        Assert.AreEqual("Fichier synchronisé : server.properties", formattedFr);

        string singleFr = loc.Format("files_upload_success_single", "server.jar");
        Assert.AreEqual("Le fichier « server.jar » a été téléversé avec succès", singleFr);

        string multiFr = loc.Format("files_upload_success_multiple", 5);
        Assert.AreEqual("5 éléments téléversés avec succès", multiFr);

        loc.SetLanguage(AppLanguage.En);
        string formattedEn = loc.Format("files_synced_success", "server.properties");
        Assert.AreEqual("File synchronized: server.properties", formattedEn);

        string singleEn = loc.Format("files_upload_success_single", "server.jar");
        Assert.AreEqual("File 'server.jar' uploaded successfully", singleEn);

        string multiEn = loc.Format("files_upload_success_multiple", 5);
        Assert.AreEqual("5 items uploaded successfully", multiEn);

        // Persistence test
        loc.SetLanguage(AppLanguage.En);
        Assert.AreEqual(AppLanguage.En, loc.CurrentLanguage);

        loc.SetLanguage(AppLanguage.Fr);
        Assert.AreEqual(AppLanguage.Fr, loc.CurrentLanguage);
    }

    public void Test_ModelLocalizedProperties()
    {
        var loc = LocalizationManager.Instance;

        var fileItem = new ServerFileItem { Name = "test.txt", IsFile = true };
        var subdomain = new ServerSubdomain { Subdomain = "play", DomainName = "overnode.fr" };
        var subuser = new ServerSubuser { Email = "user@example.com", Permissions = new List<string> { "*" } };
        var variable = new ServerStartupVariable { Name = "SERVER_PORT", ServerValue = "25565" };
        var plugin = new ServerPluginItem { Name = "WorldEdit" };
        var log = new ServerActivityLog { Action = "server:start", Username = "admin" };

        loc.SetLanguage(AppLanguage.Fr);
        Assert.AreEqual("Ouvrir / Éditer", fileItem.ContextOpenText);
        Assert.AreEqual("Actif", subdomain.StatusText);
        Assert.AreEqual("2FA activé", subuser.TwoFactorStatusText);
        Assert.AreEqual("Toutes permissions (Admin)", subuser.PermissionsSummary);
        Assert.AreEqual("Mettre à jour", variable.UpdateButtonText);
        Assert.AreEqual("Installer", plugin.InstallActionText);
        Assert.AreEqual("Désinstaller", plugin.UninstallActionText);
        Assert.AreEqual("par", log.ByPrefix);

        loc.SetLanguage(AppLanguage.En);
        Assert.AreEqual("Open / Edit", fileItem.ContextOpenText);
        Assert.AreEqual("Active", subdomain.StatusText);
        Assert.AreEqual("2FA enabled", subuser.TwoFactorStatusText);
        Assert.AreEqual("All permissions (Admin)", subuser.PermissionsSummary);
        Assert.AreEqual("Update", variable.UpdateButtonText);
        Assert.AreEqual("Install", plugin.InstallActionText);
        Assert.AreEqual("Uninstall", plugin.UninstallActionText);
        Assert.AreEqual("by", log.ByPrefix);

        loc.SetLanguage(AppLanguage.Fr);
    }
}
