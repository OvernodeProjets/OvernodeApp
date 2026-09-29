using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Overnode.App.Services;

public class CookieRecord
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("value")]
    public string Value { get; set; } = string.Empty;

    [JsonPropertyName("domain")]
    public string Domain { get; set; } = string.Empty;

    [JsonPropertyName("path")]
    public string Path { get; set; } = "/";

    [JsonPropertyName("secure")]
    public bool Secure { get; set; }

    [JsonPropertyName("httpOnly")]
    public bool HttpOnly { get; set; }

    [JsonPropertyName("expires")]
    public DateTime? Expires { get; set; }
}

public sealed class SessionPersistence
{
    private static readonly Lazy<SessionPersistence> _instance = new(() => new SessionPersistence());
    public static SessionPersistence Instance => _instance.Value;

    private static readonly byte[] Entropy = Encoding.UTF8.GetBytes("Overnode.SessionProtection.v1");
    private readonly string _storagePath;

    private SessionPersistence()
    {
        string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        _storagePath = Path.Combine(localAppData, "Overnode", "session.dat");
    }

    public void SaveCookies(IEnumerable<Cookie> cookies)
    {
        try
        {
            var records = new List<CookieRecord>();
            foreach (var c in cookies)
            {
                if (c.Domain.Contains("overnode.fr", StringComparison.OrdinalIgnoreCase) ||
                    c.Domain.Contains("discord.com", StringComparison.OrdinalIgnoreCase))
                {
                    records.Add(new CookieRecord
                    {
                        Name = c.Name,
                        Value = c.Value,
                        Domain = c.Domain,
                        Path = c.Path,
                        Secure = c.Secure,
                        HttpOnly = c.HttpOnly,
                        Expires = c.Expires != DateTime.MinValue ? c.Expires : DateTime.UtcNow.AddDays(30)
                    });
                }
            }

            string json = JsonSerializer.Serialize(records);
            byte[] plainBytes = Encoding.UTF8.GetBytes(json);
            byte[] encryptedBytes = ProtectedData.Protect(
                plainBytes,
                Entropy,
                DataProtectionScope.CurrentUser
            );

            string? dir = Path.GetDirectoryName(_storagePath);
            if (!string.IsNullOrEmpty(dir))
            {
                Directory.CreateDirectory(dir);
            }

            File.WriteAllBytes(_storagePath, encryptedBytes);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[SessionPersistence] Save error: {ex.Message}");
        }
    }

    public List<Cookie> LoadCookies()
    {
        var result = new List<Cookie>();
        if (!File.Exists(_storagePath)) return result;

        try
        {
            byte[] encryptedBytes = File.ReadAllBytes(_storagePath);
            byte[] plainBytes = ProtectedData.Unprotect(
                encryptedBytes,
                Entropy,
                DataProtectionScope.CurrentUser
            );

            string json = Encoding.UTF8.GetString(plainBytes);
            var records = JsonSerializer.Deserialize<List<CookieRecord>>(json);
            if (records != null)
            {
                foreach (var r in records)
                {
                    if (string.IsNullOrWhiteSpace(r.Name) || string.IsNullOrWhiteSpace(r.Domain)) continue;

                    string cleanDomain = r.Domain.TrimStart('.');
                    var cookie = new Cookie(r.Name, r.Value, r.Path, cleanDomain)
                    {
                        Secure = r.Secure,
                        HttpOnly = r.HttpOnly,
                        Expires = r.Expires ?? DateTime.UtcNow.AddDays(30)
                    };
                    result.Add(cookie);
                }
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[SessionPersistence] Load error: {ex.Message}");
        }

        return result;
    }

    public void Clear()
    {
        try
        {
            if (File.Exists(_storagePath))
            {
                File.Delete(_storagePath);
            }
        }
        catch
        {
            // Ignore error on delete
        }
    }
}
