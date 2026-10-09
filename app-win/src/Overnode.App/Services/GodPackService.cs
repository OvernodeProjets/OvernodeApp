using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Http;
using System.Net.Http.Json;
using System.Text.Json;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using Overnode.App.Models;

namespace Overnode.App.Services;

public partial class GodPackService : ObservableObject
{
    private static readonly Lazy<GodPackService> _instance = new(() => new GodPackService());
    public static GodPackService Shared => _instance.Value;

    public const string DiscordIdStorageKey = "overnode_godpack_discord_id";

    [ObservableProperty]
    private bool _hasGodPack;

    [ObservableProperty]
    private bool _isChecking;

    [ObservableProperty]
    private DateTime? _lastCheckedAt;

    [ObservableProperty]
    private string? _lastError;

    [ObservableProperty]
    private string? _activeDiscordId;

    [ObservableProperty]
    private string? _savedDiscordId;

    private readonly string _storageFilePath;
    private readonly HttpClient _httpClient;

    private GodPackService()
    {
        string appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        string folder = Path.Combine(appData, "Overnode");
        try
        {
            Directory.CreateDirectory(folder);
        }
        catch { }

        _storageFilePath = Path.Combine(folder, "godpack_vip.json");
        _httpClient = new HttpClient { Timeout = TimeSpan.FromSeconds(4) };

        LoadSavedDiscordId();

        if (Environment.GetEnvironmentVariable("OVERNODE_FORCE_GOD_PACK") == "1")
        {
            _hasGodPack = true;
        }
    }

    private void LoadSavedDiscordId()
    {
        try
        {
            if (File.Exists(_storageFilePath))
            {
                string json = File.ReadAllText(_storageFilePath);
                using var doc = JsonDocument.Parse(json);
                if (doc.RootElement.TryGetProperty("discordId", out var prop))
                {
                    string? saved = prop.GetString()?.Trim();
                    if (!string.IsNullOrEmpty(saved))
                    {
                        SavedDiscordId = saved;
                    }
                }
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[GodPackService] Error loading saved Discord ID: {ex.Message}");
        }
    }

    public void SaveDiscordId(string id)
    {
        string clean = id?.Trim() ?? string.Empty;
        if (string.IsNullOrEmpty(clean)) return;

        SavedDiscordId = clean;

        try
        {
            var data = new { discordId = clean };
            string json = JsonSerializer.Serialize(data, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(_storageFilePath, json);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[GodPackService] Error saving Discord ID: {ex.Message}");
        }
    }

    public void ClearSavedDiscordId()
    {
        try
        {
            if (File.Exists(_storageFilePath))
            {
                File.Delete(_storageFilePath);
            }
        }
        catch { }

        SavedDiscordId = null;
        ActiveDiscordId = null;
        HasGodPack = false;
    }

    public async Task CheckAccessAsync(User? user = null, string? explicitDiscordId = null)
    {
        if (Environment.GetEnvironmentVariable("OVERNODE_FORCE_GOD_PACK") == "1")
        {
            HasGodPack = true;
            return;
        }

        IsChecking = true;
        LastError = null;

        bool verified = false;
        string? verifiedDiscordId = null;

        // 1. Vérification via Toledo Cloud API (/api/bundles/status)
        try
        {
            var status = await APIClient.Shared.GetAsync<BundleStatusResponse>("/api/bundles/status");
            if (status?.HasGodPack == true)
            {
                verified = true;
            }
        }
        catch
        {
            // Non-bloquant, on poursuit la vérification via le portail Updater
        }

        // 2. Collecte de tous les identifiants Discord candidats
        var candidateIds = new List<string>();

        if (!string.IsNullOrWhiteSpace(explicitDiscordId))
        {
            candidateIds.Add(explicitDiscordId.Trim());
        }

        if (!string.IsNullOrWhiteSpace(SavedDiscordId) && !candidateIds.Contains(SavedDiscordId.Trim()))
        {
            candidateIds.Add(SavedDiscordId.Trim());
        }

        string? rpcId = DiscordRPCService.Shared.CurrentDiscordUserId?.Trim();
        if (!string.IsNullOrEmpty(rpcId) && !candidateIds.Contains(rpcId))
        {
            candidateIds.Add(rpcId);
        }

        string? userDId = user?.DiscordId?.Trim();
        if (!string.IsNullOrEmpty(userDId) && !candidateIds.Contains(userDId))
        {
            candidateIds.Add(userDId);
        }

        if (!string.IsNullOrEmpty(user?.Id) && user.Id.Length >= 17 && ulong.TryParse(user.Id, out _) && !candidateIds.Contains(user.Id))
        {
            candidateIds.Add(user.Id);
        }

        // 3. Vérification via OvernodeApp-Updater (/api/v1/godpack/check/{discordId})
        foreach (var candidate in candidateIds)
        {
            bool? updaterVerified = await CheckUpdaterDiscordIdAsync(candidate);
            if (updaterVerified == true)
            {
                verified = true;
                verifiedDiscordId = candidate;
                break;
            }
        }

        if (verified)
        {
            if (!string.IsNullOrEmpty(verifiedDiscordId))
            {
                ActiveDiscordId = verifiedDiscordId;
                SaveDiscordId(verifiedDiscordId);
            }
            HasGodPack = true;
        }
        else
        {
            HasGodPack = false;
            if (!string.IsNullOrWhiteSpace(explicitDiscordId) && candidateIds.Count > 0)
            {
                ActiveDiscordId = null;
            }
        }

        LastCheckedAt = DateTime.UtcNow;
        IsChecking = false;
    }

    public async Task<bool?> CheckUpdaterDiscordIdAsync(string discordId)
    {
        if (string.IsNullOrWhiteSpace(discordId))
        {
            return false;
        }

        string encoded = Uri.EscapeDataString(discordId.Trim());

        var urlsToTry = new List<string>
        {
            $"{UpdateService.Shared.UpdaterBaseUrl.ToString().TrimEnd('/')}/api/v1/godpack/check/{encoded}",
            $"http://127.0.0.1:3344/api/v1/godpack/check/{encoded}",
            $"http://localhost:3344/api/v1/godpack/check/{encoded}",
            $"http://127.0.0.1:3000/api/v1/godpack/check/{encoded}",
            $"http://localhost:3000/api/v1/godpack/check/{encoded}"
        };

        foreach (var url in urlsToTry)
        {
            try
            {
                using var request = new HttpRequestMessage(HttpMethod.Get, url);
                request.Headers.Add("Accept", "application/json");

                using var response = await _httpClient.SendAsync(request);
                if (response.IsSuccessStatusCode)
                {
                    var result = await response.Content.ReadFromJsonAsync<UpdaterGodPackCheckResponse>();
                    if (result?.HasGodPack == true)
                    {
                        return true;
                    }
                }
            }
            catch
            {
                // Try next endpoint
            }
        }

        return false;
    }

    public void SetDebugGodPack(bool active)
    {
        HasGodPack = active;
    }
}
