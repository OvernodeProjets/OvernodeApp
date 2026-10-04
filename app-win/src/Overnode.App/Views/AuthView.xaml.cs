using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Net;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.Web.WebView2.Core;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.Services;
using Overnode.App.ViewModels;

namespace Overnode.App.Views;

public sealed partial class AuthView : UserControl
{
    public AuthViewModel? ViewModel { get; private set; }

    private bool _isWebAuthInitialized = false;
    private bool _isWebAuthCompleted = false;

    public AuthView()
    {
        InitializeComponent();
        Loaded += OnLoaded;
        Unloaded += OnUnloaded;
    }

    public void Initialize(AuthViewModel viewModel)
    {
        if (ViewModel != null)
        {
            ViewModel.PropertyChanged -= OnViewModelPropertyChanged;
        }

        ViewModel = viewModel;
        ViewModel.PropertyChanged += OnViewModelPropertyChanged;
        UpdateLocalization();
        UpdateState();
    }

    private void OnLoaded(object sender, RoutedEventArgs e)
    {
        LocalizationManager.Instance.PropertyChanged += OnLocalizationChanged;
        UpdateLocalization();
        UpdateState();
    }

    private void OnUnloaded(object sender, RoutedEventArgs e)
    {
        LocalizationManager.Instance.PropertyChanged -= OnLocalizationChanged;
        if (ViewModel != null)
        {
            ViewModel.PropertyChanged -= OnViewModelPropertyChanged;
        }
    }

    private void OnLocalizationChanged(object? sender, PropertyChangedEventArgs e)
    {
        DispatcherQueue.TryEnqueue(UpdateLocalization);
    }

