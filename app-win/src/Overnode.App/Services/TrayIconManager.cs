using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using Overnode.App.Localization;
using Overnode.App.Models;

namespace Overnode.App.Services;

/// <summary>
/// Abstraction for window management invoked by the tray menu.
/// </summary>
public interface ITrayTarget
{
    IntPtr GetWindowHandle();
    void RestoreWindow();
    void NavigateToSettings();
    void QuitApplication();
    void EnqueueOnUIThread(Action action);
}

/// <summary>
/// Manages the Windows notification area (System Tray) icon and Quick Actions context menu,
/// providing parity with macOS MenuBarManager.
/// </summary>
public sealed class TrayIconManager : IDisposable
{
    private static readonly Lazy<TrayIconManager> _instance = new(() => new TrayIconManager());
    public static TrayIconManager Shared => _instance.Value;
    public static TrayIconManager Instance => _instance.Value;

    // --- Win32 Constants ---
    private const uint NIM_ADD = 0x00000000;
    private const uint NIM_MODIFY = 0x00000001;
    private const uint NIM_DELETE = 0x00000002;
    private const uint NIM_SETVERSION = 0x00000004;

    private const uint NIF_MESSAGE = 0x00000001;
    private const uint NIF_ICON = 0x00000002;
    private const uint NIF_TIP = 0x00000004;
    private const uint NIF_SHOWTIP = 0x00000080;

    private const uint NOTIFYICON_VERSION_4 = 4;

    private const uint WM_USER = 0x0400;
    private const uint WM_APP = 0x8000;
    private const uint WM_TRAY_CALLBACK = WM_APP + 100;
    private const uint WM_COMMAND = 0x0111;
    private const uint WM_NULL = 0x0000;

    private const uint WM_LBUTTONUP = 0x0202;
    private const uint WM_LBUTTONDBLCLK = 0x0203;
    private const uint WM_RBUTTONUP = 0x0205;
    private const uint WM_CONTEXTMENU = 0x007B;

    private const uint MF_STRING = 0x00000000;
    private const uint MF_GRAYED = 0x00000001;
    private const uint MF_DISABLED = 0x00000002;
    private const uint MF_ENABLED = 0x00000000;
    private const uint MF_SEPARATOR = 0x00000800;

    private const uint TPM_RETURNCMD = 0x0100;
    private const uint TPM_RIGHTBUTTON = 0x0002;
    private const uint TPM_LEFTBUTTON = 0x0000;

    private const uint IMAGE_ICON = 1;
    private const uint LR_LOADFROMFILE = 0x00000010;
    private const int SM_CXSMICON = 49;
    private const int SM_CYSMICON = 50;

    private const int MB_YESNO = 0x00000004;
    private const int MB_ICONWARNING = 0x00000030;
    private const int MB_DEFBUTTON2 = 0x00000100;
    private const int MB_SETFOREGROUND = 0x00010000;
    private const int IDYES = 6;

    private const uint TRAY_ICON_UID = 1001;
    private const uint SUBCLASS_ID = 2001;

