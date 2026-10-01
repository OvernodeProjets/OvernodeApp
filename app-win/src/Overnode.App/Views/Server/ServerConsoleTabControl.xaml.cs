using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.UI;
using Microsoft.UI.Text;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Documents;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Overnode.App.Localization;
using Overnode.App.Services;
using Overnode.App.ViewModels;
using Windows.ApplicationModel.DataTransfer;
using Windows.System;
using Windows.UI;

namespace Overnode.App.Views.Server;

public sealed partial class ServerConsoleTabControl : UserControl
{
    private static readonly Dictionary<string, SolidColorBrush> BrushCache = new(StringComparer.OrdinalIgnoreCase);
    private static readonly SolidColorBrush DefaultTextBrush = new(Color.FromArgb(255, 203, 213, 225));

    public ServerDetailViewModel? ViewModel => DataContext as ServerDetailViewModel;
    private ServerDetailViewModel? _boundViewModel;

    public ServerConsoleTabControl()
    {
        InitializeComponent();
        LocalizationManager.Instance.LanguageChanged += (s, e) => UpdateLocalization();
        DataContextChanged += OnDataContextChanged;
        UpdateLocalization();
    }

    private static SolidColorBrush GetBrushForHex(string hex)
    {
        if (BrushCache.TryGetValue(hex, out var cached))
        {
            return cached;
        }

        try
        {
            string clean = hex.TrimStart('#');
            if (clean.Length == 6)
            {
                byte r = byte.Parse(clean.Substring(0, 2), System.Globalization.NumberStyles.HexNumber);
                byte g = byte.Parse(clean.Substring(2, 2), System.Globalization.NumberStyles.HexNumber);
                byte b = byte.Parse(clean.Substring(4, 2), System.Globalization.NumberStyles.HexNumber);
                var brush = new SolidColorBrush(Color.FromArgb(255, r, g, b));
                BrushCache[hex] = brush;
                return brush;
            }
        }
        catch { }

        return DefaultTextBrush;
    }

    private void OnDataContextChanged(FrameworkElement sender, DataContextChangedEventArgs args)
    {
        if (_boundViewModel != null)
        {
            _boundViewModel.ConsoleLines.CollectionChanged -= OnConsoleLinesChanged;
            _boundViewModel.PropertyChanged -= OnViewModelPropertyChanged;
        }

        _boundViewModel = DataContext as ServerDetailViewModel;
        if (_boundViewModel != null)
        {
            RebuildConsoleBlocks();
            _boundViewModel.ConsoleLines.CollectionChanged += OnConsoleLinesChanged;
            _boundViewModel.PropertyChanged += OnViewModelPropertyChanged;
            UpdateStatsUI();
        }
        else
        {
            ConsoleRichTextBlock.Blocks.Clear();
        }
    }

    private void RebuildConsoleBlocks()
    {
        ConsoleRichTextBlock.Blocks.Clear();
        if (_boundViewModel == null) return;

        foreach (var line in _boundViewModel.ConsoleLines)
        {
            ConsoleRichTextBlock.Blocks.Add(CreateParagraphForLine(line));
        }

        DispatcherQueue.TryEnqueue(() =>
        {
            ConsoleScrollViewer.ChangeView(null, ConsoleScrollViewer.ScrollableHeight, null, false);
        });
    }

    private Paragraph CreateParagraphForLine(string line)
    {
        var p = new Paragraph { Margin = new Thickness(0, 1, 0, 1) };
        var spans = ConsoleColorHelper.ParseLineToSpans(line);

        foreach (var span in spans)
        {
            var run = new Run
            {
                Text = span.Text,
                Foreground = GetBrushForHex(span.HexColor)
            };

            if (span.IsBold)
            {
                run.FontWeight = FontWeights.Bold;
            }

            p.Inlines.Add(run);
        }

        return p;
    }

    private void OnViewModelPropertyChanged(object? sender, System.ComponentModel.PropertyChangedEventArgs e)
    {
        DispatcherQueue.TryEnqueue(UpdateStatsUI);
    }

    private void OnConsoleLinesChanged(object? sender, NotifyCollectionChangedEventArgs e)
    {
        DispatcherQueue.TryEnqueue(() =>
        {
            if (e.Action == NotifyCollectionChangedAction.Reset)
            {
                ConsoleRichTextBlock.Blocks.Clear();
                return;
            }

            if (e.Action == NotifyCollectionChangedAction.Add && e.NewItems != null)
            {
                foreach (var item in e.NewItems)
                {
                    if (item is string line)
                    {
                        ConsoleRichTextBlock.Blocks.Add(CreateParagraphForLine(line));
                    }
                }

                while (ConsoleRichTextBlock.Blocks.Count > 1000)
                {
                    ConsoleRichTextBlock.Blocks.RemoveAt(0);
                }

                ConsoleScrollViewer.ChangeView(null, ConsoleScrollViewer.ScrollableHeight, null, false);
            }
        });
    }

