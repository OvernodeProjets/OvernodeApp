using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Text.Json.Serialization;
using Overnode.App.Localization;

namespace Overnode.App.Models;

public enum SidebarPosition
{
    [JsonPropertyName("left")]
    Left,

    [JsonPropertyName("right")]
    Right
}

public static class SidebarPositionExtensions
{
    public static string GetLocalizedDisplayName(this SidebarPosition position, LocalizationManager loc)
    {
        return position switch
        {
            SidebarPosition.Left => loc.GetString("godpack_sidebar_left", "Gauche (Défaut)"),
            SidebarPosition.Right => loc.GetString("godpack_sidebar_right", "Droite (Inversée)"),
            _ => position.ToString()
        };
    }
}

public class ThemeColorsConfig : IEquatable<ThemeColorsConfig>
{
    [JsonPropertyName("backgroundHex")]
    public string BackgroundHex { get; set; } = "#101218";

    [JsonPropertyName("cardBackgroundHex")]
    public string CardBackgroundHex { get; set; } = "#181B22";

    [JsonPropertyName("secondaryCardBackgroundHex")]
    public string SecondaryCardBackgroundHex { get; set; } = "#202229";

    [JsonPropertyName("borderHex")]
    public string BorderHex { get; set; } = "#2E3337";

    [JsonPropertyName("borderSubtleOpacity")]
    public double BorderSubtleOpacity { get; set; } = 0.08;

    [JsonPropertyName("textPrimaryHex")]
    public string TextPrimaryHex { get; set; } = "#FFFFFF";

    [JsonPropertyName("textSecondaryHex")]
    public string TextSecondaryHex { get; set; } = "#95A1AD";

    [JsonPropertyName("textMutedHex")]
    public string TextMutedHex { get; set; } = "#66707D";

    [JsonPropertyName("accentGoldHex")]
    public string AccentGoldHex { get; set; } = "#F59E0B";

    [JsonPropertyName("accentCyanHex")]
    public string AccentCyanHex { get; set; } = "#06B6D4";

    [JsonPropertyName("accentBlueHex")]
    public string AccentBlueHex { get; set; } = "#598CF2";

    [JsonPropertyName("accentDangerHex")]
    public string AccentDangerHex { get; set; } = "#EF4444";

    [JsonPropertyName("accentWarningHex")]
    public string AccentWarningHex { get; set; } = "#F59E0B";

    [JsonPropertyName("accentSuccessHex")]
    public string AccentSuccessHex { get; set; } = "#22C55E";

    [JsonPropertyName("accentDiscordHex")]
    public string AccentDiscordHex { get; set; } = "#5865F2";

    public ThemeColorsConfig() { }

    public ThemeColorsConfig Clone()
    {
        return new ThemeColorsConfig
        {
            BackgroundHex = BackgroundHex,
            CardBackgroundHex = CardBackgroundHex,
            SecondaryCardBackgroundHex = SecondaryCardBackgroundHex,
            BorderHex = BorderHex,
            BorderSubtleOpacity = BorderSubtleOpacity,
            TextPrimaryHex = TextPrimaryHex,
            TextSecondaryHex = TextSecondaryHex,
            TextMutedHex = TextMutedHex,
            AccentGoldHex = AccentGoldHex,
            AccentCyanHex = AccentCyanHex,
            AccentBlueHex = AccentBlueHex,
            AccentDangerHex = AccentDangerHex,
            AccentWarningHex = AccentWarningHex,
            AccentSuccessHex = AccentSuccessHex,
            AccentDiscordHex = AccentDiscordHex
        };
    }

    public bool Equals(ThemeColorsConfig? other)
    {
        if (other is null) return false;
        return string.Equals(BackgroundHex, other.BackgroundHex, StringComparison.OrdinalIgnoreCase) &&
               string.Equals(CardBackgroundHex, other.CardBackgroundHex, StringComparison.OrdinalIgnoreCase) &&
               string.Equals(SecondaryCardBackgroundHex, other.SecondaryCardBackgroundHex, StringComparison.OrdinalIgnoreCase) &&
               string.Equals(BorderHex, other.BorderHex, StringComparison.OrdinalIgnoreCase) &&
               Math.Abs(BorderSubtleOpacity - other.BorderSubtleOpacity) < 0.001 &&
               string.Equals(TextPrimaryHex, other.TextPrimaryHex, StringComparison.OrdinalIgnoreCase) &&
               string.Equals(TextSecondaryHex, other.TextSecondaryHex, StringComparison.OrdinalIgnoreCase) &&
               string.Equals(TextMutedHex, other.TextMutedHex, StringComparison.OrdinalIgnoreCase) &&
               string.Equals(AccentGoldHex, other.AccentGoldHex, StringComparison.OrdinalIgnoreCase) &&
               string.Equals(AccentCyanHex, other.AccentCyanHex, StringComparison.OrdinalIgnoreCase) &&
               string.Equals(AccentBlueHex, other.AccentBlueHex, StringComparison.OrdinalIgnoreCase) &&
               string.Equals(AccentDangerHex, other.AccentDangerHex, StringComparison.OrdinalIgnoreCase) &&
               string.Equals(AccentWarningHex, other.AccentWarningHex, StringComparison.OrdinalIgnoreCase) &&
               string.Equals(AccentSuccessHex, other.AccentSuccessHex, StringComparison.OrdinalIgnoreCase) &&
               string.Equals(AccentDiscordHex, other.AccentDiscordHex, StringComparison.OrdinalIgnoreCase);
    }

