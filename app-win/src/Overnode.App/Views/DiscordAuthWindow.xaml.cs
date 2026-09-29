using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.Web.WebView2.Core;
using Overnode.App.Models;
using Overnode.App.Services;

namespace Overnode.App.Views;

public sealed partial class DiscordAuthWindow : Window
{
    private readonly TaskCompletionSource<AuthStateResponse?> _tcs = new();
    private bool _isCompleted = false;

    public Task<AuthStateResponse?> AuthTask => _tcs.Task;

    public DiscordAuthWindow()
    {
        InitializeComponent();
        ConfigureWindow();
        Closed += OnWindowClosed;
        _ = InitializeWebViewAsync();
    }

    private void ConfigureWindow()
    {
        var hWnd = WinRT.Interop.WindowNative.GetWindowHandle(this);
        var windowId = Microsoft.UI.Win32Interop.GetWindowIdFromWindow(hWnd);
        var appWindow = Microsoft.UI.Windowing.AppWindow.GetFromWindowId(windowId);
        if (appWindow != null)
        {
            appWindow.Resize(new Windows.Graphics.SizeInt32(650, 750));
            var displayArea = Microsoft.UI.Windowing.DisplayArea.GetFromWindowId(windowId, Microsoft.UI.Windowing.DisplayAreaFallback.Primary);
            if (displayArea != null)
            {
                var centeredPosition = appWindow.Position;
                centeredPosition.X = (displayArea.WorkArea.Width - 650) / 2;
                centeredPosition.Y = (displayArea.WorkArea.Height - 750) / 2;
                appWindow.Move(centeredPosition);
            }
        }
    }

    private async Task InitializeWebViewAsync()
    {
        try
        {
            string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            string userDataFolder = Path.Combine(localAppData, "Overnode", "WebView2Profile");
            Directory.CreateDirectory(userDataFolder);
            Environment.SetEnvironmentVariable("WEBVIEW2_USER_DATA_FOLDER", userDataFolder);

            await AuthWebView.EnsureCoreWebView2Async();

            var settings = AuthWebView.CoreWebView2.Settings;
            settings.AreDevToolsEnabled = false;
            settings.AreDefaultContextMenusEnabled = false;
            settings.IsStatusBarEnabled = false;

            AuthWebView.CoreWebView2.Settings.UserAgent =
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 OvernodeWindowsNative/1.0";

            // Injected observer script
            string script = @"
            (function() {
                let hasReported = false;
                function checkAuthState() {
                    if (hasReported) return;
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

            await AuthWebView.CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync(script);
            AuthWebView.CoreWebView2.WebMessageReceived += OnWebMessageReceived;
            AuthWebView.NavigationCompleted += OnNavigationCompleted;

            AuthWebView.CoreWebView2.Navigate("https://console.overnode.fr/auth/discord/login");
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[DiscordAuthWindow] Init error: {ex.Message}");
            CompleteAuth(null);
        }
    }

    private void OnNavigationCompleted(object? sender, CoreWebView2NavigationCompletedEventArgs e)
    {
        LoadingRing.IsActive = false;
        LoadingRing.Visibility = Visibility.Collapsed;
        AuthWebView.Visibility = Visibility.Visible;
    }

    private async void OnWebMessageReceived(object? sender, CoreWebView2WebMessageReceivedEventArgs e)
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
                await SyncCookiesFromWebViewAsync();
                CompleteAuth(state);
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[DiscordAuthWindow] Message error: {ex.Message}");
        }
    }

    private async Task SyncCookiesFromWebViewAsync()
    {
        try
        {
            var cookieManager = AuthWebView.CoreWebView2.CookieManager;
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
                catch { }

                netCookies.Add(netCookie);
            }

            SessionPersistence.Instance.SaveCookies(netCookies);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[DiscordAuthWindow] Cookie sync error: {ex.Message}");
        }
    }

    private void CompleteAuth(AuthStateResponse? state)
    {
        if (_isCompleted) return;
        _isCompleted = true;
        _tcs.TrySetResult(state);
        Close();
    }

    private void CloseButton_Click(object sender, RoutedEventArgs e)
    {
        CompleteAuth(null);
    }

    private void OnWindowClosed(object sender, WindowEventArgs args)
    {
        if (!_isCompleted)
        {
            _isCompleted = true;
            _tcs.TrySetResult(null);
        }
    }
}
