using System;
using System.Collections.Generic;
using System.Globalization;
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

    private readonly string _settingsFilePath;

    [ObservableProperty]
    private AppLanguage _currentLanguage = AppLanguage.Fr;

    public event EventHandler? LanguageChanged;

    private Dictionary<string, string> _translations = new(StringComparer.OrdinalIgnoreCase);

    private LocalizationManager()
    {
        string appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        string folder = Path.Combine(appData, "Overnode");
        try
        {
            Directory.CreateDirectory(folder);
        }
        catch { }
        _settingsFilePath = Path.Combine(folder, "localization.json");

        AppLanguage initialLang = DetermineInitialLanguage();
        _currentLanguage = initialLang;
        LoadLanguage(initialLang);
    }

    private AppLanguage DetermineInitialLanguage()
    {
        try
        {
            if (File.Exists(_settingsFilePath))
            {
                string json = File.ReadAllText(_settingsFilePath);
                using var doc = JsonDocument.Parse(json);
                if (doc.RootElement.TryGetProperty("language", out var langProp))
                {
                    string? saved = langProp.GetString();
                    if (string.Equals(saved, "en", StringComparison.OrdinalIgnoreCase))
                    {
                        return AppLanguage.En;
                    }
                    if (string.Equals(saved, "fr", StringComparison.OrdinalIgnoreCase))
                    {
                        return AppLanguage.Fr;
                    }
                }
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[Localization] Error reading saved language: {ex.Message}");
        }

        // Fallback: Detect Windows OS Culture
        try
        {
            string uiLang = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName;
            if (uiLang.Equals("en", StringComparison.OrdinalIgnoreCase))
            {
                return AppLanguage.En;
            }
        }
        catch { }

        return AppLanguage.Fr;
    }

    public void SetLanguage(AppLanguage language)
    {
        if (CurrentLanguage == language && _translations.Count > 0) return;
        CurrentLanguage = language;
        SaveLanguage(language);
        LoadLanguage(language);
        OnPropertyChanged(string.Empty); // Notify all bindings of translation changes
        LanguageChanged?.Invoke(this, EventArgs.Empty);
    }

    private void SaveLanguage(AppLanguage language)
    {
        try
        {
            string code = language == AppLanguage.En ? "en" : "fr";
            var data = new { language = code };
            string json = JsonSerializer.Serialize(data, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(_settingsFilePath, json);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[Localization] Error saving language: {ex.Message}");
        }
    }

    private void LoadLanguage(AppLanguage language)
    {
        string fileName = language == AppLanguage.En ? "en.json" : "fr.json";
        
        // Search in several possible directories
        var candidatePaths = new List<string>
        {
            Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Localization", fileName),
            Path.Combine(AppContext.BaseDirectory, "Localization", fileName),
            Path.Combine(Directory.GetCurrentDirectory(), "Localization", fileName),
            Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "src", "Overnode.App", "Localization", fileName),
            Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", "..", "..", "src", "Overnode.App", "Localization", fileName)
        };

        foreach (var path in candidatePaths)
        {
            try
            {
                if (File.Exists(path))
                {
                    string json = File.ReadAllText(path);
                    var dict = JsonSerializer.Deserialize<Dictionary<string, string>>(json);
                    if (dict != null && dict.Count > 0)
                    {
                        _translations = new Dictionary<string, string>(dict, StringComparer.OrdinalIgnoreCase);
                        return;
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[Localization] Load error for '{path}': {ex.Message}");
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

    public string Format(string key, params object[] args)
    {
        string template = GetString(key);
        try
        {
            return string.Format(template, args);
        }
        catch
        {
            return template;
        }
    }

    public string this[string key] => GetString(key);
}