    public override bool Equals(object? obj) => Equals(obj as ThemeColorsConfig);

    public override int GetHashCode() => HashCode.Combine(BackgroundHex, CardBackgroundHex, AccentGoldHex);
}

public class AppThemeConfig : IEquatable<AppThemeConfig>
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = "custom";

    [JsonPropertyName("name")]
    public string Name { get; set; } = "Mon Thème Overnode";

    [JsonPropertyName("description")]
    public string? Description { get; set; }

    [JsonPropertyName("author")]
    public string Author { get; set; } = "Overnode User";

    [JsonPropertyName("version")]
    public string Version { get; set; } = "1.0.0";

    [JsonPropertyName("colors")]
    public ThemeColorsConfig Colors { get; set; } = new();

    [JsonPropertyName("backgroundImageUrl")]
    public string? BackgroundImageUrl { get; set; }

    [JsonPropertyName("backgroundLocalPath")]
    public string? BackgroundLocalPath { get; set; }

    [JsonPropertyName("backgroundOpacity")]
    public double BackgroundOpacity { get; set; } = 0.25;

    [JsonPropertyName("backgroundBlur")]
    public double BackgroundBlur { get; set; } = 0.0;

    [JsonPropertyName("backgroundOverlayDarkness")]
    public double BackgroundOverlayDarkness { get; set; } = 0.65;

    [JsonPropertyName("landingTab")]
    public string LandingTab { get; set; } = "dashboard";

    [JsonPropertyName("sidebarPosition")]
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public SidebarPosition SidebarPosition { get; set; } = SidebarPosition.Left;

    [JsonPropertyName("cardCornerRadius")]
    public double CardCornerRadius { get; set; } = 10.0;

    public AppThemeConfig() { }

    public string ToJson()
    {
        return JsonSerializer.Serialize(this, new JsonSerializerOptions { WriteIndented = true });
    }

    public static AppThemeConfig? FromJson(string json)
    {
        return JsonSerializer.Deserialize<AppThemeConfig>(json);
    }

    public AppThemeConfig Clone()
    {
        return new AppThemeConfig
        {
            Id = Id,
            Name = Name,
            Description = Description,
            Author = Author,
            Version = Version,
            Colors = Colors.Clone(),
            BackgroundImageUrl = BackgroundImageUrl,
            BackgroundLocalPath = BackgroundLocalPath,
            BackgroundOpacity = BackgroundOpacity,
            BackgroundBlur = BackgroundBlur,
            BackgroundOverlayDarkness = BackgroundOverlayDarkness,
            LandingTab = LandingTab,
            SidebarPosition = SidebarPosition,
            CardCornerRadius = CardCornerRadius
        };
    }

    public bool Equals(AppThemeConfig? other)
    {
        if (other is null) return false;
        return string.Equals(Id, other.Id, StringComparison.Ordinal) &&
               string.Equals(Name, other.Name, StringComparison.Ordinal) &&
               Colors.Equals(other.Colors) &&
               string.Equals(BackgroundImageUrl, other.BackgroundImageUrl, StringComparison.Ordinal) &&
               string.Equals(BackgroundLocalPath, other.BackgroundLocalPath, StringComparison.Ordinal) &&
               Math.Abs(BackgroundOpacity - other.BackgroundOpacity) < 0.001 &&
               Math.Abs(BackgroundBlur - other.BackgroundBlur) < 0.001 &&
               Math.Abs(BackgroundOverlayDarkness - other.BackgroundOverlayDarkness) < 0.001 &&
               string.Equals(LandingTab, other.LandingTab, StringComparison.Ordinal) &&
               SidebarPosition == other.SidebarPosition &&
               Math.Abs(CardCornerRadius - other.CardCornerRadius) < 0.001;
    }

    public override bool Equals(object? obj) => Equals(obj as AppThemeConfig);

    public override int GetHashCode() => HashCode.Combine(Id, Name, Colors);
}

