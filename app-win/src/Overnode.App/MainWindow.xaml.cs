using System;
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;
using Microsoft.UI;
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Media.Imaging;
using Windows.Graphics;
using Windows.Graphics.Imaging;
using Windows.Storage.Streams;
using Overnode.App.ViewModels;

namespace Overnode.App;

public sealed partial class MainWindow : Window
{
    [DllImport("user32.dll")]
    private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    private static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("dwmapi.dll")]
    private static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);

    [DllImport("user32.dll")]
    private static extern uint GetDpiForWindow(IntPtr hWnd);

    private const int DWMWA_USE_IMMERSIVE_DARK_MODE = 20;

    private static readonly string LogPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.Desktop),
        "overnode_crash.log");

    private readonly Views.AuthView _authView = new();
    private readonly Views.TwoFactorVerificationView _twoFactorView = new();
    private readonly Views.DashboardView _dashboardView = new();

    public AuthViewModel AuthVM { get; }

    public MainWindow()
    {
        InitializeComponent();

        try
        {
            SystemBackdrop = new Microsoft.UI.Xaml.Media.MicaBackdrop();
        }
        catch { }

        AuthVM = new AuthViewModel();
        AuthVM.PropertyChanged += OnAuthVMPropertyChanged;

        _authView.Initialize(AuthVM);
        _twoFactorView.Initialize(AuthVM.TwoFactorVM);
        _dashboardView.AuthVM = AuthVM;

        RootGrid.Children.Add(_authView);
        RootGrid.Children.Add(_twoFactorView);
        RootGrid.Children.Add(_dashboardView);

        UpdateActiveView();
        ConfigureWindow();

        if (Environment.GetEnvironmentVariable("OVERNODE_CAPTURE_SCREEN") == "1")
        {
            _ = System.Threading.Tasks.Task.Run(() =>
            {
                DispatcherQueue.TryEnqueue(CaptureScreenshotAsync);
            });
        }
    }

    private void OnAuthVMPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        DispatcherQueue.TryEnqueue(UpdateActiveView);
    }

    private void UpdateActiveView()
    {
        if (AuthVM.IsAuthenticated)
        {
            _authView.Visibility = Visibility.Collapsed;
            _twoFactorView.Visibility = Visibility.Collapsed;
            _dashboardView.Visibility = Visibility.Visible;
        }
        else if (AuthVM.IsTwoFactorPending)
        {
            _authView.Visibility = Visibility.Collapsed;
            _twoFactorView.Visibility = Visibility.Visible;
            _dashboardView.Visibility = Visibility.Collapsed;
        }
        else
        {
            _authView.Visibility = Visibility.Visible;
            _twoFactorView.Visibility = Visibility.Collapsed;
            _dashboardView.Visibility = Visibility.Collapsed;
        }
    }

    public const int DefaultDipWidth = 1180;
    public const int DefaultDipHeight = 780;

    private void ConfigureWindow()
    {
        try
        {
            var hWnd = WinRT.Interop.WindowNative.GetWindowHandle(this);
            int useDarkMode = 1;
            DwmSetWindowAttribute(hWnd, DWMWA_USE_IMMERSIVE_DARK_MODE, ref useDarkMode, sizeof(int));

            File.AppendAllText(LogPath, $"[{DateTime.Now}] ConfigureWindow: hWnd = 0x{hWnd.ToInt64():X}\n");
            var windowId = Win32Interop.GetWindowIdFromWindow(hWnd);
            File.AppendAllText(LogPath, $"[{DateTime.Now}] ConfigureWindow: windowId = {windowId.Value}\n");
            var appWindow = AppWindow.GetFromWindowId(windowId);
            File.AppendAllText(LogPath, $"[{DateTime.Now}] ConfigureWindow: appWindow is {(appWindow != null ? "not null" : "null")}\n");
            if (appWindow != null)
            {
                appWindow.Title = "Overnode";

                // DPI-aware sizing: 1180x780 DIPs
                uint dpi = GetDpiForWindow(hWnd);
                double scale = dpi > 0 ? (double)dpi / 96.0 : 1.0;
                int physWidth = (int)Math.Round(DefaultDipWidth * scale);
                int physHeight = (int)Math.Round(DefaultDipHeight * scale);

                appWindow.Resize(new SizeInt32(physWidth, physHeight));
                appWindow.IsShownInSwitchers = true;

                // Match Overnode Dark Theme for TitleBar and system buttons
                if (AppWindowTitleBar.IsCustomizationSupported())
                {
                    var titleBar = appWindow.TitleBar;
                    titleBar.BackgroundColor = ColorHelper.FromArgb(255, 16, 18, 24);
                    titleBar.ForegroundColor = Colors.White;
                    titleBar.InactiveBackgroundColor = ColorHelper.FromArgb(255, 16, 18, 24);
                    titleBar.InactiveForegroundColor = ColorHelper.FromArgb(255, 149, 161, 173);
                    titleBar.ButtonBackgroundColor = ColorHelper.FromArgb(255, 16, 18, 24);
                    titleBar.ButtonForegroundColor = Colors.White;
                    titleBar.ButtonHoverBackgroundColor = ColorHelper.FromArgb(255, 32, 34, 41);
                    titleBar.ButtonHoverForegroundColor = Colors.White;
                    titleBar.ButtonPressedBackgroundColor = ColorHelper.FromArgb(255, 46, 51, 55);
                    titleBar.ButtonPressedForegroundColor = Colors.White;
                    titleBar.ButtonInactiveBackgroundColor = ColorHelper.FromArgb(255, 16, 18, 24);
                    titleBar.ButtonInactiveForegroundColor = ColorHelper.FromArgb(255, 102, 112, 125);
                }

                var displayArea = DisplayArea.GetFromWindowId(windowId, DisplayAreaFallback.Primary);
                if (displayArea != null)
                {
                    var centeredX = (displayArea.WorkArea.Width - physWidth) / 2;
                    var centeredY = (displayArea.WorkArea.Height - physHeight) / 2;
                    appWindow.Move(new PointInt32(centeredX, centeredY));
                    File.AppendAllText(LogPath, $"[{DateTime.Now}] Centered at {centeredX}, {centeredY}\n");
                }

                var iconPath = Path.Combine(AppContext.BaseDirectory, "Assets", "app_icon.png");
                if (File.Exists(iconPath))
                {
                    appWindow.SetIcon(iconPath);
                }

                appWindow.Show(true);
                File.AppendAllText(LogPath, $"[{DateTime.Now}] appWindow.Show(true) called, isVisible={appWindow.IsVisible}\n");
            }
            ShowWindow(hWnd, 5);
            SetForegroundWindow(hWnd);
            File.AppendAllText(LogPath, $"[{DateTime.Now}] Win32 ShowWindow and SetForegroundWindow called\n");
        }
        catch (Exception ex)
        {
            File.AppendAllText(LogPath, $"[{DateTime.Now}] Exception in ConfigureWindow: {ex}\n");
        }
    }

    private async void CaptureScreenshotAsync()
    {
        try
        {
            await System.Threading.Tasks.Task.Delay(1500);
            if (Content is FrameworkElement root)
            {
                var rtb = new RenderTargetBitmap();
                await rtb.RenderAsync(root);
                var pixelBuffer = await rtb.GetPixelsAsync();

                string artifactDir = @"C:\Users\jesui\.gemini\antigravity\brain\e8a1065e-c266-4499-80b2-6f1938130351";
                string filePath = Path.Combine(artifactDir, "overnode_window.png");

                using var fileStream = File.Create(filePath);
                var memStream = new InMemoryRandomAccessStream();
                var encoder = await BitmapEncoder.CreateAsync(BitmapEncoder.PngEncoderId, memStream);

                var reader = DataReader.FromBuffer(pixelBuffer);
                byte[] pixels = new byte[pixelBuffer.Length];
                reader.ReadBytes(pixels);

                encoder.SetPixelData(
                    BitmapPixelFormat.Bgra8,
                    BitmapAlphaMode.Premultiplied,
                    (uint)rtb.PixelWidth,
                    (uint)rtb.PixelHeight,
                    96,
                    96,
                    pixels);
                await encoder.FlushAsync();
                memStream.Seek(0);
                using (var readStream = memStream.AsStreamForRead())
                {
                    await readStream.CopyToAsync(fileStream);
                }

                File.AppendAllText(LogPath, $"[{DateTime.Now}] Window screenshot saved: {filePath} ({rtb.PixelWidth}x{rtb.PixelHeight})\n");
            }
        }
        catch (Exception ex)
        {
            File.AppendAllText(LogPath, $"[{DateTime.Now}] Screenshot capture error: {ex}\n");
        }
    }
}

