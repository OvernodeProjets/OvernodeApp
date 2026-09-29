using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace Overnode.App.Models;

public enum ServerPowerSignal
{
    Start,
    Stop,
    Restart,
    Kill
}

public static class ServerPowerSignalExtensions
{
    public static string ToSignalString(this ServerPowerSignal signal) => signal switch
    {
        ServerPowerSignal.Start => "start",
        ServerPowerSignal.Stop => "stop",
        ServerPowerSignal.Restart => "restart",
        ServerPowerSignal.Kill => "kill",
        _ => "start"
    };

    public static string ToGlyph(this ServerPowerSignal signal) => signal switch
    {
        ServerPowerSignal.Start => "\uE768", // Play
        ServerPowerSignal.Stop => "\uE71A", // Stop
        ServerPowerSignal.Restart => "\uE72C", // Refresh
        ServerPowerSignal.Kill => "\uE7BA", // Warning / Bolt
        _ => "\uE768"
    };
}

public enum ServerTab
{
    Console,
    Renewal,
    Files,
    Subdomains,
    Subusers,
    Settings
}

public static class ServerTabExtensions
{
    public static string ToKey(this ServerTab tab) => tab switch
    {
        ServerTab.Console => "server_tab_console",
        ServerTab.Renewal => "server_tab_renewal",
        ServerTab.Files => "server_tab_files",
        ServerTab.Subdomains => "server_tab_subdomains",
        ServerTab.Subusers => "server_tab_subusers",
        ServerTab.Settings => "server_tab_settings",
        _ => "server_tab_console"
    };

    public static string ToGlyph(this ServerTab tab) => tab switch
    {
        ServerTab.Console => "\uE756", // CommandPrompt
        ServerTab.Renewal => "\uE787", // Calendar
        ServerTab.Files => "\uE8B7", // Folder
        ServerTab.Subdomains => "\uE839", // WebSearch / Globe
        ServerTab.Subusers => "\uE716", // People
        ServerTab.Settings => "\uE713", // Settings
        _ => "\uE756"
    };
}

public class ServerRenewalStatus
{
    [JsonPropertyName("isActive")]
    public bool? IsActive { get; set; } = true;

    [JsonPropertyName("nextRenewalAt")]
    public string? NextRenewalAt { get; set; }

    [JsonPropertyName("lastRenewedAt")]
    public string? LastRenewedAt { get; set; }

    [JsonPropertyName("canRenew")]
    public bool? CanRenew { get; set; } = true;

    [JsonPropertyName("requiresRenewal")]
    public bool? RequiresRenewal { get; set; } = false;

    [JsonPropertyName("isExpired")]
    public bool? IsExpired { get; set; } = false;

    [JsonPropertyName("timeRemaining")]
    public string? TimeRemaining { get; set; }

    [JsonPropertyName("renewalCount")]
    public int? RenewalCount { get; set; } = 0;

    [JsonPropertyName("availableIn")]
    public string? AvailableIn { get; set; }

    public string CalculatedTimeRemaining
    {
        get
        {
            if (!string.IsNullOrEmpty(TimeRemaining)) return TimeRemaining;
            if (string.IsNullOrEmpty(NextRenewalAt)) return "—";

            if (DateTime.TryParse(NextRenewalAt, out var nextAt))
            {
                var diff = nextAt - DateTime.UtcNow;
                if (diff.TotalSeconds <= 0) return "Expiré";
                if (diff.TotalDays >= 1) return $"{(int)diff.TotalDays}j {diff.Hours}h";
                if (diff.TotalHours >= 1) return $"{diff.Hours}h {diff.Minutes}min";
                if (diff.TotalMinutes >= 1) return $"{diff.Minutes} min";
                return "Moins d'une minute";
            }
            return "—";
        }
    }
}

public class ServerRenewalActionResponse
{
    [JsonPropertyName("message")]
    public string? Message { get; set; }

    [JsonPropertyName("restarted")]
    public bool? Restarted { get; set; }

    [JsonPropertyName("renewalData")]
    public ServerRenewalStatus? RenewalData { get; set; }

    [JsonPropertyName("error")]
    public string? Error { get; set; }

    [JsonPropertyName("availableIn")]
    public string? AvailableIn { get; set; }
}

public class ServerFileItem
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("mode")]
    public string? Mode { get; set; }

    [JsonPropertyName("size")]
    public long Size { get; set; } = 0;

    [JsonPropertyName("isFile")]
    public bool IsFile { get; set; } = true;

    [JsonPropertyName("isSymlink")]
    public bool IsSymlink { get; set; } = false;

    [JsonPropertyName("isEditable")]
    public bool IsEditable { get; set; } = true;

    [JsonPropertyName("mimetype")]
    public string? Mimetype { get; set; }

    [JsonPropertyName("modifiedAt")]
    public string? ModifiedAt { get; set; }

    public string FormattedSize
    {
        get
        {
            if (!IsFile) return "—";
            if (Size < 1024) return $"{Size} B";
            var kb = Size / 1024.0;
            if (kb < 1024) return string.Format(System.Globalization.CultureInfo.InvariantCulture, "{0:F1} KB", kb);
            var mb = kb / 1024.0;
            if (mb < 1024) return string.Format(System.Globalization.CultureInfo.InvariantCulture, "{0:F1} MB", mb);
            var gb = mb / 1024.0;
            return string.Format(System.Globalization.CultureInfo.InvariantCulture, "{0:F2} GB", gb);
        }
    }

    public string IconGlyph => IsFile ? "\uE8A5" : "\uE8B7"; // Document vs Folder
}

