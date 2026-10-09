using System;
using System.IO;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
#if HAS_WINUI
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Imaging;
using Windows.UI;
#endif
using Overnode.App.Models;

namespace Overnode.App.Services;

public partial class ThemeManager : ObservableObject
{
    private static readonly Lazy<ThemeManager> _instance = new(() => new ThemeManager());
    public static ThemeManager Shared => _instance.Value;

    private readonly string _settingsFilePath;
    private readonly string _cacheDirectory;
    private readonly HttpClient _httpClient;

    [ObservableProperty]
    private AppThemeConfig _currentConfig;

#if HAS_WINUI
    [ObservableProperty]
    private BitmapImage? _backgroundBitmap;
#endif

    [ObservableProperty]
    private bool _isDownloadingBackground;

    [ObservableProperty]
    private string? _backgroundLoadError;

    public bool HasActiveCustomBackground
    {
        get
        {
#if HAS_WINUI
            return (BackgroundBitmap != null || !string.IsNullOrWhiteSpace(CurrentConfig.BackgroundLocalPath))
                   && CurrentConfig.BackgroundOpacity > 0.01;
#else
            return (!string.IsNullOrWhiteSpace(CurrentConfig.BackgroundImageUrl) || !string.IsNullOrWhiteSpace(CurrentConfig.BackgroundLocalPath))
                   && CurrentConfig.BackgroundOpacity > 0.01;
#endif
        }
    }

    public NavigationTab ResolvedLandingTab => CurrentConfig.LandingTab switch
    {
        "servers" => NavigationTab.Servers,
        "wallet" => NavigationTab.Wallet,
        "daily_reward" => NavigationTab.DailyReward,
        "store" => NavigationTab.Store,
        "support" => NavigationTab.Support,
        "afk" => NavigationTab.Afk,
        "settings" => NavigationTab.Settings,
        _ => NavigationTab.Dashboard
    };

    public IReadOnlyList<AppThemeConfig> Presets => PresetThemes.All;

    private ThemeManager()
    {
        string appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        string folder = Path.Combine(appData, "Overnode");
        _cacheDirectory = Path.Combine(folder, "ThemeBackgrounds");

        try
        {
            Directory.CreateDirectory(folder);
            Directory.CreateDirectory(_cacheDirectory);
        }
        catch { }

        bool isTestEnvironment = AppDomain.CurrentDomain.FriendlyName.Contains("Tests", StringComparison.OrdinalIgnoreCase)
            || AppDomain.CurrentDomain.FriendlyName.Contains("testhost", StringComparison.OrdinalIgnoreCase)
            || Environment.GetEnvironmentVariable("OVERNODE_TEST_THEME") == "1";
        string configFileName = isTestEnvironment ? "theme_config_test.json" : "theme_config.json";
        _settingsFilePath = Path.Combine(folder, configFileName);
        _httpClient = new HttpClient { Timeout = TimeSpan.FromSeconds(15) };
        _httpClient.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) OvernodeApp/1.0");

        var loaded = LoadStoredConfig() ?? PresetThemes.OvernodeOriginal;

        if ((!string.IsNullOrWhiteSpace(loaded.BackgroundImageUrl) || !string.IsNullOrWhiteSpace(loaded.BackgroundLocalPath))
            && loaded.BackgroundOpacity <= 0.25)
        {
            loaded.BackgroundOpacity = 0.85;
            if (loaded.BackgroundOverlayDarkness >= 0.65)
            {
                loaded.BackgroundOverlayDarkness = 0.30;
            }
        }

        _currentConfig = loaded;