public static class PresetThemes
{
    public static AppThemeConfig OvernodeOriginal => new()
    {
        Id = "overnode_original",
        Name = "Overnode Original",
        Author = "Overnode Official",
        Version = "1.0",
        Colors = new ThemeColorsConfig
        {
            BackgroundHex = "#101218",
            CardBackgroundHex = "#181B22",
            SecondaryCardBackgroundHex = "#202229",
            BorderHex = "#2E3337",
            BorderSubtleOpacity = 0.08,
            TextPrimaryHex = "#FFFFFF",
            TextSecondaryHex = "#95A1AD",
            TextMutedHex = "#66707D",
            AccentGoldHex = "#F59E0B",
            AccentCyanHex = "#06B6D4"
        },
        LandingTab = "dashboard",
        SidebarPosition = SidebarPosition.Left,
        CardCornerRadius = 10.0
    };

    public static AppThemeConfig CyberpunkNeon => new()
    {
        Id = "cyberpunk_neon",
        Name = "Cyberpunk Neon",
        Author = "Overnode Community",
        Version = "1.0",
        Colors = new ThemeColorsConfig
        {
            BackgroundHex = "#0D0F18",
            CardBackgroundHex = "#141724",
            SecondaryCardBackgroundHex = "#1B2032",
            BorderHex = "#2A3250",
            BorderSubtleOpacity = 0.15,
            TextPrimaryHex = "#FFFFFF",
            TextSecondaryHex = "#9AA6BF",
            TextMutedHex = "#5E6C87",
            AccentGoldHex = "#00F5D4",
            AccentCyanHex = "#BD00FF"
        },
        LandingTab = "dashboard",
        SidebarPosition = SidebarPosition.Left,
        CardCornerRadius = 12.0
    };

    public static AppThemeConfig MidnightOLED => new()
    {
        Id = "midnight_oled",
        Name = "Midnight OLED",
        Author = "Overnode Official",
        Version = "1.0",
        Colors = new ThemeColorsConfig
        {
            BackgroundHex = "#000000",
            CardBackgroundHex = "#0C0D11",
            SecondaryCardBackgroundHex = "#14161D",
            BorderHex = "#20242D",
            BorderSubtleOpacity = 0.10,
            TextPrimaryHex = "#F8FAFC",
            TextSecondaryHex = "#94A3B8",
            TextMutedHex = "#475569",
            AccentGoldHex = "#E5B842",
            AccentCyanHex = "#38BDF8"
        },
        LandingTab = "dashboard",
        SidebarPosition = SidebarPosition.Left,
        CardCornerRadius = 8.0
    };

    public static AppThemeConfig EmeraldMatrix => new()
    {
        Id = "emerald_matrix",
        Name = "Emerald Matrix",
        Author = "Overnode Community",
        Version = "1.0",
        Colors = new ThemeColorsConfig
        {
            BackgroundHex = "#06120D",
            CardBackgroundHex = "#0C1E17",
            SecondaryCardBackgroundHex = "#132B21",
            BorderHex = "#1D4032",
            BorderSubtleOpacity = 0.12,
            TextPrimaryHex = "#E6F4EA",
            TextSecondaryHex = "#8CB89F",
            TextMutedHex = "#4E735E",
            AccentGoldHex = "#00FF88",
            AccentCyanHex = "#00E5FF"
        },
        LandingTab = "dashboard",
        SidebarPosition = SidebarPosition.Left,
        CardCornerRadius = 10.0
    };

    public static AppThemeConfig CrimsonVelvet => new()
    {
        Id = "crimson_velvet",
        Name = "Crimson Velvet",
        Author = "Overnode Community",
        Version = "1.0",
        Colors = new ThemeColorsConfig
        {
            BackgroundHex = "#140508",
            CardBackgroundHex = "#1E0C11",
            SecondaryCardBackgroundHex = "#2B1219",
            BorderHex = "#3E1C24",
            BorderSubtleOpacity = 0.14,
            TextPrimaryHex = "#FFE4E9",
            TextSecondaryHex = "#C98B99",
            TextMutedHex = "#7A4955",
            AccentGoldHex = "#FF3366",
            AccentCyanHex = "#FF7597"
        },
        LandingTab = "dashboard",
        SidebarPosition = SidebarPosition.Left,
        CardCornerRadius = 10.0
    };