public class ServerSubdomain
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("serverId")]
    public string? ServerId { get; set; }

    [JsonPropertyName("subdomain")]
    public string Subdomain { get; set; } = string.Empty;

    [JsonPropertyName("domainName")]
    public string DomainName { get; set; } = "overnode.fr";

    [JsonPropertyName("createdAt")]
    public string? CreatedAt { get; set; }

    public string Fqdn => !string.IsNullOrEmpty(DomainName) ? $"{Subdomain}.{DomainName}" : Subdomain;
}

public class ServerSubuser
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("uuid")]
    public string? Uuid { get; set; }

    [JsonPropertyName("email")]
    public string Email { get; set; } = string.Empty;

    [JsonPropertyName("image")]
    public string? Image { get; set; }

    [JsonPropertyName("twoFactorEnabled")]
    public bool TwoFactorEnabled { get; set; } = false;

    [JsonPropertyName("permissions")]
    public List<string> Permissions { get; set; } = new();

    public string PermissionsSummary => Permissions.Contains("*")
        ? "Toutes permissions (Admin)"
        : $"{Permissions.Count} permission(s)";
}

public class ServerActivityLog
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("timestamp")]
    public string Timestamp { get; set; } = string.Empty;

    [JsonPropertyName("action")]
    public string Action { get; set; } = string.Empty;

    [JsonPropertyName("username")]
    public string? Username { get; set; }

    [JsonPropertyName("details")]
    public string? Details { get; set; }
}

public class ServerStartupVariable
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("envVariable")]
    public string EnvVariable { get; set; } = string.Empty;

    [JsonPropertyName("defaultValue")]
    public string DefaultValue { get; set; } = string.Empty;

    [JsonPropertyName("serverValue")]
    public string ServerValue { get; set; } = string.Empty;

    [JsonPropertyName("isEditable")]
    public bool IsEditable { get; set; } = true;
}

public class PteroFileListResponse
{
    public class FileDatum
    {
        public class FileAttributes
        {
            [JsonPropertyName("name")]
            public string Name { get; set; } = string.Empty;
            [JsonPropertyName("mode")]
            public string? Mode { get; set; }
            [JsonPropertyName("size")]
            public long? Size { get; set; }
            [JsonPropertyName("is_file")]
            public bool? IsFile { get; set; }
            [JsonPropertyName("is_symlink")]
            public bool? IsSymlink { get; set; }
            [JsonPropertyName("is_editable")]
            public bool? IsEditable { get; set; }
            [JsonPropertyName("mimetype")]
            public string? Mimetype { get; set; }
            [JsonPropertyName("modified_at")]
            public string? ModifiedAt { get; set; }
        }

        [JsonPropertyName("attributes")]
        public FileAttributes? Attributes { get; set; }
    }

    [JsonPropertyName("data")]
    public List<FileDatum> Data { get; set; } = new();
}

public class PteroUsersResponse
{
    public class UserDatum
    {
        public class UserAttributes
        {
            [JsonPropertyName("id")]
            public object? Id { get; set; }
            [JsonPropertyName("uuid")]
            public string? Uuid { get; set; }
            [JsonPropertyName("email")]
            public string Email { get; set; } = string.Empty;
            [JsonPropertyName("image")]
            public string? Image { get; set; }
            [JsonPropertyName("2fa_enabled")]
            public bool? TwoFactorEnabled { get; set; }
            [JsonPropertyName("permissions")]
            public List<string>? Permissions { get; set; }
        }

        [JsonPropertyName("attributes")]
        public UserAttributes? Attributes { get; set; }
    }

    [JsonPropertyName("data")]
    public List<UserDatum> Data { get; set; } = new();
}

public class PteroStartupVariablesResponse
{
    public class VarDatum
    {
        public class VarAttributes
        {
            [JsonPropertyName("name")]
            public string Name { get; set; } = string.Empty;
            [JsonPropertyName("description")]
            public string? Description { get; set; }
            [JsonPropertyName("env_variable")]
            public string EnvVariable { get; set; } = string.Empty;
            [JsonPropertyName("default_value")]
            public string? DefaultValue { get; set; }
            [JsonPropertyName("server_value")]
            public string? ServerValue { get; set; }
            [JsonPropertyName("is_editable")]
            public bool? IsEditable { get; set; }
            [JsonPropertyName("rules")]
            public string? Rules { get; set; }
        }

        [JsonPropertyName("attributes")]
        public VarAttributes? Attributes { get; set; }
    }

    [JsonPropertyName("data")]
    public List<VarDatum> Data { get; set; } = new();
}

public class ServerPluginItem
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("description")]
    public string? Description { get; set; }

    [JsonPropertyName("iconUrl")]
    public string? IconUrl { get; set; }

    [JsonPropertyName("version")]
    public string? Version { get; set; }

    [JsonPropertyName("author")]
    public string? Author { get; set; }

    [JsonPropertyName("platform")]
    public string Platform { get; set; } = string.Empty;

    [JsonPropertyName("downloads")]
    public int? Downloads { get; set; }

    [JsonPropertyName("isInstalled")]
    public bool IsInstalled { get; set; } = false;
}