        _ = LoadBackgroundImageIfNeededAsync();
        ApplyCurrentColorsToApplicationResources();
    }

    public void ApplyPreset(AppThemeConfig preset)
    {
        var newConfig = preset.Clone();
        newConfig.BackgroundImageUrl = CurrentConfig.BackgroundImageUrl;
        newConfig.BackgroundLocalPath = CurrentConfig.BackgroundLocalPath;
        newConfig.LandingTab = CurrentConfig.LandingTab;
        newConfig.SidebarPosition = CurrentConfig.SidebarPosition;

        CurrentConfig = newConfig;
        SaveConfig();
        ApplyCurrentColorsToApplicationResources();
    }

    public void ResetToDefault()
    {
        CurrentConfig = PresetThemes.OvernodeOriginal.Clone();
#if HAS_WINUI
        BackgroundBitmap = null;
#endif
        SaveConfig();
        ApplyCurrentColorsToApplicationResources();
    }

    public void UpdateColors(Action<ThemeColorsConfig> update)
    {
        var copy = CurrentConfig.Clone();
        copy.Id = "custom";
        copy.Name = "Thème Personnalisé";
        update(copy.Colors);

        CurrentConfig = copy;
        SaveConfig();
        ApplyCurrentColorsToApplicationResources();
    }

    public void UpdateBackground(
        string? url,
        string? localPath,
        double? opacity = null,
        double? blur = null,
        double? darkness = null)
    {
        var copy = CurrentConfig.Clone();
        copy.BackgroundImageUrl = url;
        copy.BackgroundLocalPath = localPath;

        if ((!string.IsNullOrWhiteSpace(url) || !string.IsNullOrWhiteSpace(localPath)) && copy.BackgroundOpacity < 0.4)
        {
            copy.BackgroundOpacity = 0.85;
            if (copy.BackgroundOverlayDarkness > 0.4)
            {
                copy.BackgroundOverlayDarkness = 0.30;
            }
        }

        if (opacity.HasValue) copy.BackgroundOpacity = opacity.Value;
        if (blur.HasValue) copy.BackgroundBlur = blur.Value;
        if (darkness.HasValue) copy.BackgroundOverlayDarkness = darkness.Value;

        CurrentConfig = copy;
        SaveConfig();
        _ = LoadBackgroundImageIfNeededAsync();
    }

    public void UpdateLandingTab(string tab)
    {
        var copy = CurrentConfig.Clone();
        copy.LandingTab = tab;
        CurrentConfig = copy;
        SaveConfig();
    }

    public void UpdateSidebarPosition(SidebarPosition pos)
    {
        var copy = CurrentConfig.Clone();
        copy.SidebarPosition = pos;
        CurrentConfig = copy;
        SaveConfig();
    }

    public void UpdateCornerRadius(double radius)
    {
        var copy = CurrentConfig.Clone();
        copy.CardCornerRadius = radius;
        CurrentConfig = copy;
        SaveConfig();
    }

    public void UpdateLayoutPreferences(string landingTab, SidebarPosition sidebarPosition, double cardCornerRadius)
    {
        var copy = CurrentConfig.Clone();
        copy.LandingTab = landingTab;
        copy.SidebarPosition = sidebarPosition;
        copy.CardCornerRadius = cardCornerRadius;
        CurrentConfig = copy;
        SaveConfig();
    }

    public void ExportConfiguration(string destinationFilePath)
    {
        var options = new JsonSerializerOptions { WriteIndented = true };
        string json = JsonSerializer.Serialize(CurrentConfig, options);
        File.WriteAllText(destinationFilePath, json, Encoding.UTF8);
    }

    public void ImportConfiguration(string sourceFilePath)
    {
        string json = File.ReadAllText(sourceFilePath, Encoding.UTF8);
        var imported = JsonSerializer.Deserialize<AppThemeConfig>(json);
        if (imported != null)
        {
            CurrentConfig = imported;
            SaveConfig();
            ApplyCurrentColorsToApplicationResources();
            _ = LoadBackgroundImageIfNeededAsync();
        }
        else
        {
            throw new InvalidOperationException("Format de configuration invalide");
        }
    }

    public void ReloadConfig()
    {
        var loaded = LoadStoredConfig();
        if (loaded != null)
        {
            CurrentConfig = loaded;
            ApplyCurrentColorsToApplicationResources();
            _ = LoadBackgroundImageIfNeededAsync();
        }
    }

    private AppThemeConfig? LoadStoredConfig()
    {
        try
        {
            if (File.Exists(_settingsFilePath))
            {
                string json = File.ReadAllText(_settingsFilePath, Encoding.UTF8);
                return JsonSerializer.Deserialize<AppThemeConfig>(json);
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[ThemeManager] Error loading config: {ex.Message}");
        }
        return null;
    }

    private void SaveConfig()
    {
        try
        {
            string? dir = Path.GetDirectoryName(_settingsFilePath);
            if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
            {
                Directory.CreateDirectory(dir);
            }
            var options = new JsonSerializerOptions { WriteIndented = true };
            string json = JsonSerializer.Serialize(CurrentConfig, options);
            File.WriteAllText(_settingsFilePath, json, Encoding.UTF8);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[ThemeManager] Error saving config: {ex.Message}");
        }
    }

    public async Task LoadBackgroundImageIfNeededAsync()
    {
        // 1. Image locale
        if (!string.IsNullOrWhiteSpace(CurrentConfig.BackgroundLocalPath))
        {
            string localPath = CurrentConfig.BackgroundLocalPath;
            if (File.Exists(localPath))
            {
                try
                {
                    await SetBitmapFromPathAsync(localPath);
                    BackgroundLoadError = null;
                    OnPropertyChanged(nameof(HasActiveCustomBackground));
                    return;
                }
                catch (Exception ex)
                {
                    BackgroundLoadError = ex.Message;
                }
            }
        }

        // 2. URL Web
        string? urlStr = CurrentConfig.BackgroundImageUrl?.Trim();
        if (string.IsNullOrWhiteSpace(urlStr))
        {
#if HAS_WINUI
            BackgroundBitmap = null;
#endif
            BackgroundLoadError = null;
            OnPropertyChanged(nameof(HasActiveCustomBackground));
            return;
        }

        string cacheFile = GetCacheFilePath(urlStr);
        if (File.Exists(cacheFile))
        {
            try
            {
                await SetBitmapFromPathAsync(cacheFile);
                BackgroundLoadError = null;
                OnPropertyChanged(nameof(HasActiveCustomBackground));
            }
            catch { }
        }

        if (!Uri.TryCreate(urlStr, UriKind.Absolute, out var uri))
        {
            BackgroundLoadError = "URL d'image invalide";
            IsDownloadingBackground = false;
            return;
        }

        IsDownloadingBackground = true;
        BackgroundLoadError = null;

        try
        {
            var bytes = await _httpClient.GetByteArrayAsync(uri);
            if (bytes != null && bytes.Length > 0)
            {
                await File.WriteAllBytesAsync(cacheFile, bytes);
                await SetBitmapFromPathAsync(cacheFile);
                BackgroundLoadError = null;
            }
        }
        catch (Exception ex)
        {
#if HAS_WINUI
            if (BackgroundBitmap == null)
            {
                BackgroundLoadError = ex.Message;
            }
#else
            BackgroundLoadError = ex.Message;
#endif
        }
        finally
        {
            IsDownloadingBackground = false;
            OnPropertyChanged(nameof(HasActiveCustomBackground));
        }
    }

    private Task SetBitmapFromPathAsync(string path)
    {
        var tcs = new TaskCompletionSource();
#if HAS_WINUI
        try
        {
            void Action()
            {
                try
                {
                    var bmp = new BitmapImage(new Uri(path));
                    BackgroundBitmap = bmp;
                    tcs.SetResult();
                }
                catch (Exception ex)
                {
                    tcs.SetException(ex);
                }
            }

            if (MainWindow.Current?.DispatcherQueue != null)
            {
                MainWindow.Current.DispatcherQueue.TryEnqueue(Action);
            }
            else
            {
                tcs.SetResult();
            }
        }
        catch (Exception ex)
        {
            tcs.SetException(ex);
        }
#else
        tcs.SetResult();
#endif
        return tcs.Task;
    }

    private string GetCacheFilePath(string key)
    {
        byte[] bytes = Encoding.UTF8.GetBytes(key);
        string b64 = Convert.ToBase64String(bytes).Replace('/', '_').Replace('+', '-');
        if (b64.Length > 64) b64 = b64.Substring(0, 64);
        return Path.Combine(_cacheDirectory, $"{b64}.dat");
    }

    public void ApplyCurrentColorsToApplicationResources()
    {
#if HAS_WINUI
        void UpdateResources()
        {
            try
            {
                if (Application.Current?.Resources is not ResourceDictionary res) return;

                var c = CurrentConfig.Colors;

                UpdateBrush(res, "OvernodeBackgroundBrush", "OvernodeBackgroundColor", c.BackgroundHex);
                UpdateBrush(res, "OvernodeCardBrush", "OvernodeCardColor", c.CardBackgroundHex);
                UpdateBrush(res, "OvernodeSecondaryCardBrush", "OvernodeSecondaryCardColor", c.SecondaryCardBackgroundHex);
                UpdateBrush(res, "OvernodeBorderBrush", "OvernodeBorderColor", c.BorderHex);

                // Subtle border
                var subtleBase = ColorHexHelper.FromHex(c.BorderHex);
                byte subtleAlpha = (byte)Math.Clamp((int)(c.BorderSubtleOpacity * 255), 10, 255);
                var subtleColor = Color.FromArgb(subtleAlpha, subtleBase.R, subtleBase.G, subtleBase.B);
                UpdateBrushWithColor(res, "OvernodeBorderSubtleBrush", "OvernodeBorderSubtleColor", subtleColor);

                UpdateBrush(res, "OvernodeTextPrimaryBrush", "OvernodeTextPrimaryColor", c.TextPrimaryHex);
                UpdateBrush(res, "OvernodeTextSecondaryBrush", "OvernodeTextSecondaryColor", c.TextSecondaryHex);
                UpdateBrush(res, "OvernodeTextMutedBrush", "OvernodeTextMutedColor", c.TextMutedHex);
                UpdateBrush(res, "OvernodeAccentGoldBrush", "OvernodeAccentGoldColor", c.AccentGoldHex);
                UpdateBrush(res, "OvernodeAccentCyanBrush", "OvernodeAccentCyanColor", c.AccentCyanHex);
                UpdateBrush(res, "OvernodeAccentDiscordBrush", "OvernodeAccentDiscordColor", c.AccentDiscordHex);
                UpdateBrush(res, "OvernodeAccentSuccessBrush", "OvernodeAccentSuccessColor", c.AccentSuccessHex);
                UpdateBrush(res, "OvernodeAccentDangerBrush", "OvernodeAccentDangerColor", c.AccentDangerHex);
                UpdateBrush(res, "OvernodeAccentWarningBrush", "OvernodeAccentWarningColor", c.AccentWarningHex);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[ThemeManager] Error updating application resources: {ex.Message}");
            }
        }

        if (MainWindow.Current?.DispatcherQueue != null)
        {
            if (MainWindow.Current.DispatcherQueue.HasThreadAccess)
            {
                UpdateResources();
            }
            else
            {
                MainWindow.Current.DispatcherQueue.TryEnqueue(UpdateResources);
            }
        }
        else
        {
            UpdateResources();
        }
#endif
    }

#if HAS_WINUI
    private static void UpdateBrush(ResourceDictionary rootRes, string brushKey, string colorKey, string hex)
    {
        var col = ColorHexHelper.FromHex(hex);
        UpdateBrushWithColor(rootRes, brushKey, colorKey, col);
    }

    private static void UpdateBrushWithColor(ResourceDictionary rootRes, string brushKey, string colorKey, Color col)
    {
        SolidColorBrush? foundBrush = null;

        void Traverse(ResourceDictionary dict)
        {
            if (dict == null) return;

            try
            {
                if (dict.TryGetValue(brushKey, out var bObj) && bObj is SolidColorBrush sb)
                {
                    sb.Color = col;
                    foundBrush ??= sb;
                }
            }
            catch { }

            try
            {
                if (dict.TryGetValue(colorKey, out _))
                {
                    dict[colorKey] = col;
                }
            }
            catch { }

            if (dict.MergedDictionaries != null)
            {
                foreach (var child in dict.MergedDictionaries)
                {
                    Traverse(child);
                }
            }
        }

        Traverse(rootRes);

        foundBrush ??= new SolidColorBrush(col);
        try
        {
            rootRes[brushKey] = foundBrush;
            rootRes[colorKey] = col;
        }
        catch { }
    }
#endif
}
