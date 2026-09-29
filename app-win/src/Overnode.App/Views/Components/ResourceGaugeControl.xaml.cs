using System;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Overnode.App.Localization;

namespace Overnode.App.Views.Components;

public sealed partial class ResourceGaugeControl : UserControl
{
    public static readonly DependencyProperty TitleProperty =
        DependencyProperty.Register(nameof(Title), typeof(string), typeof(ResourceGaugeControl),
            new PropertyMetadata(string.Empty, (d, e) => ((ResourceGaugeControl)d).UpdateUI()));

    public static readonly DependencyProperty GlyphProperty =
        DependencyProperty.Register(nameof(Glyph), typeof(string), typeof(ResourceGaugeControl),
            new PropertyMetadata("\uE80F", (d, e) => ((ResourceGaugeControl)d).UpdateUI()));

    public static readonly DependencyProperty UsedFormattedProperty =
        DependencyProperty.Register(nameof(UsedFormatted), typeof(string), typeof(ResourceGaugeControl),
            new PropertyMetadata("0", (d, e) => ((ResourceGaugeControl)d).UpdateUI()));

    public static readonly DependencyProperty TotalFormattedProperty =
        DependencyProperty.Register(nameof(TotalFormatted), typeof(string), typeof(ResourceGaugeControl),
            new PropertyMetadata("0", (d, e) => ((ResourceGaugeControl)d).UpdateUI()));

    public static readonly DependencyProperty UnitProperty =
        DependencyProperty.Register(nameof(Unit), typeof(string), typeof(ResourceGaugeControl),
            new PropertyMetadata(string.Empty, (d, e) => ((ResourceGaugeControl)d).UpdateUI()));

    public static readonly DependencyProperty PercentageProperty =
        DependencyProperty.Register(nameof(Percentage), typeof(double), typeof(ResourceGaugeControl),
            new PropertyMetadata(0.0, (d, e) => ((ResourceGaugeControl)d).UpdateUI()));

    public static readonly DependencyProperty AccentBrushProperty =
        DependencyProperty.Register(nameof(AccentBrush), typeof(Brush), typeof(ResourceGaugeControl),
            new PropertyMetadata(null, (d, e) => ((ResourceGaugeControl)d).UpdateUI()));

    public string Title
    {
        get => (string)GetValue(TitleProperty);
        set => SetValue(TitleProperty, value);
    }

    public string Glyph
    {
        get => (string)GetValue(GlyphProperty);
        set => SetValue(GlyphProperty, value);
    }

    public string UsedFormatted
    {
        get => (string)GetValue(UsedFormattedProperty);
        set => SetValue(UsedFormattedProperty, value);
    }

    public string TotalFormatted
    {
        get => (string)GetValue(TotalFormattedProperty);
        set => SetValue(TotalFormattedProperty, value);
    }

    public string Unit
    {
        get => (string)GetValue(UnitProperty);
        set => SetValue(UnitProperty, value);
    }

    public double Percentage
    {
        get => (double)GetValue(PercentageProperty);
        set => SetValue(PercentageProperty, value);
    }

    public Brush AccentBrush
    {
        get => (Brush)GetValue(AccentBrushProperty);
        set => SetValue(AccentBrushProperty, value);
    }

    public ResourceGaugeControl()
    {
        this.InitializeComponent();
    }

    private void UpdateUI()
    {
        GaugeTitle.Text = Title;
        GaugeIcon.Glyph = Glyph;
        var unitSuffix = !string.IsNullOrEmpty(Unit) ? $" {Unit}" : "";
        GaugeValues.Text = $"{UsedFormatted}{unitSuffix} / {TotalFormatted}{unitSuffix}";
        GaugeProgress.Value = Math.Clamp(Percentage, 0, 100);

        var utilText = LocalizationManager.Instance.GetString("resource_utilization");
        GaugeUtilization.Text = $"{Percentage:F1}% {utilText}";

        if (AccentBrush != null)
        {
            GaugeIcon.Foreground = AccentBrush;
            GaugeProgress.Foreground = AccentBrush;
        }
    }
}
