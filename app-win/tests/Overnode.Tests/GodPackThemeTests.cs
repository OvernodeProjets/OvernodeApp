using System;
using System.IO;
using System.Linq;
using System.Text.Json;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.Services;

namespace Overnode.Tests;

public class GodPackThemeTests
{
    public void Test_All_9_Presets_Validity()
    {
        var presets = PresetThemes.All;
        if (presets.Count != 9)
        {
            throw new Exception($"Expected 9 presets, found {presets.Count}");
        }

        string[] expectedNames = 
        {
            "Overnode Original",
            "Cyberpunk Neon",
            "Midnight OLED",
            "Emerald Matrix",
            "Crimson Velvet",
            "Sapphire Abyss",
            "Nord Frost",
            "Amethyst Dream",
            "Sunset Horizon"
        };

        foreach (var expected in expectedNames)
        {
            var p = presets.FirstOrDefault(x => x.Name == expected);
            if (p == null) throw new Exception($"Missing preset: {expected}");
            if (string.IsNullOrWhiteSpace(p.Author)) throw new Exception($"Preset '{expected}' missing author");
            if (p.Colors == null) throw new Exception($"Preset '{expected}' colors is null");

            ValidateHex(p.Colors.AccentGoldHex, $"{expected} AccentGoldHex");
            ValidateHex(p.Colors.BackgroundHex, $"{expected} BackgroundHex");
            ValidateHex(p.Colors.CardBackgroundHex, $"{expected} CardBackgroundHex");
            ValidateHex(p.Colors.SecondaryCardBackgroundHex, $"{expected} SecondaryCardBackgroundHex");
            ValidateHex(p.Colors.BorderHex, $"{expected} BorderHex");
            ValidateHex(p.Colors.TextPrimaryHex, $"{expected} TextPrimaryHex");
            ValidateHex(p.Colors.TextSecondaryHex, $"{expected} TextSecondaryHex");
            ValidateHex(p.Colors.TextMutedHex, $"{expected} TextMutedHex");
            ValidateHex(p.Colors.AccentCyanHex, $"{expected} AccentCyanHex");
            ValidateHex(p.Colors.AccentDiscordHex, $"{expected} AccentDiscordHex");
            ValidateHex(p.Colors.AccentSuccessHex, $"{expected} AccentSuccessHex");
            ValidateHex(p.Colors.AccentDangerHex, $"{expected} AccentDangerHex");
            ValidateHex(p.Colors.AccentWarningHex, $"{expected} AccentWarningHex");
        }
    }

    private static void ValidateHex(string hex, string label)
    {
        if (string.IsNullOrWhiteSpace(hex) || !hex.StartsWith("#") || (hex.Length != 7 && hex.Length != 9 && hex.Length != 4))
        {
            throw new Exception($"Invalid hex '{hex}' for {label}");
        }
    }

    public void Test_ColorHexHelper_Normalization()
    {
        if (!ColorHexHelper.IsValidHex("#E5B842")) throw new Exception("Expected #E5B842 to be valid");
        if (!ColorHexHelper.IsValidHex("#0B0D13")) throw new Exception("Expected #0B0D13 to be valid");
        if (!ColorHexHelper.IsValidHex("#FFF")) throw new Exception("Expected #FFF to be valid");
        if (ColorHexHelper.IsValidHex("invalid-hex")) throw new Exception("Expected invalid-hex to be invalid");

        string norm6 = ColorHexHelper.NormalizeHex("#e5b842");
        if (norm6 != "#E5B842") throw new Exception($"Expected #E5B842, got {norm6}");

        string norm3 = ColorHexHelper.NormalizeHex("#abc");
        if (norm3 != "#AABBCC") throw new Exception($"Expected #AABBCC, got {norm3}");
    }