    public static AppThemeConfig SapphireAbyss => new()
    {
        Id = "sapphire_abyss",
        Name = "Sapphire Abyss",
        Author = "Overnode Official",
        Version = "1.0",
        Colors = new ThemeColorsConfig
        {
            BackgroundHex = "#080E1E",
            CardBackgroundHex = "#0E172E",
            SecondaryCardBackgroundHex = "#142040",
            BorderHex = "#1F315D",
            BorderSubtleOpacity = 0.12,
            TextPrimaryHex = "#E2F1FF",
            TextSecondaryHex = "#88A8D8",
            TextMutedHex = "#4A6694",
            AccentGoldHex = "#00D2FF",
            AccentCyanHex = "#3A86FF"
        },
        LandingTab = "dashboard",
        SidebarPosition = SidebarPosition.Left,
        CardCornerRadius = 10.0
    };

    public static AppThemeConfig NordFrost => new()
    {
        Id = "nord_frost",
        Name = "Nord Frost",
        Author = "Overnode Community",
        Version = "1.0",
        Colors = new ThemeColorsConfig
        {
            BackgroundHex = "#242933",
            CardBackgroundHex = "#2E3440",
            SecondaryCardBackgroundHex = "#3B4252",
            BorderHex = "#4C566A",
            BorderSubtleOpacity = 0.12,
            TextPrimaryHex = "#ECEFF4",
            TextSecondaryHex = "#D8DEE9",
            TextMutedHex = "#7B88A1",
            AccentGoldHex = "#88C0D0",
            AccentCyanHex = "#81A1C1"
        },
        LandingTab = "dashboard",
        SidebarPosition = SidebarPosition.Left,
        CardCornerRadius = 10.0
    };

    public static AppThemeConfig AmethystDream => new()
    {
        Id = "amethyst_dream",
        Name = "Amethyst Dream",
        Author = "Overnode Community",
        Version = "1.0",
        Colors = new ThemeColorsConfig
        {
            BackgroundHex = "#11081A",
            CardBackgroundHex = "#1B0E2B",
            SecondaryCardBackgroundHex = "#281540",
            BorderHex = "#3B205D",
            BorderSubtleOpacity = 0.14,
            TextPrimaryHex = "#F5E8FF",
            TextSecondaryHex = "#B896D9",
            TextMutedHex = "#6F528A",
            AccentGoldHex = "#F72585",
            AccentCyanHex = "#7209B7"
        },
        LandingTab = "dashboard",
        SidebarPosition = SidebarPosition.Left,
        CardCornerRadius = 12.0
    };

    public static AppThemeConfig SunsetHorizon => new()
    {
        Id = "sunset_horizon",
        Name = "Sunset Horizon",
        Author = "Overnode Community",
        Version = "1.0",
        Colors = new ThemeColorsConfig
        {
            BackgroundHex = "#170D0E",
            CardBackgroundHex = "#241517",
            SecondaryCardBackgroundHex = "#331E20",
            BorderHex = "#4A2B2E",
            BorderSubtleOpacity = 0.12,
            TextPrimaryHex = "#FFF0EB",
            TextSecondaryHex = "#D49E94",
            TextMutedHex = "#805851",
            AccentGoldHex = "#FF7B00",
            AccentCyanHex = "#FFB703"
        },
        LandingTab = "dashboard",
        SidebarPosition = SidebarPosition.Left,
        CardCornerRadius = 10.0
    };

    public static IReadOnlyList<AppThemeConfig> All { get; } = new[]
    {
        OvernodeOriginal,
        CyberpunkNeon,
        MidnightOLED,
        EmeraldMatrix,
        CrimsonVelvet,
        SapphireAbyss,
        NordFrost,
        AmethystDream,
        SunsetHorizon
    };
}

public class BundleStatusResponse
{
    [JsonPropertyName("hasGodPack")]
    public bool? HasGodPack { get; set; }

    [JsonPropertyName("activeBundles")]
    public List<string>? ActiveBundles { get; set; }

    [JsonPropertyName("hasAutoRenew")]
    public bool? HasAutoRenew { get; set; }

    [JsonPropertyName("hasUpgradedPack")]
    public bool? HasUpgradedPack { get; set; }

    public bool HasGodPackActive => HasGodPack == true || (ActiveBundles != null && ActiveBundles.Contains("bundle_god_f4"));
}

public class UpdaterGodPackCheckResponse
{
    [JsonPropertyName("discordId")]
    public string? DiscordId { get; set; }

    [JsonPropertyName("hasGodPack")]
    public bool HasGodPack { get; set; }
}
