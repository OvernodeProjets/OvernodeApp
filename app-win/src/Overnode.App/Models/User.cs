using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace Overnode.App.Models;

public class User
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("username")]
    public string Username { get; set; } = "User";

    [JsonPropertyName("email")]
    public string Email { get; set; } = string.Empty;

    [JsonPropertyName("global_name")]
    public string? GlobalName { get; set; }

    [JsonPropertyName("role")]
    public string? Role { get; set; }

    [JsonPropertyName("avatar_url")]
    public string? AvatarUrl { get; set; }

    [JsonPropertyName("coins")]
    public int Coins { get; set; } = 0;

    public string DisplayName => !string.IsNullOrWhiteSpace(GlobalName) ? GlobalName : Username;
    public string Initial => !string.IsNullOrEmpty(Username) ? Username.Substring(0, 1).ToUpperInvariant() : "U";
}

public class AuthStateResponse
{
    [JsonPropertyName("authenticated")]
    public bool Authenticated { get; set; }

    [JsonPropertyName("twoFactorPending")]
    public bool? TwoFactorPending { get; set; }

    [JsonPropertyName("twoFactorEnabled")]
    public bool? TwoFactorEnabled { get; set; }

    [JsonPropertyName("banned")]
    public bool? Banned { get; set; }

    [JsonPropertyName("admin")]
    public bool? Admin { get; set; }

    [JsonPropertyName("user")]
    public User? User { get; set; }

    [JsonPropertyName("site_name")]
    public string? SiteName { get; set; }
}

public class InitResponse
{
    public class UserPayload
    {
        [JsonPropertyName("id")]
        public object? RawId { get; set; }

        public string Id => RawId?.ToString() ?? Guid.NewGuid().ToString();

        [JsonPropertyName("username")]
        public string Username { get; set; } = "User";

        [JsonPropertyName("email")]
        public string Email { get; set; } = string.Empty;

        [JsonPropertyName("global_name")]
        public string? GlobalName { get; set; }

        [JsonPropertyName("pterodactylEmail")]
        public string? PterodactylEmail { get; set; }
    }

    public class RolePayload
    {
        [JsonPropertyName("id")]
        public string? Id { get; set; }

        [JsonPropertyName("name")]
        public string? Name { get; set; }

        [JsonPropertyName("color")]
        public string? Color { get; set; }
    }

    public class SubuserServerItem
    {
        [JsonPropertyName("id")]
        public object? RawId { get; set; }

        [JsonPropertyName("serverId")]
        public string? ServerId { get; set; }

        [JsonPropertyName("server_id")]
        public string? ServerIdAlt { get; set; }

        [JsonPropertyName("serverName")]
        public string? ServerName { get; set; }

        [JsonPropertyName("name")]
        public string? Name { get; set; }

        [JsonPropertyName("ownerId")]
        public object? RawOwnerId { get; set; }

        public string ResolvedId => !string.IsNullOrWhiteSpace(ServerId) ? ServerId : (ServerIdAlt ?? RawId?.ToString() ?? string.Empty);
        public string ResolvedName => !string.IsNullOrWhiteSpace(ServerName) ? ServerName : (Name ?? "Shared Server");
    }

    [JsonPropertyName("user")]
    public UserPayload? User { get; set; }

    [JsonPropertyName("coins")]
    public int? Coins { get; set; }

    [JsonPropertyName("admin")]
    public bool? Admin { get; set; }

    [JsonPropertyName("permissions")]
    public List<string>? Permissions { get; set; }

    [JsonPropertyName("roles")]
    public List<RolePayload>? Roles { get; set; }

    [JsonPropertyName("servers")]
    public List<PteroServerWrapper>? Servers { get; set; }

    [JsonPropertyName("subuserServers")]
    public List<SubuserServerItem>? SubuserServers { get; set; }
}
