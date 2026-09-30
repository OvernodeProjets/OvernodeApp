using System;
using System.Collections.Generic;
using System.Globalization;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;

namespace Overnode.App.Services;

/// <summary>
/// Represents a colored text segment in the server console.
/// </summary>
public sealed class ConsoleColorSpan
{
    public string Text { get; set; } = string.Empty;
    public string HexColor { get; set; } = "#CBD5E1";
    public bool IsBold { get; set; }

    public ConsoleColorSpan() { }

    public ConsoleColorSpan(string text, string hexColor, bool isBold = false)
    {
        Text = text;
        HexColor = hexColor;
        IsBold = isBold;
    }
}

/// <summary>
/// Helper to parse console output, preserve ANSI/semantic colors, and format clipboard content
/// (HTML, RTF, Discord ANSI, and Plain Text) so console colors are preserved when copying.
/// </summary>
public static class ConsoleColorHelper
{
    // Color Palette matching Overnode Dark Terminal
    public const string ColorRed = "#F87171";      // Errors, crashes, exceptions
    public const string ColorGreen = "#34D399";    // Success, done, connected
    public const string ColorYellow = "#FBBF24";   // Warnings, actions, notices
    public const string ColorBlue = "#60A5FA";     // Info, ports, network
    public const string ColorMagenta = "#E879F9";  // Debug, special
    public const string ColorCyan = "#38BDF8";     // Commands, prompts, system
    public const string ColorWhite = "#F8FAFC";    // Bright white
    public const string ColorGray = "#94A3B8";     // Muted gray / secondary
    public const string ColorDefault = "#CBD5E1"; // Standard terminal output text

    private static readonly Regex AnsiRegex = new(@"\x1B\[[0-9;]*[a-zA-Z]", RegexOptions.Compiled);
    private static readonly Regex AnsiSequenceRegex = new(@"\x1B\[([0-9;]*)m", RegexOptions.Compiled);

    /// <summary>
    /// Strips all ANSI escape sequences from text.
    /// </summary>
    public static string StripAnsi(string input)
    {
        if (string.IsNullOrEmpty(input)) return string.Empty;
        return AnsiRegex.Replace(input, string.Empty);
    }

    /// <summary>
    /// Parses a single raw console line into colored spans.
    /// Handles both ANSI escape codes and semantic keyword coloring.
    /// </summary>
    public static List<ConsoleColorSpan> ParseLineToSpans(string rawLine)
    {
        var spans = new List<ConsoleColorSpan>();
        if (string.IsNullOrEmpty(rawLine))
        {
            spans.Add(new ConsoleColorSpan(string.Empty, ColorDefault));
            return spans;
        }

        // Check if line contains ANSI escape codes
        if (rawLine.Contains('\x1B'))
        {
            var parsed = ParseAnsiSpans(rawLine);
            if (parsed.Count > 0)
            {
                return parsed;
            }
        }

        // Semantic fallback based on content
        string color = DetectSemanticColor(rawLine);
        bool isBold = color == ColorRed || color == ColorCyan;
        spans.Add(new ConsoleColorSpan(rawLine, color, isBold));
        return spans;
    }

    /// <summary>
    /// Detects semantic color for a line without ANSI codes.
    /// </summary>
    public static string DetectSemanticColor(string line)
    {
        if (string.IsNullOrWhiteSpace(line)) return ColorDefault;

        if (line.Contains("[Error]", StringComparison.OrdinalIgnoreCase) ||
            line.Contains("ERROR", StringComparison.OrdinalIgnoreCase) ||
            line.Contains("Exception", StringComparison.OrdinalIgnoreCase) ||
            line.Contains("Fatal", StringComparison.OrdinalIgnoreCase) ||
            line.Contains("Failed", StringComparison.OrdinalIgnoreCase))
        {
            return ColorRed;
        }

        if (line.Contains("[Action]", StringComparison.OrdinalIgnoreCase) ||
            line.Contains("WARN", StringComparison.OrdinalIgnoreCase) ||
            line.Contains("Warning", StringComparison.OrdinalIgnoreCase) ||
            line.Contains("Alert", StringComparison.OrdinalIgnoreCase))
        {
            return ColorYellow;
        }

        if (line.StartsWith("> ") || line.Contains("[System]", StringComparison.OrdinalIgnoreCase))
        {
            return ColorCyan;
        }

        if (line.Contains("[Success]", StringComparison.OrdinalIgnoreCase) ||
            line.Contains("Done (", StringComparison.OrdinalIgnoreCase) ||
            line.Contains("Started", StringComparison.OrdinalIgnoreCase) ||
            line.Contains("Connected", StringComparison.OrdinalIgnoreCase) ||
            line.Contains("Ready", StringComparison.OrdinalIgnoreCase))
        {
            return ColorGreen;
        }

        return ColorDefault;
    }

