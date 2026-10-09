using System;
using System.Globalization;
#if HAS_WINUI
using Microsoft.UI.Xaml.Media;
using Windows.UI;
#endif

namespace Overnode.App.Services;

public static class ColorHexHelper
{
    public static bool IsValidHex(string? hex)
    {
        if (string.IsNullOrWhiteSpace(hex)) return false;
        string clean = hex.Trim().TrimStart('#');
        if (clean.Length != 3 && clean.Length != 6 && clean.Length != 8) return false;
        foreach (char c in clean)
        {
            if (!Uri.IsHexDigit(c)) return false;
        }
        return true;
    }

    public static string NormalizeHex(string? hex, string defaultHex = "#E5B842")
    {
        if (!IsValidHex(hex)) return defaultHex;
        string clean = hex!.Trim().TrimStart('#');
        if (clean.Length == 3)
        {
            return $"#{clean[0]}{clean[0]}{clean[1]}{clean[1]}{clean[2]}{clean[2]}".ToUpperInvariant();
        }
        return $"#{clean}".ToUpperInvariant();
    }

#if HAS_WINUI
    public static Color FromHex(string? hex, Color defaultColor = default)
    {
        if (defaultColor == default)
        {
            defaultColor = Color.FromArgb(255, 255, 255, 255);
        }

        if (string.IsNullOrWhiteSpace(hex))
        {
            return defaultColor;
        }

        string clean = hex.Trim().TrimStart('#');

        try
        {
            if (clean.Length == 3) // RGB (12-bit)
            {
                byte r = (byte)(Convert.ToByte(clean.Substring(0, 1), 16) * 17);
                byte g = (byte)(Convert.ToByte(clean.Substring(1, 1), 16) * 17);
                byte b = (byte)(Convert.ToByte(clean.Substring(2, 1), 16) * 17);
                return Color.FromArgb(255, r, g, b);
            }
            if (clean.Length == 6) // RGB (24-bit)
            {
                byte r = byte.Parse(clean.Substring(0, 2), NumberStyles.HexNumber, CultureInfo.InvariantCulture);
                byte g = byte.Parse(clean.Substring(2, 2), NumberStyles.HexNumber, CultureInfo.InvariantCulture);
                byte b = byte.Parse(clean.Substring(4, 2), NumberStyles.HexNumber, CultureInfo.InvariantCulture);
                return Color.FromArgb(255, r, g, b);
            }
            if (clean.Length == 8) // ARGB (32-bit)
            {
                byte a = byte.Parse(clean.Substring(0, 2), NumberStyles.HexNumber, CultureInfo.InvariantCulture);
                byte r = byte.Parse(clean.Substring(2, 2), NumberStyles.HexNumber, CultureInfo.InvariantCulture);
                byte g = byte.Parse(clean.Substring(4, 2), NumberStyles.HexNumber, CultureInfo.InvariantCulture);
                byte b = byte.Parse(clean.Substring(6, 2), NumberStyles.HexNumber, CultureInfo.InvariantCulture);
                return Color.FromArgb(a, r, g, b);
            }
        }
        catch
        {
            // Fallback on error
        }

        return defaultColor;
    }

    public static string ToHex(Color color, bool includeAlpha = false)
    {
        return includeAlpha
            ? $"#{color.A:X2}{color.R:X2}{color.G:X2}{color.B:X2}"
            : $"#{color.R:X2}{color.G:X2}{color.B:X2}";
    }

    public static SolidColorBrush ToBrush(string? hex, Color defaultColor = default)
    {
        return new SolidColorBrush(FromHex(hex, defaultColor));
    }
#endif
}