    private void UpdateLocalization()
    {
        var loc = LocalizationManager.Instance;
        ResourceCpuLabel.Text = loc.GetString("resource_cpu").ToUpperInvariant();
        ResourceRamLabel.Text = loc.GetString("resource_ram").ToUpperInvariant();
        ResourceDiskLabel.Text = loc.GetString("resource_disk").ToUpperInvariant();
        CommandTextBox.PlaceholderText = loc.GetString("console_input_placeholder");
        SendText.Text = loc.GetString("console_send");
        ClearText.Text = loc.GetString("console_clear");
        if (ContextMenuCopy != null) ContextMenuCopy.Text = loc.GetString("console_context_copy");
        if (ContextMenuSelectAll != null) ContextMenuSelectAll.Text = loc.GetString("console_context_select_all");
        if (ContextMenuClear != null) ContextMenuClear.Text = loc.GetString("console_context_clear");
        UpdateStatsUI();
    }

    public void UpdateStatsUI()
    {
        if (ViewModel == null) return;
        var srv = ViewModel.Server;
        CpuText.Text = $"{srv.CpuUsedPercent:F1}% / {srv.CpuLimitPercent:F0}%";
        RamText.Text = $"{srv.MemoryUsedMB:F0} / {srv.MemoryLimitMB:F0} MB";
        DiskText.Text = $"{srv.DiskUsedMB:F0} / {srv.DiskLimitMB:F0} MB";
    }

    private async void OnSendCommandClicked(object sender, RoutedEventArgs e)
    {
        await SendCommandInternalAsync();
    }

    private async void OnCommandKeyDown(object sender, KeyRoutedEventArgs e)
    {
        if (e.Key == VirtualKey.Enter)
        {
            e.Handled = true;
            await SendCommandInternalAsync();
        }
    }

    private async Task SendCommandInternalAsync()
    {
        if (ViewModel == null) return;
        var text = CommandTextBox.Text;
        if (string.IsNullOrWhiteSpace(text)) return;
        CommandTextBox.Text = string.Empty;

        ViewModel.CommandInput = text;
        await ViewModel.SendConsoleCommandAsync();
    }

    private void OnClearConsoleClicked(object sender, RoutedEventArgs e)
    {
        ViewModel?.ConsoleLines.Clear();
        ConsoleRichTextBlock.Blocks.Clear();
    }

    // --- Direct Console Copying & Color Transmission ---

    private void OnContextMenuCopyClicked(object sender, RoutedEventArgs e)
    {
        CopySelectedOrAll();
    }

    private void OnContextMenuSelectAllClicked(object sender, RoutedEventArgs e)
    {
        ConsoleRichTextBlock.SelectAll();
    }

    private void OnConsoleKeyDown(object sender, KeyRoutedEventArgs e)
    {
        var ctrl = Microsoft.UI.Input.InputKeyboardSource.GetKeyStateForCurrentThread(VirtualKey.Control);
        bool isCtrlDown = (ctrl & Windows.UI.Core.CoreVirtualKeyStates.Down) == Windows.UI.Core.CoreVirtualKeyStates.Down;

        if (isCtrlDown && e.Key == VirtualKey.C)
        {
            e.Handled = true;
            CopySelectedOrAll();
        }
        else if (isCtrlDown && e.Key == VirtualKey.A)
        {
            e.Handled = true;
            ConsoleRichTextBlock.SelectAll();
        }
    }

    private void CopySelectedOrAll()
    {
        List<string> linesToCopy;
        string selected = ConsoleRichTextBlock.SelectedText;

        if (!string.IsNullOrWhiteSpace(selected))
        {
            linesToCopy = selected.Split(new[] { "\r\n", "\r", "\n" }, StringSplitOptions.None).ToList();
        }
        else if (_boundViewModel != null && _boundViewModel.ConsoleLines.Count > 0)
        {
            linesToCopy = _boundViewModel.ConsoleLines.ToList();
        }
        else
        {
            return;
        }

        var dataPackage = new DataPackage();

        string plainText = ConsoleColorHelper.ToPlainText(linesToCopy);
        string htmlFragment = ConsoleColorHelper.ToHtmlFragment(linesToCopy);
        string clipboardHtml = ConsoleColorHelper.WrapInClipboardHtml(htmlFragment);
        string rtf = ConsoleColorHelper.ToRtf(linesToCopy);

        dataPackage.SetText(plainText);
        dataPackage.SetHtmlFormat(clipboardHtml);
        dataPackage.SetRtf(rtf);

        try
        {
            Clipboard.SetContent(dataPackage);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[ServerConsoleTabControl] Clipboard error: {ex.Message}");
        }
    }
}
