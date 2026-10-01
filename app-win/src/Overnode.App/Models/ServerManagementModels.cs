using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Text.Json.Serialization;
using Overnode.App.Localization;

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
    Package,
    Plugins,
    Logs,
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
        ServerTab.Package => "server_tab_package",
        ServerTab.Plugins => "server_tab_plugins",
        ServerTab.Logs => "server_tab_logs",
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
        ServerTab.Package => "\uE71D", // Sliders / Package
        ServerTab.Plugins => "\uE74C", // Puzzle / Extension
        ServerTab.Logs => "\uE9D9", // History / List
        ServerTab.Settings => "\uE713", // Settings
        _ => "\uE756"
    };
}

public class RenewalDurationObject
{
    [JsonPropertyName("totalMs")]
    public double? TotalMs { get; set; }

    [JsonPropertyName("totalSeconds")]
    public double? TotalSeconds { get; set; }

    [JsonPropertyName("days")]
    public int? Days { get; set; }

    [JsonPropertyName("hours")]
    public int? Hours { get; set; }

    [JsonPropertyName("minutes")]
    public int? Minutes { get; set; }

    [JsonPropertyName("seconds")]
    public int? Seconds { get; set; }

    public string Formatted
    {
        get
        {
            int d = Days ?? 0;
            int h = Hours ?? 0;
            int m = Minutes ?? 0;
            if (d > 0) return $"{d}j {h}h";
            if (h > 0) return $"{h}h {m}min";
            if (m > 0) return $"{m} min";
            return "Moins d'une minute";
        }
    }
}