    private static List<ConsoleColorSpan> ParseAnsiSpans(string line)
    {
        var result = new List<ConsoleColorSpan>();
        var matches = AnsiSequenceRegex.Matches(line);

        if (matches.Count == 0)
        {
            string clean = StripAnsi(line);
            result.Add(new ConsoleColorSpan(clean, DetectSemanticColor(clean)));
            return result;
        }

        string currentColor = ColorDefault;
        bool isBold = false;
        int currentIndex = 0;

        foreach (Match match in matches)
        {
            if (match.Index > currentIndex)
            {
                string textSegment = line.Substring(currentIndex, match.Index - currentIndex);
                if (!string.IsNullOrEmpty(textSegment))
                {
                    result.Add(new ConsoleColorSpan(textSegment, currentColor, isBold));
                }
            }

            // Parse SGR codes
            string codeStr = match.Groups[1].Value;
            if (string.IsNullOrEmpty(codeStr) || codeStr == "0")
            {
                currentColor = ColorDefault;
                isBold = false;
            }
            else
            {
                string[] parts = codeStr.Split(';');
                foreach (string part in parts)
                {
                    if (int.TryParse(part, out int code))
                    {
                        switch (code)
                        {
                            case 0:
                                currentColor = ColorDefault;
                                isBold = false;
                                break;
                            case 1:
                                isBold = true;
                                break;
                            case 30:
                            case 90:
                                currentColor = ColorGray;
                                break;
                            case 31:
                            case 91:
                                currentColor = ColorRed;
                                break;
                            case 32:
                            case 92:
                                currentColor = ColorGreen;
                                break;
                            case 33:
                            case 93:
                                currentColor = ColorYellow;
                                break;
                            case 34:
                            case 94:
                                currentColor = ColorBlue;
                                break;
                            case 35:
                            case 95:
                                currentColor = ColorMagenta;
                                break;
                            case 36:
                            case 96:
                                currentColor = ColorCyan;
                                break;
                            case 37:
                            case 97:
                                currentColor = ColorWhite;
                                break;
                            case 39:
                                currentColor = ColorDefault;
                                break;
                        }
                    }
                }
            }

            currentIndex = match.Index + match.Length;
        }

        if (currentIndex < line.Length)
        {
            string remaining = line.Substring(currentIndex);
            if (!string.IsNullOrEmpty(remaining))
            {
                result.Add(new ConsoleColorSpan(remaining, currentColor, isBold));
            }
        }

        return result;
    }

    /// <summary>
    /// Converts a list of raw console lines into clean plain text.
    /// </summary>
    public static string ToPlainText(IEnumerable<string> lines)
    {
        var sb = new StringBuilder();
        foreach (var line in lines)
        {
            sb.AppendLine(StripAnsi(line));
        }
        return sb.ToString().TrimEnd();
    }

    /// <summary>
    /// Converts console lines to colored HTML markup.
    /// </summary>
    public static string ToHtmlFragment(IEnumerable<string> lines)
    {
        var sb = new StringBuilder();
        sb.Append("<div style=\"background-color: #0C0E14; color: #CBD5E1; font-family: 'Consolas', 'Cascadia Code', monospace; font-size: 12px; padding: 12px; border-radius: 6px; line-height: 1.4;\">");

        foreach (var line in lines)
        {
            sb.Append("<div style=\"white-space: pre-wrap; margin: 1px 0;\">");
            var spans = ParseLineToSpans(line);
            foreach (var span in spans)
            {
                string encoded = WebUtility.HtmlEncode(span.Text);
                string weight = span.IsBold ? "font-weight: bold; " : string.Empty;
                sb.Append($"<span style=\"color: {span.HexColor}; {weight}\">{encoded}</span>");
            }
            sb.Append("</div>");
        }

        sb.Append("</div>");
        return sb.ToString();
    }