    public void Test_BundleStatus_And_Updater_Deserialization()
    {
        // 1. Toledo Cloud /api/bundles/status
        string toledoJson = """
        {
            "status": "success",
            "activeBundles": ["bundle_starter", "bundle_god_f4"],
            "hasGodPack": true
        }
        """;

        var bundleStatus = JsonSerializer.Deserialize<BundleStatusResponse>(toledoJson);
        if (bundleStatus == null) throw new Exception("Failed to deserialize BundleStatusResponse");
        if (!bundleStatus.HasGodPackActive) throw new Exception("Expected HasGodPackActive to be true");
        if (bundleStatus.ActiveBundles?.Count != 2) throw new Exception("Expected 2 active bundles");

        // 2. OvernodeApp-Updater /api/v1/godpack/check/:discordId
        string updaterJson = """
        {
            "hasGodPack": true,
            "discordId": "123456789012345678",
            "tier": "god",
            "expiresAt": null
        }
        """;

        var updaterResponse = JsonSerializer.Deserialize<UpdaterGodPackCheckResponse>(updaterJson);
        if (updaterResponse == null) throw new Exception("Failed to deserialize UpdaterGodPackCheckResponse");
        if (!updaterResponse.HasGodPack) throw new Exception("Expected UpdaterGodPackCheckResponse.HasGodPack to be true");
        if (updaterResponse.DiscordId != "123456789012345678") throw new Exception("Discord ID mismatch");
    }

    public void Test_ThemeConfig_Serialization_Parity()
    {
        var config = new AppThemeConfig
        {
            Name = "Cyberpunk Test",
            Description = "Custom unit test theme",
            Author = "Agent",
            Version = "1.0",
            SidebarPosition = SidebarPosition.Right,
            LandingTab = "servers",
            CardCornerRadius = 16,
            BackgroundImageUrl = "https://example.com/bg.png",
            BackgroundOpacity = 0.45,
            BackgroundBlur = 12.0,
            BackgroundOverlayDarkness = 0.60,
            Colors = new ThemeColorsConfig
            {
                AccentGoldHex = "#FF007F",
                BackgroundHex = "#05050A",
                CardBackgroundHex = "#0E0E18"
            }
        };

        string exportedJson = config.ToJson();
        var imported = AppThemeConfig.FromJson(exportedJson);

        if (imported == null) throw new Exception("Deserialized config is null");
        if (imported.Name != "Cyberpunk Test") throw new Exception($"Name mismatch: {imported.Name}");
        if (imported.SidebarPosition != SidebarPosition.Right) throw new Exception("Sidebar position mismatch");
        if (imported.LandingTab != "servers") throw new Exception("Landing tab mismatch");
        if (imported.CardCornerRadius != 16) throw new Exception("Corner radius mismatch");
        if (imported.BackgroundImageUrl != "https://example.com/bg.png") throw new Exception("Bg URL mismatch");
        if (Math.Abs(imported.BackgroundOpacity - 0.45) > 0.001) throw new Exception("Opacity mismatch");
        if (Math.Abs(imported.BackgroundBlur - 12.0) > 0.001) throw new Exception("Blur mismatch");
        if (Math.Abs(imported.BackgroundOverlayDarkness - 0.60) > 0.001) throw new Exception("Overlay darkness mismatch");
        if (imported.Colors.AccentGoldHex != "#FF007F") throw new Exception("Accent color mismatch");
    }

    public void Test_ThemeManager_Preset_And_Reset()
    {
        var manager = ThemeManager.Shared;

        // Apply Cyberpunk Neon
        var cyberpunk = manager.Presets.First(x => x.Name == "Cyberpunk Neon");
        manager.ApplyPreset(cyberpunk);

        if (manager.CurrentConfig.Name != "Cyberpunk Neon") throw new Exception("Failed to apply Cyberpunk Neon preset");
        if (manager.CurrentConfig.Colors.AccentGoldHex != "#00F5D4") throw new Exception($"Unexpected accent: {manager.CurrentConfig.Colors.AccentGoldHex}");

        // Reset to default
        manager.ResetToDefault();
        if (manager.CurrentConfig.Name != "Overnode Original") throw new Exception("Reset failed to restore Overnode Original");
        if (manager.CurrentConfig.Colors.AccentGoldHex != "#F59E0B") throw new Exception("Reset failed to restore gold accent");
    }

