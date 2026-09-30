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

    private readonly Views.AuthView _authView = new();
    private readonly Views.TwoFactorVerificationView _twoFactorView = new();
    private readonly Views.DashboardView _dashboardView = new();
    private readonly Views.Components.UpdateModalControl _updateModal = new();

    public AuthViewModel AuthVM { get; }
    public UpdateViewModel UpdateVM => UpdateViewModel.Shared;

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
        _updateModal.Initialize(UpdateVM);

        RootGrid.Children.Add(_authView);
        RootGrid.Children.Add(_twoFactorView);
        RootGrid.Children.Add(_dashboardView);
        RootGrid.Children.Add(_updateModal);

        UpdateActiveView();
        ConfigureWindow();

        // Silent background update check on startup
        _ = System.Threading.Tasks.Task.Run(() => UpdateVM.CheckForUpdatesAsync(silent: true));

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

            var windowId = Win32Interop.GetWindowIdFromWindow(hWnd);
            var appWindow = AppWindow.GetFromWindowId(windowId);
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
                }

                var iconPath = Path.Combine(AppContext.BaseDirectory, "Assets", "app_icon.ico");
                if (!File.Exists(iconPath))
                {
                    iconPath = Path.Combine(AppContext.BaseDirectory, "Assets", "app_icon.png");
                }
                if (File.Exists(iconPath))
                {
                    appWindow.SetIcon(iconPath);
                }

                appWindow.Show(true);
            }
            ShowWindow(hWnd, 5);
            SetForegroundWindow(hWnd);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[{DateTime.Now}] Exception in ConfigureWindow: {ex}");
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

                string filePath = Environment.GetEnvironmentVariable("OVERNODE_SCREENSHOT_PATH")
                    ?? @"C:\Users\jesui\.gemini\antigravity\brain\849e978a-0067-4dda-91bc-fea6fbc03247\screenshot.png";
                string? dir = Path.GetDirectoryName(filePath);
                if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);

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

                System.Diagnostics.Debug.WriteLine($"[{DateTime.Now}] Window screenshot saved: {filePath} ({rtb.PixelWidth}x{rtb.PixelHeight})");
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[{DateTime.Now}] Screenshot capture error: {ex}");
        }
    }
}

