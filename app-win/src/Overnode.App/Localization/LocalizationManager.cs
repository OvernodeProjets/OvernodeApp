using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using CommunityToolkit.Mvvm.ComponentModel;

namespace Overnode.App.Localization;

public enum AppLanguage
{
    Fr,
    En
}

public partial class LocalizationManager : ObservableObject
{
    private static readonly Lazy<LocalizationManager> _instance = new(() => new LocalizationManager());
    public static LocalizationManager Instance => _instance.Value;

    [ObservableProperty]
    private AppLanguage _currentLanguage = AppLanguage.Fr;

    public event EventHandler? LanguageChanged;

    private Dictionary<string, string> _translations = new(StringComparer.OrdinalIgnoreCase);

    private LocalizationManager()
    {
        LoadLanguage(AppLanguage.Fr);
    }

    public void SetLanguage(AppLanguage language)
    {
        if (CurrentLanguage == language && _translations.Count > 0) return;
        CurrentLanguage = language;
        LoadLanguage(language);
        OnPropertyChanged(string.Empty); // Notify all bindings of translation changes
        LanguageChanged?.Invoke(this, EventArgs.Empty);
    }

    private void LoadLanguage(AppLanguage language)
    {
        string fileName = language == AppLanguage.En ? "en.json" : "fr.json";
        string baseDir = AppDomain.CurrentDomain.BaseDirectory;
        string filePath = Path.Combine(baseDir, "Localization", fileName);

        if (!File.Exists(filePath))
        {
            // Fallback check in source or working directory
            filePath = Path.Combine(Directory.GetCurrentDirectory(), "Localization", fileName);
        }

        if (File.Exists(filePath))
        {
            try
            {
                string json = File.ReadAllText(filePath);
                var dict = JsonSerializer.Deserialize<Dictionary<string, string>>(json);
                if (dict != null)
                {
                    _translations = new Dictionary<string, string>(dict, StringComparer.OrdinalIgnoreCase);
                    return;
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[Localization] Load error: {ex.Message}");
            }
        }
    }

    public string GetString(string key, string? defaultValue = null)
    {
        if (string.IsNullOrEmpty(key)) return string.Empty;
        if (_translations.TryGetValue(key, out var val))
        {
            return val;
        }
        return defaultValue ?? key;
    }

    public string this[string key] => GetString(key);
}