    private void OnViewModelPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        DispatcherQueue.TryEnqueue(UpdateState);
    }

    private void UpdateLocalization()
    {
        var loc = LocalizationManager.Instance;
        TitleText.Text = loc["auth_title"];
        SubtitleText.Text = loc["auth_subtitle"];
        DiscordButtonText.Text = ViewModel?.IsLoading == true ? loc["auth_logging_in"] : loc["auth_login_discord"];
        PasskeyButtonText.Text = loc["auth_login_passkey"];
        PasskeyNoticeText.Text = loc["auth_passkey_notice"];
        WebAuthModalTitle.Text = loc["auth_login_discord"];

        bool isFr = loc.CurrentLanguage == AppLanguage.Fr;
        FrButton.Background = isFr ? new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(0x33, 0xFF, 0xFF, 0xFF)) : new SolidColorBrush(Microsoft.UI.Colors.Transparent);
        EnButton.Background = !isFr ? new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(0x33, 0xFF, 0xFF, 0xFF)) : new SolidColorBrush(Microsoft.UI.Colors.Transparent);
    }

    private void UpdateState()
    {
        if (ViewModel == null) return;

        bool loading = ViewModel.IsLoading;
        DiscordButton.IsEnabled = !loading;
        PasskeyButton.IsEnabled = !loading;
        LoadingRing.IsActive = loading;
        LoadingRing.Visibility = loading ? Visibility.Visible : Visibility.Collapsed;

        if (!string.IsNullOrEmpty(ViewModel.ErrorMessage))
        {
            ErrorText.Text = ViewModel.ErrorMessage;
            ErrorBorder.Visibility = Visibility.Visible;
        }
        else
        {
            ErrorBorder.Visibility = Visibility.Collapsed;
        }

        var loc = LocalizationManager.Instance;
        DiscordButtonText.Text = loading ? loc["auth_logging_in"] : loc["auth_login_discord"];
    }

    private async void DiscordButton_Click(object sender, RoutedEventArgs e)
    {
        await StartDiscordWebAuthAsync();
    }

    private void PasskeyButton_Click(object sender, RoutedEventArgs e)
    {
        ViewModel?.LoginWithPasskey();
    }

    private void FrButton_Click(object sender, RoutedEventArgs e)
    {
        LocalizationManager.Instance.SetLanguage(AppLanguage.Fr);
    }

    private void EnButton_Click(object sender, RoutedEventArgs e)
    {
        LocalizationManager.Instance.SetLanguage(AppLanguage.En);
    }

    public async Task StartDiscordWebAuthAsync()
    {
        _isWebAuthCompleted = false;
        WebAuthModalTitle.Text = LocalizationManager.Instance["auth_login_discord"];
        WebAuthModalOverlay.Visibility = Visibility.Visible;
        WebAuthLoadingRing.IsActive = true;
        WebAuthLoadingRing.Visibility = Visibility.Visible;
        WebAuthWebView.Visibility = Visibility.Collapsed;

        try
        {
            if (!_isWebAuthInitialized)
            {
                string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
                string userDataFolder = Path.Combine(localAppData, "Overnode", "WebView2Profile");
                Directory.CreateDirectory(userDataFolder);
                Environment.SetEnvironmentVariable("WEBVIEW2_USER_DATA_FOLDER", userDataFolder);

                WebAuthWebView.DefaultBackgroundColor = ColorHelper.FromArgb(255, 16, 18, 24);

                await WebAuthWebView.EnsureCoreWebView2Async();

                var settings = WebAuthWebView.CoreWebView2.Settings;
                settings.AreDevToolsEnabled = false;
                settings.AreDefaultContextMenusEnabled = false;
                settings.IsStatusBarEnabled = false;

                WebAuthWebView.CoreWebView2.Settings.UserAgent =
                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 OvernodeWindowsNative/1.0";

                string script = @"
                (function() {
                    function injectStyles() {
                        const styleId = 'overnode-no-scroll';
                        if (document.getElementById(styleId)) return;
                        const style = document.createElement('style');
                        style.id = styleId;
                        style.innerHTML = '::-webkit-scrollbar { display: none !important; width: 0 !important; height: 0 !important; } html, body { scrollbar-width: none !important; -ms-overflow-style: none !important; overflow-x: hidden !important; }';
                        (document.head || document.documentElement).appendChild(style);
                    }
                    if (document.readyState === 'loading') {
                        document.addEventListener('DOMContentLoaded', injectStyles);
                    } else {
                        injectStyles();
                    }

                    let hasReported = false;
                    function checkAuthState() {
                        if (hasReported) return;

                        var path = window.location.pathname || '';
                        if (path.indexOf('2fa') !== -1) {
                            hasReported = true;
                            window.chrome.webview.postMessage(JSON.stringify({
                                authenticated: false,
                                twoFactorPending: true
                            }));
                            return;
                        }

                        fetch('/api/v5/state', { credentials: 'include' })
                            .then(r => r.ok ? r.json() : null)
                            .then(state => {
                                if (!state) return;
                                if (state.authenticated === true || state.twoFactorPending === true) {
                                    hasReported = true;
                                    window.chrome.webview.postMessage(JSON.stringify(state));
                                }
                            })
                            .catch(() => {});
                    }
                    setInterval(checkAuthState, 700);
                    checkAuthState();
                })();
                ";

                await WebAuthWebView.CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync(script);
                WebAuthWebView.CoreWebView2.WebMessageReceived += OnWebAuthWebMessageReceived;
                WebAuthWebView.CoreWebView2.SourceChanged += OnWebAuthSourceChanged;
                WebAuthWebView.NavigationCompleted += OnWebAuthNavigationCompleted;

                _isWebAuthInitialized = true;
            }

            WebAuthWebView.CoreWebView2.Navigate("https://console.overnode.fr/auth/discord/login");
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[AuthView] WebAuth init error: {ex.Message}");
            HideDiscordAuthModal();
            if (ViewModel != null)
            {
                await ViewModel.HandleDiscordAuthResultAsync(null);
            }
        }
    }

    private void WebAuthCloseButton_Click(object sender, RoutedEventArgs e)
    {
        try
        {
            WebAuthWebView.CoreWebView2?.Stop();
        }
        catch { }

        HideDiscordAuthModal();
    }

    public void HideDiscordAuthModal()
    {
        WebAuthModalOverlay.Visibility = Visibility.Collapsed;
        WebAuthLoadingRing.IsActive = false;
        WebAuthLoadingRing.Visibility = Visibility.Collapsed;
        WebAuthWebView.Visibility = Visibility.Collapsed;
    }

    private async void OnWebAuthSourceChanged(object? sender, CoreWebView2SourceChangedEventArgs e)
    {
        try
        {
            string url = WebAuthWebView.Source?.ToString() ?? "";
            if (url.Contains("/auth/2fa", StringComparison.OrdinalIgnoreCase) ||
                url.Contains("/2fa", StringComparison.OrdinalIgnoreCase))
            {
                if (_isWebAuthCompleted) return;
                _isWebAuthCompleted = true;

                await SyncCookiesFromWebViewAsync();
                HideDiscordAuthModal();

                if (ViewModel != null)
                {
                    await ViewModel.HandleDiscordAuthResultAsync(new AuthStateResponse
                    {
                        Authenticated = false,
                        TwoFactorPending = true
                    });
                }
            }
        }
        catch { }
    }

    private async void OnWebAuthNavigationCompleted(object? sender, CoreWebView2NavigationCompletedEventArgs e)
    {
        try
        {
            await WebAuthWebView.CoreWebView2.ExecuteScriptAsync(
                "const s = document.createElement('style'); s.innerHTML = '::-webkit-scrollbar { display: none !important; width: 0 !important; height: 0 !important; } html, body { scrollbar-width: none !important; -ms-overflow-style: none !important; overflow-x: hidden !important; }'; (document.head || document.documentElement).appendChild(s);"
            );
        }
        catch { }

        WebAuthLoadingRing.IsActive = false;
        WebAuthLoadingRing.Visibility = Visibility.Collapsed;
        WebAuthWebView.Visibility = Visibility.Visible;
    }

    private async void OnWebAuthWebMessageReceived(object? sender, CoreWebView2WebMessageReceivedEventArgs e)
    {
        try
        {
            string json = e.TryGetWebMessageAsString();
            if (string.IsNullOrEmpty(json)) return;

            var state = JsonSerializer.Deserialize<AuthStateResponse>(json, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            if (state != null && (state.Authenticated || state.TwoFactorPending == true))
            {
                if (_isWebAuthCompleted) return;
                _isWebAuthCompleted = true;

                await SyncCookiesFromWebViewAsync();
                HideDiscordAuthModal();

                if (ViewModel != null)
                {
                    await ViewModel.HandleDiscordAuthResultAsync(state);
                }
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[AuthView] Message error: {ex.Message}");
        }
    }

    private async Task SyncCookiesFromWebViewAsync()
    {
        try
        {
            if (WebAuthWebView.CoreWebView2 == null) return;
            var cookieManager = WebAuthWebView.CoreWebView2.CookieManager;
            var cookies = await cookieManager.GetCookiesAsync("https://console.overnode.fr");

            var netCookies = new List<Cookie>();
            foreach (var c in cookies)
            {
                string cleanDomain = c.Domain.TrimStart('.');
                var netCookie = new Cookie(c.Name, c.Value, c.Path, cleanDomain)
                {
                    Secure = c.IsSecure,
                    HttpOnly = c.IsHttpOnly,
                    Expires = c.Expires != 0 ? DateTimeOffset.FromUnixTimeSeconds((long)c.Expires).UtcDateTime : DateTime.UtcNow.AddDays(30)
                };

                try
                {
                    APIClient.Instance.CookieContainer.Add(APIClient.Instance.BaseUri, netCookie);
                }
                catch
                {
                    try
                    {
                        APIClient.Instance.CookieContainer.Add(netCookie);
                    }
                    catch { }
                }

                netCookies.Add(netCookie);
            }

            SessionPersistence.Instance.SaveCookies(netCookies);
            APIClient.Instance.PersistCurrentCookies();
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[AuthView] Cookie sync error: {ex.Message}");
        }
    }
}
