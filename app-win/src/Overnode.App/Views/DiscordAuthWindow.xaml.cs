using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Runtime.InteropServices;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI;
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.Web.WebView2.Core;
using Overnode.App.Models;
using Overnode.App.Services;

namespace Overnode.App.Views;

public sealed partial class DiscordAuthWindow : Window
{
    [DllImport("dwmapi.dll")]
    private static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);

    [DllImport("user32.dll")]
    private static extern uint GetDpiForWindow(IntPtr hWnd);

    private const int DWMWA_USE_IMMERSIVE_DARK_MODE = 20;

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

        // Enforce dark mode on window frame and title bar at OS level
        int useDarkMode = 1;
        DwmSetWindowAttribute(hWnd, DWMWA_USE_IMMERSIVE_DARK_MODE, ref useDarkMode, sizeof(int));

        var windowId = Win32Interop.GetWindowIdFromWindow(hWnd);
        var appWindow = AppWindow.GetFromWindowId(windowId);
        if (appWindow != null)
        {
            appWindow.Title = "Connexion Discord - Overnode";

            // DPI-aware sizing: 580x740 DIPs to fit Discord dialog comfortably without scrollbars
            uint dpi = GetDpiForWindow(hWnd);
            double scale = dpi > 0 ? (double)dpi / 96.0 : 1.0;
            int width = (int)Math.Round(580 * scale);
            int height = (int)Math.Round(740 * scale);

            appWindow.Resize(new Windows.Graphics.SizeInt32(width, height));
            appWindow.IsShownInSwitchers = true;

            // Match Overnode Dark Theme for TitleBar and system caption buttons (#101218)
            if (AppWindowTitleBar.IsCustomizationSupported())
            {
                var titleBar = appWindow.TitleBar;
                var bg = ColorHelper.FromArgb(255, 16, 18, 24);
                titleBar.BackgroundColor = bg;
                titleBar.ForegroundColor = Colors.White;
                titleBar.InactiveBackgroundColor = bg;
                titleBar.InactiveForegroundColor = ColorHelper.FromArgb(255, 149, 161, 173);
                titleBar.ButtonBackgroundColor = bg;
                titleBar.ButtonForegroundColor = Colors.White;
                titleBar.ButtonHoverBackgroundColor = ColorHelper.FromArgb(255, 32, 34, 41);
                titleBar.ButtonHoverForegroundColor = Colors.White;
                titleBar.ButtonPressedBackgroundColor = ColorHelper.FromArgb(255, 46, 51, 55);
                titleBar.ButtonPressedForegroundColor = Colors.White;
                titleBar.ButtonInactiveBackgroundColor = bg;
                titleBar.ButtonInactiveForegroundColor = ColorHelper.FromArgb(255, 102, 112, 125);
            }

            var iconPath = Path.Combine(AppContext.BaseDirectory, "Assets", "app_icon.png");
            if (File.Exists(iconPath))
            {
                appWindow.SetIcon(iconPath);
            }

            var displayArea = DisplayArea.GetFromWindowId(windowId, DisplayAreaFallback.Primary);
            if (displayArea != null)
            {
                var centeredPosition = appWindow.Position;
                centeredPosition.X = (displayArea.WorkArea.Width - width) / 2;
                centeredPosition.Y = (displayArea.WorkArea.Height - height) / 2;
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

            AuthWebView.DefaultBackgroundColor = ColorHelper.FromArgb(255, 16, 18, 24);

            await AuthWebView.EnsureCoreWebView2Async();

            var settings = AuthWebView.CoreWebView2.Settings;
            settings.AreDevToolsEnabled = false;
            settings.AreDefaultContextMenusEnabled = false;
            settings.IsStatusBarEnabled = false;

            AuthWebView.CoreWebView2.Settings.UserAgent =
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 OvernodeWindowsNative/1.0";

            // Injected script to suppress scrollbars and observe login state
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

            await AuthWebView.CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync(script);
            AuthWebView.CoreWebView2.WebMessageReceived += OnWebMessageReceived;
            AuthWebView.CoreWebView2.SourceChanged += OnSourceChanged;
            AuthWebView.NavigationCompleted += OnNavigationCompleted;

            AuthWebView.CoreWebView2.Navigate("https://console.overnode.fr/auth/discord/login");
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[DiscordAuthWindow] Init error: {ex.Message}");
            CompleteAuth(null);
        }
    }

    private async void OnSourceChanged(object? sender, CoreWebView2SourceChangedEventArgs e)
    {
        try
        {
            string url = AuthWebView.Source?.ToString() ?? "";
            if (url.Contains("/auth/2fa", StringComparison.OrdinalIgnoreCase) ||
                url.Contains("/2fa", StringComparison.OrdinalIgnoreCase))
            {
                await SyncCookiesFromWebViewAsync();
                CompleteAuth(new AuthStateResponse
                {
                    Authenticated = false,
                    TwoFactorPending = true
                });
            }
        }
        catch { }
    }

    private async void OnNavigationCompleted(object? sender, CoreWebView2NavigationCompletedEventArgs e)
    {
        try
        {
            await AuthWebView.CoreWebView2.ExecuteScriptAsync(
                "const s = document.createElement('style'); s.innerHTML = '::-webkit-scrollbar { display: none !important; width: 0 !important; height: 0 !important; } html, body { scrollbar-width: none !important; -ms-overflow-style: none !important; overflow-x: hidden !important; }'; (document.head || document.documentElement).appendChild(s);"
            );
        }
        catch { }

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

    private void OnWindowClosed(object sender, WindowEventArgs args)
    {
        if (!_isCompleted)
        {
            _isCompleted = true;
            _tcs.TrySetResult(null);
        }
    }
}
