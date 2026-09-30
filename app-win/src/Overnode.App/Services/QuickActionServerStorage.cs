using System;
using System.IO;
using System.Text.Json;

namespace Overnode.App.Services;

public sealed class QuickActionServerStorage
{
    private static readonly Lazy<QuickActionServerStorage> _instance = new(() => new QuickActionServerStorage());
    public static QuickActionServerStorage Instance => _instance.Value;
    public static QuickActionServerStorage Shared => _instance.Value;

    private const string SettingKey = "overnode_quick_action_server_id";
    public event EventHandler? DidChange;

    private readonly string _settingsFilePath;
    private string? _cachedId;

    private QuickActionServerStorage()
    {
        string appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        string folder = Path.Combine(appData, "Overnode");
        Directory.CreateDirectory(folder);
        _settingsFilePath = Path.Combine(folder, "quick_action_server.json");

        Load();
    }

    private void Load()
    {
        try
        {
            if (File.Exists(_settingsFilePath))
            {
                string json = File.ReadAllText(_settingsFilePath);
                var doc = JsonDocument.Parse(json);
                if (doc.RootElement.TryGetProperty(SettingKey, out var prop))
                {
                    _cachedId = prop.GetString();
                }
            }
        }
        catch
        {
            _cachedId = null;
        }
    }

    public string? GetSelectedServerIdentifier()
    {
        return string.IsNullOrWhiteSpace(_cachedId) ? null : _cachedId.Trim();
    }

    public void SetSelectedServerIdentifier(string? identifier)
    {
        string? trimmed = string.IsNullOrWhiteSpace(identifier) ? null : identifier.Trim();
        if (_cachedId == trimmed) return;

        _cachedId = trimmed;

        try
        {
            var data = new { overnode_quick_action_server_id = _cachedId };
            string json = JsonSerializer.Serialize(data, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(_settingsFilePath, json);
        }
        catch
        {
        }

        DidChange?.Invoke(this, EventArgs.Empty);
    }
}