    // Menu Command IDs
    public const int CMD_TITLE = 1000;
    public const int CMD_SERVER_INFO = 1001;
    public const int CMD_SERVER_STATS = 1002;
    public const int CMD_START = 1010;
    public const int CMD_STOP = 1011;
    public const int CMD_RESTART = 1012;
    public const int CMD_KILL = 1013;
    public const int CMD_NO_SERVER = 1020;
    public const int CMD_SETTINGS = 1021;
    public const int CMD_OPEN = 1030;
    public const int CMD_QUIT = 1031;

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct NOTIFYICONDATAW
    {
        public uint cbSize;
        public IntPtr hWnd;
        public uint uID;
        public uint uFlags;
        public uint uCallbackMessage;
        public IntPtr hIcon;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string szTip;
        public uint dwState;
        public uint dwStateMask;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
        public string szInfo;
        public uint uTimeoutOrVersion;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 64)]
        public string szInfoTitle;
        public uint dwInfoFlags;
        public Guid guidItem;
        public IntPtr hBalloonIcon;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct POINT
    {
        public int X;
        public int Y;
    }

    private delegate IntPtr SubclassProc(IntPtr hWnd, uint uMsg, IntPtr wParam, IntPtr lParam, UIntPtr uIdSubclass, IntPtr dwRefData);

    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    private static extern bool Shell_NotifyIconW(uint dwMessage, ref NOTIFYICONDATAW lpData);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    private static extern IntPtr LoadImageW(IntPtr hinst, string lpszName, uint uType, int cxDesired, int cyDesired, uint fuLoad);

    [DllImport("user32.dll")]
    private static extern bool DestroyIcon(IntPtr hIcon);

    [DllImport("user32.dll")]
    private static extern int GetSystemMetrics(int nIndex);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern IntPtr CreatePopupMenu();

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern bool AppendMenuW(IntPtr hMenu, uint uFlags, UIntPtr uIDNewItem, string lpNewItem);

    [DllImport("user32.dll")]
    private static extern bool DestroyMenu(IntPtr hMenu);

    [DllImport("user32.dll")]
    private static extern bool GetCursorPos(out POINT lpPoint);

    [DllImport("user32.dll")]
    private static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern int TrackPopupMenuEx(IntPtr hMenu, uint uFlags, int x, int y, IntPtr hWnd, IntPtr lpTPMParams);

    [DllImport("user32.dll")]
    private static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern uint RegisterWindowMessageW(string lpString);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int MessageBoxW(IntPtr hWnd, string lpText, string lpCaption, uint uType);

    [DllImport("comctl32.dll")]
    private static extern bool SetWindowSubclass(IntPtr hWnd, SubclassProc pfnSubclass, UIntPtr uIdSubclass, IntPtr dwRefData);

    [DllImport("comctl32.dll")]
    private static extern IntPtr DefSubclassProc(IntPtr hWnd, uint uMsg, IntPtr wParam, IntPtr lParam);

    [DllImport("comctl32.dll")]
    private static extern bool RemoveWindowSubclass(IntPtr hWnd, SubclassProc pfnSubclass, UIntPtr uIdSubclass);

    [DllImport("uxtheme.dll", EntryPoint = "#135", SetLastError = true)]
    private static extern int SetPreferredAppMode(int appMode);

    [DllImport("uxtheme.dll", EntryPoint = "#133", SetLastError = true)]
    private static extern bool AllowDarkModeForWindow(IntPtr hWnd, bool allow);

    // --- State fields ---
    private readonly object _lock = new();
    private readonly List<ServerInstance> _cachedServers = new();
    private ServerInstance? _activeServer;
    private bool _isPerformingAction;
    private bool _isInitialized;
    private bool _disposed;

    private IntPtr _hWnd = IntPtr.Zero;
    private IntPtr _hIcon = IntPtr.Zero;
    private SubclassProc? _subclassProc;
    private uint _taskbarCreatedMsg;
    private ITrayTarget? _trayTarget;

    private System.Threading.Timer? _periodicRefreshTimer;
    private readonly LocalizationManager _loc = LocalizationManager.Instance;

    public ServerInstance? ActiveServer => _activeServer;
    public bool IsPerformingAction => _isPerformingAction;
    public bool IsInitialized => _isInitialized;

    private TrayIconManager()
    {
        QuickActionServerStorage.Shared.DidChange += OnQuickActionServerChanged;
        _loc.PropertyChanged += (s, e) => UpdateTooltip();
    }

    public void Initialize(ITrayTarget target)
    {
        if (_isInitialized || _disposed) return;
        _trayTarget = target;

        try
        {
            _hWnd = target.GetWindowHandle();
            if (_hWnd == IntPtr.Zero) return;

            // Enable Windows 11 Dark Mode styling for popup menus
            try
            {
                SetPreferredAppMode(2); // ForceDark
                AllowDarkModeForWindow(_hWnd, true);
            }
            catch { }

            _taskbarCreatedMsg = RegisterWindowMessageW("TaskbarCreated");

            // Setup subclass for window procedure
            _subclassProc = new SubclassProc(WndProcSubclass);
            SetWindowSubclass(_hWnd, _subclassProc, (UIntPtr)SUBCLASS_ID, IntPtr.Zero);

            AddTrayIcon();

            RefreshSelectedServer();

            // Periodic live state refresh (every 15 seconds)
            _periodicRefreshTimer = new System.Threading.Timer(_ =>
            {
                _ = RefreshActiveServerLiveStateAsync();
            }, null, TimeSpan.FromSeconds(15), TimeSpan.FromSeconds(15));

            _isInitialized = true;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[TrayIconManager] Initialization error: {ex}");
        }
    }

    public void AddTrayIcon()
    {
        if (_hWnd == IntPtr.Zero) return;

        try
        {
            if (_hIcon != IntPtr.Zero)
            {
                DestroyIcon(_hIcon);
                _hIcon = IntPtr.Zero;
            }

            _hIcon = LoadTrayIcon();

            var nid = new NOTIFYICONDATAW
            {
                cbSize = (uint)Marshal.SizeOf<NOTIFYICONDATAW>(),
                hWnd = _hWnd,
                uID = TRAY_ICON_UID,
                uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP | NIF_SHOWTIP,
                uCallbackMessage = WM_TRAY_CALLBACK,
                hIcon = _hIcon,
                szTip = BuildTooltipText()
            };

            Shell_NotifyIconW(NIM_ADD, ref nid);

            // Set version to NOTIFYICON_VERSION_4 for modern Windows message semantics
            nid.uTimeoutOrVersion = NOTIFYICON_VERSION_4;
            Shell_NotifyIconW(NIM_SETVERSION, ref nid);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[TrayIconManager] AddTrayIcon error: {ex.Message}");
        }
    }

    private IntPtr LoadTrayIcon()
    {
        // 1. Prefer custom silhouette icon: transparent cloud without background
        string iconPath = Path.Combine(AppContext.BaseDirectory, "Assets", "statusbar_icon.ico");
        if (!File.Exists(iconPath))
        {
            iconPath = Path.Combine(AppContext.BaseDirectory, "Assets", "app_icon.ico");
        }

        if (File.Exists(iconPath))
        {
            int cx = GetSystemMetrics(SM_CXSMICON);
            int cy = GetSystemMetrics(SM_CYSMICON);
            IntPtr h = LoadImageW(IntPtr.Zero, iconPath, IMAGE_ICON, cx, cy, LR_LOADFROMFILE);
            if (h != IntPtr.Zero) return h;
        }

        return IntPtr.Zero;
    }

    public void UpdateServers(IEnumerable<ServerInstance> servers)
    {
        lock (_lock)
        {
            _cachedServers.Clear();
            _cachedServers.AddRange(servers);
            RefreshSelectedServer();
        }
    }

    private void OnQuickActionServerChanged(object? sender, EventArgs e)
    {
        lock (_lock)
        {
            RefreshSelectedServer();
        }
    }

    public void RefreshSelectedServer()
    {
        string? selectedId = QuickActionServerStorage.Shared.GetSelectedServerIdentifier();
        if (!string.IsNullOrWhiteSpace(selectedId))
        {
            _activeServer = _cachedServers.FirstOrDefault(s =>
                string.Equals(s.Identifier, selectedId, StringComparison.OrdinalIgnoreCase) ||
                s.Id.ToString() == selectedId);
        }
        else
        {
            _activeServer = null;
        }

        UpdateTooltip();
    }

    public string BuildTooltipText()
    {
        if (_activeServer != null)
        {
            string statusStr = LocalizedServerState(_activeServer.State);
            string full = $"Overnode - {_activeServer.Name} ({statusStr})";
            return full.Length > 127 ? full.Substring(0, 127) : full;
        }
        return "Overnode - Quick Actions";
    }

    public void UpdateTooltip()
    {
        if (_hWnd == IntPtr.Zero) return;

        try
        {
            var nid = new NOTIFYICONDATAW
            {
                cbSize = (uint)Marshal.SizeOf<NOTIFYICONDATAW>(),
                hWnd = _hWnd,
                uID = TRAY_ICON_UID,
                uFlags = NIF_TIP | NIF_SHOWTIP,
                szTip = BuildTooltipText()
            };

            Shell_NotifyIconW(NIM_MODIFY, ref nid);
        }
        catch { }
    }

    public async Task RefreshActiveServerLiveStateAsync()
    {
        ServerInstance? srv;
        lock (_lock)
        {
            srv = _activeServer;
        }

        if (srv == null || string.IsNullOrWhiteSpace(srv.Identifier)) return;

        try
        {
            var live = await ServerService.Shared.FetchLiveResourcesAsync(srv.Identifier, srv.Id);
            if (live != null)
            {
                lock (_lock)
                {
                    if (_activeServer != null && _activeServer.Identifier == srv.Identifier)
                    {
                        _activeServer.State = live.Value.state;
                        _activeServer.MemoryUsedMB = live.Value.memoryMB;
                        _activeServer.CpuUsedPercent = live.Value.cpuPercent;
                        _activeServer.DiskUsedMB = live.Value.diskMB;
                    }
                }
                UpdateTooltip();
            }
        }
        catch
        {
            // Silently maintain last known state
        }
    }

    private IntPtr WndProcSubclass(IntPtr hWnd, uint uMsg, IntPtr wParam, IntPtr lParam, UIntPtr uIdSubclass, IntPtr dwRefData)
    {
        if (uMsg == WM_TRAY_CALLBACK)
        {
            uint mouseMsg = unchecked((uint)lParam.ToInt64() & 0xFFFF);
            switch (mouseMsg)
            {
                case WM_LBUTTONDBLCLK:
                    // Double click restores the main window
                    _trayTarget?.EnqueueOnUIThread(() => _trayTarget.RestoreWindow());
                    return IntPtr.Zero;

                case WM_LBUTTONUP:
                case WM_RBUTTONUP:
                case WM_CONTEXTMENU:
                    // Single left-click or right-click shows modern quick actions menu
                    ShowContextMenu();
                    return IntPtr.Zero;
            }
        }
        else if (_taskbarCreatedMsg != 0 && uMsg == _taskbarCreatedMsg)
        {
            // Explorer restarted, recreate the icon
            AddTrayIcon();
            return IntPtr.Zero;
        }

        return DefSubclassProc(hWnd, uMsg, wParam, lParam);
    }

    public void ShowContextMenu()
    {
        if (_hWnd == IntPtr.Zero) return;

        IntPtr hMenu = CreatePopupMenu();
        if (hMenu == IntPtr.Zero) return;

        try
        {
            // 1. Header
            AppendMenuW(hMenu, MF_STRING | MF_DISABLED | MF_GRAYED, (UIntPtr)CMD_TITLE, "Overnode");
            AppendMenuW(hMenu, MF_SEPARATOR, (UIntPtr)0, string.Empty);

            ServerInstance? srv;
            bool isPerforming;
            lock (_lock)
            {
                srv = _activeServer;
                isPerforming = _isPerformingAction;
            }

            // 2. Server Details or Fallback
            if (srv != null)
            {
                string statusStr = LocalizedServerState(srv.State);
                bool isRunning = string.Equals(srv.State, "running", StringComparison.OrdinalIgnoreCase);
                string stateDot = isRunning ? "● " : "○ ";

                AppendMenuW(hMenu, MF_STRING | MF_DISABLED | MF_GRAYED, (UIntPtr)CMD_SERVER_INFO, $"{stateDot}{srv.Name} ({statusStr})");

                string memUsed = $"{srv.MemoryUsedMB:F0}";
                string memLimit = $"{(int)srv.MemoryLimitMB}";
                string cpuUsed = $"{(int)srv.CpuUsedPercent}";
                AppendMenuW(hMenu, MF_STRING | MF_DISABLED | MF_GRAYED, (UIntPtr)CMD_SERVER_STATS, $"CPU: {cpuUsed}%   RAM: {memUsed}/{memLimit} MB");

                AppendMenuW(hMenu, MF_SEPARATOR, (UIntPtr)0, string.Empty);

                // Start Server
                uint startFlags = MF_STRING | ((!isPerforming && !isRunning) ? MF_ENABLED : (MF_DISABLED | MF_GRAYED));
                AppendMenuW(hMenu, startFlags, (UIntPtr)CMD_START, $"▶  {_loc.GetString("menubar_action_start")}");

                // Stop Server
                uint stopFlags = MF_STRING | ((!isPerforming && isRunning) ? MF_ENABLED : (MF_DISABLED | MF_GRAYED));
                AppendMenuW(hMenu, stopFlags, (UIntPtr)CMD_STOP, $"■  {_loc.GetString("menubar_action_stop")}");

                // Restart Server
                uint restartFlags = MF_STRING | (!isPerforming ? MF_ENABLED : (MF_DISABLED | MF_GRAYED));
                AppendMenuW(hMenu, restartFlags, (UIntPtr)CMD_RESTART, $"↺  {_loc.GetString("menubar_action_restart")}");

                // Force Kill Server
                uint killFlags = MF_STRING | (!isPerforming ? MF_ENABLED : (MF_DISABLED | MF_GRAYED));
                AppendMenuW(hMenu, killFlags, (UIntPtr)CMD_KILL, $"⚡ {_loc.GetString("menubar_action_kill")}");
            }
            else
            {
                AppendMenuW(hMenu, MF_STRING | MF_DISABLED | MF_GRAYED, (UIntPtr)CMD_NO_SERVER, _loc.GetString("menubar_no_server_configured"));
                AppendMenuW(hMenu, MF_STRING | MF_ENABLED, (UIntPtr)CMD_SETTINGS, $"⚙  {_loc.GetString("menubar_open_settings")}");
            }

            AppendMenuW(hMenu, MF_SEPARATOR, (UIntPtr)0, string.Empty);

            // 3. Application Actions
            AppendMenuW(hMenu, MF_STRING | MF_ENABLED, (UIntPtr)CMD_OPEN, $"🖥  {_loc.GetString("menubar_open_app")}");
            AppendMenuW(hMenu, MF_STRING | MF_ENABLED, (UIntPtr)CMD_QUIT, $"✕  {_loc.GetString("menubar_quit")}");

            SetForegroundWindow(_hWnd);
            GetCursorPos(out POINT pt);

            int cmd = TrackPopupMenuEx(hMenu, TPM_RETURNCMD | TPM_RIGHTBUTTON | TPM_LEFTBUTTON, pt.X, pt.Y, _hWnd, IntPtr.Zero);
            PostMessage(_hWnd, WM_NULL, IntPtr.Zero, IntPtr.Zero);

            HandleMenuCommand(cmd);
        }
        finally
        {
            DestroyMenu(hMenu);
        }
    }

    public void HandleMenuCommand(int cmd)
    {
        switch (cmd)
        {
            case CMD_START:
                TriggerPowerSignal(ServerPowerSignal.Start);
                break;
            case CMD_STOP:
                TriggerPowerSignal(ServerPowerSignal.Stop);
                break;
            case CMD_RESTART:
                TriggerPowerSignal(ServerPowerSignal.Restart);
                break;
            case CMD_KILL:
                HandleKillAction();
                break;
            case CMD_SETTINGS:
                _trayTarget?.EnqueueOnUIThread(() => _trayTarget.NavigateToSettings());
                break;
            case CMD_OPEN:
                _trayTarget?.EnqueueOnUIThread(() => _trayTarget.RestoreWindow());
                break;
            case CMD_QUIT:
                _trayTarget?.EnqueueOnUIThread(() => _trayTarget.QuitApplication());
                break;
        }
    }

    private void HandleKillAction()
    {
        string title = _loc.GetString("power_kill_confirm_title") ?? "Confirmation";
        string msg = _loc.GetString("menubar_action_kill_confirm") ?? "Êtes-vous sûr de vouloir forcer l'arrêt immédiat ?";

        int result = MessageBoxW(_hWnd, msg, title, MB_YESNO | MB_ICONWARNING | MB_DEFBUTTON2 | MB_SETFOREGROUND);
        if (result == IDYES)
        {
            TriggerPowerSignal(ServerPowerSignal.Kill);
        }
    }

    public void TriggerPowerSignal(ServerPowerSignal signal)
    {
        ServerInstance? srv;
        lock (_lock)
        {
            if (_activeServer == null || _isPerformingAction) return;
            srv = _activeServer;
            _isPerformingAction = true;
        }

        _ = Task.Run(async () =>
        {
            try
            {
                await ServerService.Shared.SendPowerSignalAsync(srv.Identifier, signal.ToSignalString(), srv.Id.ToString());
                await Task.Delay(1200);
                var live = await ServerService.Shared.FetchLiveResourcesAsync(srv.Identifier, srv.Id);
                if (live != null)
                {
                    lock (_lock)
                    {
                        if (_activeServer != null && _activeServer.Identifier == srv.Identifier)
                        {
                            _activeServer.State = live.Value.state;
                            _activeServer.MemoryUsedMB = live.Value.memoryMB;
                            _activeServer.CpuUsedPercent = live.Value.cpuPercent;
                            _activeServer.DiskUsedMB = live.Value.diskMB;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[TrayIconManager] Power signal error: {ex.Message}");
            }
            finally
            {
                lock (_lock)
                {
                    _isPerformingAction = false;
                }
                UpdateTooltip();
            }
        });
    }

    public string LocalizedServerState(string state)
    {
        return state.ToLowerInvariant() switch
        {
            "running" => _loc.GetString("menubar_server_running") ?? "En ligne",
            "starting" => _loc.GetString("menubar_server_starting") ?? "Démarrage...",
            "stopping" => _loc.GetString("menubar_server_stopping") ?? "Arrêt...",
            "suspended" => _loc.GetString("menubar_server_suspended") ?? "Suspendu",
            _ => _loc.GetString("menubar_server_offline") ?? "Hors ligne"
        };
    }

    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;

        _periodicRefreshTimer?.Dispose();
        _periodicRefreshTimer = null;

        QuickActionServerStorage.Shared.DidChange -= OnQuickActionServerChanged;

        if (_hWnd != IntPtr.Zero)
        {
            try
            {
                var nid = new NOTIFYICONDATAW
                {
                    cbSize = (uint)Marshal.SizeOf<NOTIFYICONDATAW>(),
                    hWnd = _hWnd,
                    uID = TRAY_ICON_UID
                };
                Shell_NotifyIconW(NIM_DELETE, ref nid);

                if (_subclassProc != null)
                {
                    RemoveWindowSubclass(_hWnd, _subclassProc, (UIntPtr)SUBCLASS_ID);
                    _subclassProc = null;
                }
            }
            catch { }
        }

        if (_hIcon != IntPtr.Zero)
        {
            try
            {
                DestroyIcon(_hIcon);
            }
            catch { }
            _hIcon = IntPtr.Zero;
        }

        _trayTarget = null;
    }
}
