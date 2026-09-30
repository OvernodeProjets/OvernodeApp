using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Overnode.App.Services;

namespace Overnode.Tests;

public class ConsoleColorTests
{
    public void Test_AnsiParsing_BasicColors()
    {
        // Red ANSI sequence
        string redLine = "\x1B[31m[ERROR] Connection failed\x1B[0m";
        var spans = ConsoleColorHelper.ParseLineToSpans(redLine);

        Assert.IsTrue(spans.Count > 0, "Spans should not be empty");
        var redSpan = spans.FirstOrDefault(s => s.Text.Contains("[ERROR] Connection failed"));
        Assert.IsNotNull(redSpan, "Should find colored segment");
        Assert.AreEqual(ConsoleColorHelper.ColorRed, redSpan.HexColor, "Color should be Red");

        // Green ANSI sequence
        string greenLine = "\x1B[32m[INFO] Server started successfully\x1B[0m";
        var greenSpans = ConsoleColorHelper.ParseLineToSpans(greenLine);
        var greenSpan = greenSpans.FirstOrDefault(s => s.Text.Contains("Server started"));
        Assert.IsNotNull(greenSpan, "Should find green segment");
        Assert.AreEqual(ConsoleColorHelper.ColorGreen, greenSpan.HexColor, "Color should be Green");

        // Yellow ANSI sequence
        string yellowLine = "\x1B[33m[WARN] Memory limit reached\x1B[0m";
        var yellowSpans = ConsoleColorHelper.ParseLineToSpans(yellowLine);
        var yellowSpan = yellowSpans.FirstOrDefault(s => s.Text.Contains("Memory limit"));
        Assert.IsNotNull(yellowSpan, "Should find yellow segment");
        Assert.AreEqual(ConsoleColorHelper.ColorYellow, yellowSpan.HexColor, "Color should be Yellow");
    }

    public void Test_SemanticColoring_WithoutAnsi()
    {
        // Error line
        var errorSpans = ConsoleColorHelper.ParseLineToSpans("[12:00:00] [Error] Failed to load plugin");
        Assert.AreEqual(ConsoleColorHelper.ColorRed, errorSpans[0].HexColor, "Semantic error line should be Red");

        // Warn line
        var warnSpans = ConsoleColorHelper.ParseLineToSpans("[12:00:01] WARN Can't keep up! Is the server overloaded?");
        Assert.AreEqual(ConsoleColorHelper.ColorYellow, warnSpans[0].HexColor, "Semantic warn line should be Yellow");

        // Command line
        var cmdSpans = ConsoleColorHelper.ParseLineToSpans("> help");
        Assert.AreEqual(ConsoleColorHelper.ColorCyan, cmdSpans[0].HexColor, "Command line should be Cyan");

        // Success / Done line
        var doneSpans = ConsoleColorHelper.ParseLineToSpans("Done (2.54s)! For help, type \"help\"");
        Assert.AreEqual(ConsoleColorHelper.ColorGreen, doneSpans[0].HexColor, "Done line should be Green");

        // Normal log line
        var normalSpans = ConsoleColorHelper.ParseLineToSpans("[12:00:02] Loading world default...");
        Assert.AreEqual(ConsoleColorHelper.ColorDefault, normalSpans[0].HexColor, "Normal line should be Default color");
    }

    public void Test_StripAnsi_And_ToPlainText()
    {
        string rawLine = "\x1B[31m[ERROR]\x1B[0m \x1B[32mPlayer joined\x1B[0m";
        string stripped = ConsoleColorHelper.StripAnsi(rawLine);
        Assert.AreEqual("[ERROR] Player joined", stripped, "All ANSI tokens should be stripped");

        var lines = new[]
        {
            "\x1B[31mLine 1\x1B[0m",
            "\x1B[32mLine 2\x1B[0m"
        };
        string plain = ConsoleColorHelper.ToPlainText(lines);
        Assert.IsTrue(plain.Contains("Line 1") && plain.Contains("Line 2"), "Plain text should contain clean lines");
        Assert.IsFalse(plain.Contains("\x1B"), "Plain text must not contain ANSI escape codes");
    }

    public void Test_ToHtmlFragment_PreservesColors()
    {
        var lines = new[]
        {
            "[Error] Database connection dropped",
            "> reload",
            "Done (1.2s)!"
        };

        string html = ConsoleColorHelper.ToHtmlFragment(lines);

        Assert.IsTrue(html.Contains("background-color: #0C0E14"), "HTML must have terminal background");
        Assert.IsTrue(html.Contains(ConsoleColorHelper.ColorRed), "HTML must contain Red for error");
        Assert.IsTrue(html.Contains(ConsoleColorHelper.ColorCyan), "HTML must contain Cyan for command");
        Assert.IsTrue(html.Contains(ConsoleColorHelper.ColorGreen), "HTML must contain Green for done");

        string clipboardWrapped = ConsoleColorHelper.WrapInClipboardHtml(html);
        Assert.IsTrue(clipboardWrapped.StartsWith("Version:0.9"), "Clipboard HTML must have CF_HTML header");
        Assert.IsTrue(clipboardWrapped.Contains("<!--StartFragment-->"), "Clipboard HTML must have StartFragment");
        Assert.IsTrue(clipboardWrapped.Contains("<!--EndFragment-->"), "Clipboard HTML must have EndFragment");
    }

    public void Test_ToRtf_ContainsColorTable()
    {
        var lines = new[]
        {
            "[Error] Server fault",
            "Done!"
        };

        string rtf = ConsoleColorHelper.ToRtf(lines);
        Assert.IsTrue(rtf.StartsWith(@"{\rtf1"), "RTF header required");
        Assert.IsTrue(rtf.Contains(@"\colortbl"), "RTF must contain colortbl");
        Assert.IsTrue(rtf.Contains(@"\cf1"), "RTF must use color indices");
    }

    public void Test_ToDiscordAnsi()
    {
        var lines = new[]
        {
            "[Error] Crash detected",
            "Done!"
        };

        string discord = ConsoleColorHelper.ToDiscordAnsi(lines);
        Assert.IsTrue(discord.StartsWith("```ansi"), "Discord format must start with ```ansi");
        Assert.IsTrue(discord.EndsWith("```"), "Discord format must end with ```");
        Assert.IsTrue(discord.Contains("\x1B["), "Discord format must contain ANSI color codes");
    }

    public void Test_TrayIconManager_DisposalIdempotence()
    {
        // Verifies calling Dispose multiple times is safe and doesn't throw
        var manager = TrayIconManager.Shared;
        manager.Dispose();
        manager.Dispose();
        Assert.IsFalse(manager.IsInitialized, "Should not be initialized after Dispose");
    }
}