    public void Test_ThemeManager_ResolvedLandingTab()
    {
        var manager = ThemeManager.Shared;

        manager.UpdateLayoutPreferences("dashboard", SidebarPosition.Left, 10);
        if (manager.ResolvedLandingTab != NavigationTab.Dashboard) throw new Exception("Expected Dashboard");

        manager.UpdateLayoutPreferences("servers", SidebarPosition.Left, 10);
        if (manager.ResolvedLandingTab != NavigationTab.Servers) throw new Exception("Expected Servers");

        manager.UpdateLayoutPreferences("wallet", SidebarPosition.Left, 10);
        if (manager.ResolvedLandingTab != NavigationTab.Wallet) throw new Exception("Expected Wallet");

        manager.UpdateLayoutPreferences("daily_reward", SidebarPosition.Left, 10);
        if (manager.ResolvedLandingTab != NavigationTab.DailyReward) throw new Exception("Expected DailyReward");

        manager.UpdateLayoutPreferences("store", SidebarPosition.Left, 10);
        if (manager.ResolvedLandingTab != NavigationTab.Store) throw new Exception("Expected Store");

        manager.UpdateLayoutPreferences("support", SidebarPosition.Left, 10);
        if (manager.ResolvedLandingTab != NavigationTab.Support) throw new Exception("Expected Support");

        manager.UpdateLayoutPreferences("afk", SidebarPosition.Left, 10);
        if (manager.ResolvedLandingTab != NavigationTab.Afk) throw new Exception("Expected Afk");

        manager.UpdateLayoutPreferences("settings", SidebarPosition.Left, 10);
        if (manager.ResolvedLandingTab != NavigationTab.Settings) throw new Exception("Expected Settings");

        // Clean up
        manager.ResetToDefault();
    }

    public void Test_ThemeManager_Persistence_RoundTrip()
    {
        var manager = ThemeManager.Shared;

        // Apply Emerald Matrix preset
        var emerald = manager.Presets.First(x => x.Name == "Emerald Matrix");
        manager.ApplyPreset(emerald);

        // Modify custom color
        manager.UpdateColors(c =>
        {
            c.AccentGoldHex = "#00FF88";
        });

        // Simulate application restart by reloading config from disk
        manager.ReloadConfig();

        if (manager.CurrentConfig.Name != "Thème Personnalisé") throw new Exception($"Expected custom theme after color tweak, got {manager.CurrentConfig.Name}");
        if (manager.CurrentConfig.Colors.AccentGoldHex != "#00FF88") throw new Exception($"Expected #00FF88 persisted, got {manager.CurrentConfig.Colors.AccentGoldHex}");

        // Also test that preset reapplied persists
        var midnight = manager.Presets.First(x => x.Name == "Midnight OLED");
        manager.ApplyPreset(midnight);
        manager.ReloadConfig();
        if (manager.CurrentConfig.Name != "Midnight OLED") throw new Exception($"Expected Midnight OLED persisted, got {manager.CurrentConfig.Name}");
        if (manager.CurrentConfig.Colors.BackgroundHex != "#000000") throw new Exception($"Expected #000000, got {manager.CurrentConfig.Colors.BackgroundHex}");

        // Clean up
        manager.ResetToDefault();
    }

    public void Test_GodPack_Localization_Parity_FR_EN()
    {
        var loc = LocalizationManager.Instance;
        loc.SetLanguage(AppLanguage.Fr);

        string[] requiredKeys =
        {
            "godpack_title",
            "godpack_badge_locked",
            "godpack_badge_active",
            "godpack_locked_title",
            "godpack_locked_desc",
            "godpack_btn_discover_store",
            "godpack_btn_check_sub",
            "godpack_tab_presets",
            "godpack_tab_colors",
            "godpack_tab_background",
            "godpack_tab_layout",
            "godpack_tab_share",
            "godpack_vip_modal_title",
            "godpack_vip_modal_subtitle",
            "godpack_vip_modal_desc",
            "godpack_vip_btn_verify",
            "bundle_god_f4"
        };

        foreach (var key in requiredKeys)
        {
            loc.SetLanguage(AppLanguage.Fr);
            string fr = loc.GetString(key);
            if (string.IsNullOrWhiteSpace(fr) || fr == key)
            {
                throw new Exception($"Missing French translation for key '{key}'");
            }
            if (fr.Contains("console.overnode.fr"))
            {
                throw new Exception($"Forbidden string 'console.overnode.fr' found in FR key '{key}'");
            }

            loc.SetLanguage(AppLanguage.En);
            string en = loc.GetString(key);
            if (string.IsNullOrWhiteSpace(en) || en == key)
            {
                throw new Exception($"Missing English translation for key '{key}'");
            }
            if (en.Contains("console.overnode.fr"))
            {
                throw new Exception($"Forbidden string 'console.overnode.fr' found in EN key '{key}'");
            }
        }

        // Verify Ctrl+D in shortcut subtitle
        string shortcutFr = loc.GetString("godpack_vip_modal_subtitle");
        if (!shortcutFr.Contains("Ctrl+D"))
        {
            throw new Exception($"Expected 'Ctrl+D' in godpack_vip_modal_subtitle, got '{shortcutFr}'");
        }
    }
}