public class FlexibleRenewalStringConverter : JsonConverter<string?>
{
    public override string? Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        switch (reader.TokenType)
        {
            case JsonTokenType.Null:
                return null;

            case JsonTokenType.String:
                return reader.GetString();

            case JsonTokenType.Number:
                if (reader.TryGetDouble(out var num))
                {
                    int totalSec = num > 10_000_000 ? (int)(num / 1000.0) : (int)num;
                    int days = totalSec / 86400;
                    int hours = (totalSec % 86400) / 3600;
                    int minutes = (totalSec % 3600) / 60;
                    if (days > 0) return $"{days}j {hours}h";
                    if (hours > 0) return $"{hours}h {minutes}min";
                    if (minutes > 0) return $"{minutes} min";
                    return "Moins d'une minute";
                }
                return null;

            case JsonTokenType.StartObject:
                var duration = System.Text.Json.JsonSerializer.Deserialize<RenewalDurationObject>(ref reader, options);
                return duration?.Formatted;

            default:
                return null;
        }
    }

    public override void Write(Utf8JsonWriter writer, string? value, JsonSerializerOptions options)
    {
        if (value == null)
            writer.WriteNullValue();
        else
            writer.WriteStringValue(value);
    }
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
    [JsonConverter(typeof(FlexibleRenewalStringConverter))]
    public string? TimeRemaining { get; set; }

    [JsonPropertyName("renewalCount")]
    public int? RenewalCount { get; set; } = 0;

    [JsonPropertyName("availableIn")]
    [JsonConverter(typeof(FlexibleRenewalStringConverter))]
    public string? AvailableIn { get; set; }

    public string CalculatedTimeRemaining
    {
        get
        {
            if (!string.IsNullOrEmpty(TimeRemaining)) return TimeRemaining;
            if (string.IsNullOrEmpty(NextRenewalAt)) return "—";

            if (DateTime.TryParse(NextRenewalAt, out var nextAt))
            {
                var diff = nextAt.ToUniversalTime() - DateTime.UtcNow;
                if (diff.TotalSeconds <= 0) return "Expiré";
                if (diff.TotalDays >= 1) return $"{(int)diff.TotalDays}j {diff.Hours}h";
                if (diff.TotalHours >= 1) return $"{diff.Hours}h {diff.Minutes}min";
                if (diff.TotalMinutes >= 1) return $"{diff.Minutes} min";
                return "Moins d'une minute";
            }
            return "—";
        }
    }

    public string? CalculatedAvailableIn
    {
        get
        {
            if (!string.IsNullOrEmpty(AvailableIn)) return AvailableIn;
            if (CanRenew != false) return null;
            if (string.IsNullOrEmpty(NextRenewalAt)) return null;

            if (DateTime.TryParse(NextRenewalAt, out var nextAt))
            {
                var diff = nextAt.ToUniversalTime() - DateTime.UtcNow;
                var availableInSec = diff.TotalSeconds - (24 * 3600);
                if (availableInSec <= 0) return null;

                int totalSec = (int)availableInSec;
                int days = totalSec / 86400;
                int hours = (totalSec % 86400) / 3600;
                int minutes = (totalSec % 3600) / 60;
                if (days > 0) return $"{days}j {hours}h";
                if (hours > 0) return $"{hours}h {minutes}min";
                return $"{minutes} min";
            }
            return null;
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
    [JsonConverter(typeof(FlexibleRenewalStringConverter))]
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

    [JsonIgnore]
    public string ContextOpenText => LocalizationManager.Instance.GetString("files_context_open");

    [JsonIgnore]
    public string ContextOpenExternalText => LocalizationManager.Instance.GetString("files_context_open_external");

    [JsonIgnore]
    public string ContextDeleteText => LocalizationManager.Instance.GetString("files_context_delete");
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

    [JsonIgnore]
    public string StatusText => LocalizationManager.Instance.GetString("subdomains_status_active");
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
        ? LocalizationManager.Instance.GetString("subusers_all_permissions")
        : LocalizationManager.Instance.Format("subusers_count_permissions", Permissions.Count);

    [JsonIgnore]
    public string TwoFactorStatusText => LocalizationManager.Instance.GetString("subusers_2fa_active");
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

    [JsonIgnore]
    public string ByPrefix => LocalizationManager.Instance.GetString("logs_by_prefix");
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

    [JsonIgnore]
    public string UpdateButtonText => LocalizationManager.Instance.GetString("settings_update_btn");
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

[JsonConverter(typeof(ServerPluginItemConverter))]
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
    public string Platform { get; set; } = "spigot";

    [JsonPropertyName("downloads")]
    public int? Downloads { get; set; }

    [JsonPropertyName("isInstalled")]
    public bool IsInstalled { get; set; } = false;

    [JsonIgnore]
    public string InstallActionText => LocalizationManager.Instance.GetString("plugins_install_btn");

    [JsonIgnore]
    public string UninstallActionText => LocalizationManager.Instance.GetString("plugins_uninstall_btn");
}

public class ServerPluginItemConverter : JsonConverter<ServerPluginItem>
{
    public override ServerPluginItem? Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        if (reader.TokenType != JsonTokenType.StartObject) return null;

        using var doc = JsonDocument.ParseValue(ref reader);
        var root = doc.RootElement;

        var item = new ServerPluginItem();

        // ID (can be int or string)
        if (root.TryGetProperty("id", out var idProp))
        {
            item.Id = idProp.ValueKind == JsonValueKind.Number ? idProp.GetInt64().ToString() : idProp.GetString() ?? Guid.NewGuid().ToString();
        }
        else if (root.TryGetProperty("pluginId", out var pIdProp))
        {
            item.Id = pIdProp.ValueKind == JsonValueKind.Number ? pIdProp.GetInt64().ToString() : pIdProp.GetString() ?? Guid.NewGuid().ToString();
        }
        else
        {
            item.Id = Guid.NewGuid().ToString();
        }

        // Name
        if (root.TryGetProperty("name", out var nameProp) && nameProp.ValueKind == JsonValueKind.String)
        {
            item.Name = nameProp.GetString() ?? "Plugin";
        }
        else if (root.TryGetProperty("pluginName", out var pnProp) && pnProp.ValueKind == JsonValueKind.String)
        {
            item.Name = pnProp.GetString() ?? "Plugin";
        }

        // Description (can be description, tag, or pluginName)
        if (root.TryGetProperty("description", out var descProp) && descProp.ValueKind == JsonValueKind.String)
        {
            item.Description = descProp.GetString();
        }
        else if (root.TryGetProperty("tag", out var tagProp) && tagProp.ValueKind == JsonValueKind.String)
        {
            item.Description = tagProp.GetString();
        }
        else if (root.TryGetProperty("pluginName", out var plNameProp) && plNameProp.ValueKind == JsonValueKind.String)
        {
            var pn = plNameProp.GetString();
            if (!string.IsNullOrEmpty(pn) && pn != item.Name) item.Description = pn;
        }

        // Icon (iconUrl or icon or icon_url)
        if (root.TryGetProperty("iconUrl", out var iconProp) && iconProp.ValueKind == JsonValueKind.String)
        {
            item.IconUrl = iconProp.GetString();
        }
        else if (root.TryGetProperty("icon", out var icon2Prop) && icon2Prop.ValueKind == JsonValueKind.String)
        {
            item.IconUrl = icon2Prop.GetString();
        }
        else if (root.TryGetProperty("icon_url", out var icon3Prop) && icon3Prop.ValueKind == JsonValueKind.String)
        {
            item.IconUrl = icon3Prop.GetString();
        }

        // Version (can be string or object {"id":"latest"})
        if (root.TryGetProperty("version", out var verProp))
        {
            if (verProp.ValueKind == JsonValueKind.String)
            {
                item.Version = verProp.GetString();
            }
            else if (verProp.ValueKind == JsonValueKind.Object)
            {
                if (verProp.TryGetProperty("name", out var vn) && vn.ValueKind == JsonValueKind.String)
                    item.Version = vn.GetString();
                else if (verProp.TryGetProperty("id", out var vi) && vi.ValueKind == JsonValueKind.String)
                    item.Version = vi.GetString();
            }
        }
        item.Version ??= "latest";

        // Author (can be string or object {"name":"..."})
        if (root.TryGetProperty("author", out var authProp))
        {
            if (authProp.ValueKind == JsonValueKind.String)
            {
                item.Author = authProp.GetString();
            }
            else if (authProp.ValueKind == JsonValueKind.Object)
            {
                if (authProp.TryGetProperty("name", out var an) && an.ValueKind == JsonValueKind.String)
                    item.Author = an.GetString();
            }
        }

        // Platform
        if (root.TryGetProperty("platform", out var platProp) && platProp.ValueKind == JsonValueKind.String)
        {
            item.Platform = platProp.GetString() ?? "spigot";
        }
        else
        {
            item.Platform = "spigot";
        }

        // Downloads
        if (root.TryGetProperty("downloads", out var downProp) && downProp.ValueKind == JsonValueKind.Number)
        {
            item.Downloads = downProp.GetInt32();
        }

        // IsInstalled
        if (root.TryGetProperty("isInstalled", out var instProp))
        {
            item.IsInstalled = instProp.ValueKind == JsonValueKind.True;
        }

        return item;
    }

    public override void Write(Utf8JsonWriter writer, ServerPluginItem value, JsonSerializerOptions options)
    {
        writer.WriteStartObject();
        writer.WriteString("id", value.Id);
        writer.WriteString("name", value.Name);
        writer.WriteString("description", value.Description);
        writer.WriteString("iconUrl", value.IconUrl);
        writer.WriteString("version", value.Version);
        writer.WriteString("author", value.Author);
        writer.WriteString("platform", value.Platform);
        if (value.Downloads.HasValue) writer.WriteNumber("downloads", value.Downloads.Value);
        writer.WriteBoolean("isInstalled", value.IsInstalled);
        writer.WriteEndObject();
    }
}

public class ActivityLogsResponse
{
    public class RawLog
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
        public JsonElement? Details { get; set; }
    }

    [JsonPropertyName("data")]
    public List<RawLog> Data { get; set; } = new();
}

public class InstalledPluginsResponse
{
    public class PluginEntry
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
        public string? Platform { get; set; }
    }

    [JsonPropertyName("plugins")]
    public List<PluginEntry> Plugins { get; set; } = new();
}