    /// <summary>
    /// Wraps an HTML fragment in the standard CF_HTML format for Windows Clipboard.
    /// </summary>
    public static string WrapInClipboardHtml(string htmlFragment)
    {
        const string header = @"Version:0.9
StartHTML:{0:D8}
EndHTML:{1:D8}
StartFragment:{2:D8}
EndFragment:{3:D8}
<html>
<body>
<!--StartFragment-->";

        const string footer = @"<!--EndFragment-->
</body>
</html>";

        // Estimate byte offsets
        int headerDummyLength = string.Format(CultureInfo.InvariantCulture, header, 0, 0, 0, 0).Length;
        int startHtml = headerDummyLength;
        int startFragment = startHtml + "<html>\r\n<body>\r\n<!--StartFragment-->".Length;
        int endFragment = startFragment + Encoding.UTF8.GetByteCount(htmlFragment);
        int endHtml = endFragment + Encoding.UTF8.GetByteCount(footer);

        string finalHeader = string.Format(CultureInfo.InvariantCulture, header, startHtml, endHtml, startFragment, endFragment);
        return finalHeader + htmlFragment + footer;
    }

    /// <summary>
    /// Converts console lines to Rich Text Format (RTF) with a color table.
    /// </summary>
    public static string ToRtf(IEnumerable<string> lines)
    {
        // Palette indices:
        // \cf1 = #F87171 (Red)
        // \cf2 = #34D399 (Green)
        // \cf3 = #FBBF24 (Yellow)
        // \cf4 = #38BDF8 (Cyan)
        // \cf5 = #CBD5E1 (Default Slate)
        // \cf6 = #60A5FA (Blue)
        // \cf7 = #E879F9 (Magenta)
        // \cf8 = #94A3B8 (Gray)

        var sb = new StringBuilder();
        sb.Append(@"{\rtf1\ansi\deff0{\fonttbl{\f0\fnil\fcharset0 Consolas;}}");
        sb.Append(@"{\colortbl ;\red248\green113\blue113;\red52\green211\blue153;\red251\green191\blue36;\red56\green189\blue248;\red203\green213\blue225;\red96\green165\blue250;\red232\green121\blue249;\red148\green163\blue184;}");
        sb.Append(@"\viewkind4\uc1\pard\f0\fs18 ");

        foreach (var line in lines)
        {
            var spans = ParseLineToSpans(line);
            foreach (var span in spans)
            {
                int colorIndex = GetRtfColorIndex(span.HexColor);
                if (span.IsBold) sb.Append(@"\b ");
                sb.Append($@"\cf{colorIndex} ");
                sb.Append(EscapeRtf(span.Text));
                if (span.IsBold) sb.Append(@"\b0 ");
            }
            sb.Append(@"\par" + "\r\n");
        }

        sb.Append(@"\cf0\par}");
        return sb.ToString();
    }

    private static int GetRtfColorIndex(string hexColor)
    {
        return hexColor.ToUpperInvariant() switch
        {
            ColorRed => 1,
            ColorGreen => 2,
            ColorYellow => 3,
            ColorCyan => 4,
            ColorBlue => 6,
            ColorMagenta => 7,
            ColorGray => 8,
            _ => 5
        };
    }

    private static string EscapeRtf(string text)
    {
        if (string.IsNullOrEmpty(text)) return string.Empty;
        var sb = new StringBuilder();
        foreach (char c in text)
        {
            if (c == '\\' || c == '{' || c == '}')
            {
                sb.Append('\\').Append(c);
            }
            else if (c > 127)
            {
                sb.Append($@"\u{(int)c}?");
            }
            else
            {
                sb.Append(c);
            }
        }
        return sb.ToString();
    }

    /// <summary>
    /// Converts console lines to Discord ANSI code block format:
    /// ```ansi
    /// \u001b[31m[Error] ...\u001b[0m
    /// ```
    /// </summary>
    public static string ToDiscordAnsi(IEnumerable<string> lines)
    {
        var sb = new StringBuilder();
        sb.AppendLine("```ansi");

        foreach (var line in lines)
        {
            var spans = ParseLineToSpans(line);
            foreach (var span in spans)
            {
                string ansiCode = GetDiscordAnsiCode(span.HexColor, span.IsBold);
                sb.Append($"{ansiCode}{span.Text}\u001B[0m");
            }
            sb.AppendLine();
        }

        sb.Append("```");
        return sb.ToString();
    }

    private static string GetDiscordAnsiCode(string hexColor, bool isBold)
    {
        string boldPrefix = isBold ? "1;" : "";
        return hexColor.ToUpperInvariant() switch
        {
            ColorRed => $"\u001B[{boldPrefix}31m",
            ColorGreen => $"\u001B[{boldPrefix}32m",
            ColorYellow => $"\u001B[{boldPrefix}33m",
            ColorBlue => $"\u001B[{boldPrefix}34m",
            ColorMagenta => $"\u001B[{boldPrefix}35m",
            ColorCyan => $"\u001B[{boldPrefix}36m",
            ColorGray => $"\u001B[{boldPrefix}30m",
            _ => $"\u001B[{boldPrefix}37m"
        };
    }
}
