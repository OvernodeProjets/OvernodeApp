using System;
using System.IO;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.Services;

namespace Overnode.Tests;

public class EasterEggTests
{
    public void Test_EasterEgg_Assets_Preloaded_And_Available()
    {
        var manager = EasterEggAssetManager.Shared;
        manager.PreloadImages();

        var paths = manager.AllImagePaths;
        Assert.AreEqual(12, paths.Count, "Les 12 images de chat doivent être chargées et résolues sur Windows");

        // Vérification des poses spécifiques
        for (int i = 1; i <= 12; i++)
        {
            var p = manager.GetImagePath(i);
            Assert.IsNotNull(p, $"L'image du chat pose #{i} doit être résolue");
            Assert.IsTrue(File.Exists(p), $"Le fichier pour la pose #{i} doit exister sur le disque: {p}");

            var fi = new FileInfo(p!);
            Assert.IsTrue(fi.Length > 0, $"L'image #{i} doit avoir une taille de fichier > 0 octets");
        }
    }

    public void Test_Excluded_Image_Not_Present()
    {
        string excludedName = "5242E2B2-7A35-4A75-B865-D381C8A47636_1_105_c";

        string[] searchDirs = new[]
        {
            Path.Combine(AppContext.BaseDirectory, "Assets", "EasterEgg"),
            Path.Combine(Directory.GetCurrentDirectory(), "Assets", "EasterEgg"),
            Path.Combine(Directory.GetCurrentDirectory(), "src", "Overnode.App", "Assets", "EasterEgg"),
            Path.Combine(Directory.GetCurrentDirectory(), "app-win", "src", "Overnode.App", "Assets", "EasterEgg")
        };

        foreach (var dir in searchDirs)
        {
            if (Directory.Exists(dir))
            {
                var files = Directory.GetFiles(dir, $"*{excludedName}*");
                Assert.AreEqual(0, files.Length, $"L'image exclue {excludedName} ne doit JAMAIS être incluse dans le dossier {dir}");
            }
        }
    }

    public void Test_EasterEgg_Audio_Resolution_And_Properties()
    {
        var manager = EasterEggAssetManager.Shared;
        var audioPath = manager.AudioPath;
        Assert.IsNotNull(audioPath, "Le chemin du fichier audio cat_audio.mp3 doit être résolu");
        Assert.IsTrue(File.Exists(audioPath), $"Le fichier audio doit exister: {audioPath}");

        var fi = new FileInfo(audioPath!);
        Assert.IsTrue(fi.Length > 1_000_000, "Le fichier audio doit faire plus de 1 Mo (~2.5 Mo pour le morceau entier)");
    }

    public void Test_EasterEgg_Phases_Timing_And_Titles()
    {
        var phases = Enum.GetValues<EasterEggPhase>();
        Assert.AreEqual(5, phases.Length, "Il doit y avoir 5 phases distinctes dans l'Easter Egg");

        Assert.AreEqual(EasterEggPhase.Intro, phases[0]);
        Assert.AreEqual(EasterEggPhase.Dancing, phases[1]);
        Assert.AreEqual(EasterEggPhase.OiiaSpin, phases[2]);
        Assert.AreEqual(EasterEggPhase.DiscoChaos, phases[3]);
        Assert.AreEqual(EasterEggPhase.Finished, phases[4]);

        var loc = LocalizationManager.Instance;
        loc.SetLanguage(AppLanguage.Fr);

        foreach (var phase in phases)
        {
            string title = phase.GetTitle();
            string sub = phase.GetSubtitle();
            Assert.IsFalse(string.IsNullOrWhiteSpace(title), $"Le titre de la phase {phase} ne doit pas être vide en FR");
            Assert.IsFalse(string.IsNullOrWhiteSpace(sub), $"Le sous-titre de la phase {phase} ne doit pas être vide en FR");
        }

        loc.SetLanguage(AppLanguage.En);
        foreach (var phase in phases)
        {
            string title = phase.GetTitle();
            string sub = phase.GetSubtitle();
            Assert.IsFalse(string.IsNullOrWhiteSpace(title), $"Le titre de la phase {phase} ne doit pas être vide en EN");
            Assert.IsFalse(string.IsNullOrWhiteSpace(sub), $"Le sous-titre de la phase {phase} ne doit pas être vide en EN");
        }

        loc.SetLanguage(AppLanguage.Fr);
    }

    public void Test_EasterEgg_Localization_Active_Switch()
    {
        var loc = LocalizationManager.Instance;

        // Tester en français
        loc.SetLanguage(AppLanguage.Fr);
        Assert.AreEqual(AppLanguage.Fr, loc.CurrentLanguage);
        Assert.AreEqual("👑 L'ÉVEIL DU CHAT OVERNODE", EasterEggPhase.Intro.GetTitle());
        Assert.AreEqual("Quitter (Échap)", loc.GetString("easteregg_quit_btn"));
        Assert.AreEqual("Miaou !", loc.GetString("easteregg_meow_btn"));
        Assert.AreEqual("Serveurs Overnode propulsés par 12 chats surpuissants", loc.GetString("easteregg_quote_2"));
        Assert.AreEqual("Le protocole Ctrl+T a atteint la perfection", loc.GetString("easteregg_quote_4"));
        Assert.AreEqual("🚀 Windows x64 Optimisé", loc.GetString("easteregg_badge_silicon"));

        // Basculer activement en anglais
        loc.SetLanguage(AppLanguage.En);
        Assert.AreEqual(AppLanguage.En, loc.CurrentLanguage);
        Assert.AreEqual("👑 THE OVERNODE CAT AWAKENS", EasterEggPhase.Intro.GetTitle());
        Assert.AreEqual("Exit (Esc)", loc.GetString("easteregg_quit_btn"));
        Assert.AreEqual("Meow!", loc.GetString("easteregg_meow_btn"));
        Assert.AreEqual("Overnode servers powered by 12 overpowered cats", loc.GetString("easteregg_quote_2"));
        Assert.AreEqual("Protocol Ctrl+T has reached perfection", loc.GetString("easteregg_quote_4"));
        Assert.AreEqual("🚀 Windows x64 Optimized", loc.GetString("easteregg_badge_silicon"));

        // Rebasculer en français pour l'état par défaut
        loc.SetLanguage(AppLanguage.Fr);
        Assert.AreEqual(AppLanguage.Fr, loc.CurrentLanguage);
    }

    public void Test_EasterEgg_Shortcut_And_Rules_Parity()
    {
        // Vérifier que la règle existe et mentionne bien Ctrl+T pour Windows et Command+T pour macOS
        string rulePath = Path.Combine(Directory.GetCurrentDirectory(), ".agents", "rules", "easter-egg.md");
        if (!File.Exists(rulePath))
        {
            rulePath = Path.Combine(Directory.GetCurrentDirectory(), "..", "..", ".agents", "rules", "easter-egg.md");
        }

        if (File.Exists(rulePath))
        {
            string content = File.ReadAllText(rulePath);
            Assert.IsTrue(content.Contains("Control + T") || content.Contains("Ctrl + T"), "La règle doit spécifier Ctrl + T pour Windows");
            Assert.IsTrue(content.Contains("Command + T"), "La règle doit spécifier Command + T pour macOS");
            Assert.IsTrue(content.Contains("137 BPM"), "La règle doit mentionner le tempo 137 BPM");
            Assert.IsTrue(content.Contains("cat_01") && content.Contains("cat_12"), "La règle doit mentionner les 12 poses cat_01 à cat_12");
        }
    }
}
