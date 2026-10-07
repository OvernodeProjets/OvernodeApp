using System;
using System.Collections.Generic;
using System.IO;

#if HAS_WINUI
using Microsoft.UI.Xaml.Media.Imaging;
#endif

namespace Overnode.App.Services;

/// <summary>
/// Gère le chargement, la résolution et la mise en cache des assets pour l'Easter Egg félin (Windows).
/// </summary>
public sealed class EasterEggAssetManager
{
    private static readonly Lazy<EasterEggAssetManager> _lazy = new(() => new EasterEggAssetManager());
    public static EasterEggAssetManager Shared => _lazy.Value;

#if HAS_WINUI
    private readonly Dictionary<int, BitmapImage> _cachedImages = new();
#endif
    private readonly Dictionary<int, string> _cachedPaths = new();
    private string? _cachedAudioPath;
    public const int TotalImageCount = 12;

    public EasterEggAssetManager()
    {
    }

    public void PreloadImages()
    {
        for (int i = 1; i <= TotalImageCount; i++)
        {
            var path = ResolveFilePath($"cat_{i:D2}", "png");
            if (path != null)
            {
                _cachedPaths[i] = path;
#if HAS_WINUI
                try
                {
                    _cachedImages[i] = new BitmapImage(new Uri(path));
                }
                catch
                {
                    // Ignore en environnement headless / tests unitaires
                }
#endif
            }
        }
    }

    public string? GetImagePath(int index)
    {
        if (_cachedPaths.TryGetValue(index, out var path))
        {
            return path;
        }

        var resolved = ResolveFilePath($"cat_{index:D2}", "png");
        if (resolved != null)
        {
            _cachedPaths[index] = resolved;
            return resolved;
        }

        return null;
    }

#if HAS_WINUI
    public BitmapImage? GetImageSource(int index)
    {
        if (_cachedImages.TryGetValue(index, out var cached))
        {
            return cached;
        }

        var path = GetImagePath(index);
        if (path != null)
        {
            try
            {
                var bmp = new BitmapImage(new Uri(path));
                _cachedImages[index] = bmp;
                return bmp;
            }
            catch
            {
                return null;
            }
        }

        return null;
    }

    // Raccourcis sémantiques pour les 12 poses de chat autorisées
    public BitmapImage? CatJudge => GetImageSource(1);       // Gros plan regard noir / jugement
    public BitmapImage? CatLoaf => GetImageSource(2);        // Pain de mie / loaf classique
    public BitmapImage? CatHandsome => GetImageSource(3);    // Couché pose détendue patte avant
    public BitmapImage? CatOverhead => GetImageSource(4);    // Vue du dessus avec queue trèfle
    public BitmapImage? CatExtremeZoom => GetImageSource(5); // Macro nez / yeux perçants
    public BitmapImage? CatBellyUp => GetImageSource(6);     // Ventre en l'air / breakdance
    public BitmapImage? CatLongPaws => GetImageSource(7);    // Pattes allongées / moonwalk
    public BitmapImage? CatKingChill => GetImageSource(8);   // Majestueux dans la pénombre
    public BitmapImage? CatStatue => GetImageSource(9);      // Assis bien droit comme un sphinx
    public BitmapImage? CatSidePeek => GetImageSource(10);   // Tête large regard de côté
    public BitmapImage? CatTilted => GetImageSource(11);     // Tête penchée curieuse / mignonne
    public BitmapImage? CatGrassSleep => GetImageSource(12); // Sieste paisible dans l'herbe
#endif

    public IReadOnlyList<string> AllImagePaths
    {
        get
        {
            var list = new List<string>();
            for (int i = 1; i <= TotalImageCount; i++)
            {
                var p = GetImagePath(i);
                if (p != null)
                {
                    list.Add(p);
                }
            }
            return list;
        }
    }

    // MARK: - Audio Resolution
    public string? AudioPath
    {
        get
        {
            if (_cachedAudioPath != null && File.Exists(_cachedAudioPath))
            {
                return _cachedAudioPath;
            }

            var url = ResolveFilePath("cat_audio", "mp3");
            if (url != null)
            {
                _cachedAudioPath = url;
                return url;
            }

            return null;
        }
    }

    public Uri? AudioUri
    {
        get
        {
            var p = AudioPath;
            return p != null ? new Uri(p) : null;
        }
    }

    // MARK: - File Resolver
    private string? ResolveFilePath(string name, string ext)
    {
        var candidates = new List<string>
        {
            Path.Combine(AppContext.BaseDirectory, "Assets", "EasterEgg", $"{name}.{ext}"),
            Path.Combine(AppContext.BaseDirectory, $"{name}.{ext}"),
            Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Assets", "EasterEgg", $"{name}.{ext}"),
            Path.Combine(Directory.GetCurrentDirectory(), "app-win", "src", "Overnode.App", "Assets", "EasterEgg", $"{name}.{ext}"),
            Path.Combine(Directory.GetCurrentDirectory(), "Assets", "EasterEgg", $"{name}.{ext}"),
            Path.Combine(Directory.GetCurrentDirectory(), "src", "Overnode.App", "Assets", "EasterEgg", $"{name}.{ext}"),
            Path.Combine(Directory.GetCurrentDirectory(), "app-mac", "Sources", "Overnode", "Resources", "EasterEgg", $"{name}.{ext}"),
            Path.Combine(Directory.GetCurrentDirectory(), "..", "app-mac", "Sources", "Overnode", "Resources", "EasterEgg", $"{name}.{ext}")
        };

        foreach (var path in candidates)
        {
            try
            {
                if (File.Exists(path))
                {
                    return Path.GetFullPath(path);
                }
            }
            catch { }
        }

        return null;
    }
}
