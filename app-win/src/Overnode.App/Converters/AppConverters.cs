using System;
using Microsoft.UI;
using Microsoft.UI.Xaml.Data;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace Overnode.App.Converters;

public class BoolToStatusBrushConverter : IValueConverter
{
    private static readonly SolidColorBrush OnlineBrush = new(Color.FromArgb(255, 34, 197, 94)); // Emerald green
    private static readonly SolidColorBrush OfflineBrush = new(Color.FromArgb(255, 115, 122, 140)); // Gray

    public object Convert(object value, Type targetType, object parameter, string language)
    {
        if (value is bool b && b)
        {
            return OnlineBrush;
        }
        return OfflineBrush;
    }

    public object ConvertBack(object value, Type targetType, object parameter, string language)
    {
        throw excitingNotSupportedException();
    }

    private static NotSupportedException excitingNotSupportedException() => new();
}

public class NullOrEmptyToCollapsedConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, string language)
    {
        if (value == null) return Microsoft.UI.Xaml.Visibility.Collapsed;
        if (value is string s && string.IsNullOrWhiteSpace(s)) return Microsoft.UI.Xaml.Visibility.Collapsed;
        return Microsoft.UI.Xaml.Visibility.Visible;
    }

    public object ConvertBack(object value, Type targetType, object parameter, string language)
    {
        throw new NotSupportedException();
    }
}
