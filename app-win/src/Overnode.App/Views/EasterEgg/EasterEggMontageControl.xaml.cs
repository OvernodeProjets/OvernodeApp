using System;
using System.Collections.Generic;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Imaging;
using Microsoft.UI.Xaml.Shapes;
using Windows.Foundation;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.Services;

namespace Overnode.App.Views.EasterEgg;

public sealed partial class EasterEggMontageControl : UserControl
{
    private readonly LocalizationManager _loc = LocalizationManager.Instance;
    private readonly EasterEggAudioPlayer _audio = EasterEggAudioPlayer.Shared;
    private readonly EasterEggAssetManager _assets = EasterEggAssetManager.Shared;

    public event EventHandler? Dismissed;

    private readonly List<Rectangle> _visualizerRects = new();
    private readonly List<Image> _orbitingCats = new();
    private readonly List<Image> _rainCats = new();
    private int _clickCount;
    private bool _isInitialized;

    // Structure particule interactive
    private sealed class ActiveParticle
    {
        public FrameworkElement Element { get; set; } = null!;
        public double X { get; set; }
        public double Y { get; set; }
        public double Vx { get; set; }
        public double Vy { get; set; }
        public double Rotation { get; set; }
        public double RotationSpeed { get; set; }
        public DateTime CreatedAt { get; set; }
        public double LifespanSeconds { get; set; } = 1.8;
    }

    private readonly List<ActiveParticle> _particles = new();
    private readonly Random _rand = new();

    public EasterEggMontageControl()
    {
        InitializeComponent();
        _loc.LanguageChanged += (_, _) => UpdateLocalization();
        PointerPressed += OnContainerPointerPressed;
        SizeChanged += (_, _) => SetupLaserBeams();
    }

    public void InitializeAndStart()
    {
        _audio.SetDispatcherQueue(DispatcherQueue);
        _assets.PreloadImages();

        if (!_isInitialized)
        {
            SetupVisualizer();
            SetupPreloadedStageImages();
            SetupOrbitingSatellites();
            SetupRainCats();
            SetupLaserBeams();
            _isInitialized = true;
        }

        UpdateLocalization();

        _audio.PropertyChanged += OnAudioPropertyChanged;

        if (_audio.CurrentTime == 0)
        {
            _audio.Restart();
        }
        else
        {
            _audio.Play();
        }

        UpdateUI();
    }

    public void Close()
    {
        _audio.PropertyChanged -= OnAudioPropertyChanged;
        _audio.Stop();
        Visibility = Visibility.Collapsed;
        Dismissed?.Invoke(this, EventArgs.Empty);
    }

    private void UpdateLocalization()
    {
        PhaseTitleText.Text = _audio.CurrentPhase.GetTitle();
        QuitButtonText.Text = _loc.GetString("easteregg_quit_btn");
        IntroBannerText.Text = _loc.GetString("easteregg_intro_banner");
        IntroHintText.Text = _loc.GetString("easteregg_intro_hint");
        DancerJudgeText.Text = _loc.GetString("easteregg_dancer_judge");
        DancerBreakText.Text = _loc.GetString("easteregg_dancer_breakdancer");
        DancerPawText.Text = _loc.GetString("easteregg_dancer_velvet_paw");
        ChaosBannerText.Text = _loc.GetString("easteregg_chaos_banner");
        BadgeLagText.Text = _loc.GetString("easteregg_badge_lag_purr");
        BadgeSalmonText.Text = _loc.GetString("easteregg_badge_salmon");
        BadgeSiliconText.Text = _loc.GetString("easteregg_badge_silicon");
        VictoryTitleText.Text = _loc.GetString("easteregg_victory_title");
        VictoryDescText.Text = _loc.GetString("easteregg_victory_desc");
        RestartBtnText.Text = _loc.GetString("easteregg_restart_btn");
        BackSettingsBtnText.Text = _loc.GetString("easteregg_back_settings_btn");
        MeowButtonText.Text = _loc.GetString("easteregg_meow_btn");
        SummonedCountText.Text = _loc.Format("easteregg_summoned_count", _clickCount);
    }

    private void SetupVisualizer()
    {
        VisualizerContainer.Children.Clear();
        _visualizerRects.Clear();

        for (int i = 0; i < 16; i++)
        {
            var rect = new Rectangle
            {
                Width = 4,
                Height = 6,
                RadiusX = 2,
                RadiusY = 2,
                VerticalAlignment = VerticalAlignment.Bottom,
                Fill = new LinearGradientBrush
                {
                    StartPoint = new Windows.Foundation.Point(0, 1),
                    EndPoint = new Windows.Foundation.Point(0, 0),
                    GradientStops = new GradientStopCollection
                    {
                        new GradientStop { Color = ColorHelper.FromArgb(255, 233, 30, 99), Offset = 0 },
                        new GradientStop { Color = ColorHelper.FromArgb(255, 255, 235, 59), Offset = 0.5 },
                        new GradientStop { Color = ColorHelper.FromArgb(255, 0, 229, 255), Offset = 1 }
                    }
                }
            };
            _visualizerRects.Add(rect);
            VisualizerContainer.Children.Add(rect);
        }
    }

    private void SetupPreloadedStageImages()
    {
        // Phase Intro: Cat Loaf (2)
        IntroCatImage.Source = _assets.CatLoaf;

        // Phase Dancing: Judge (1), Breakdance (6), Long Paws (7)
        DancerJudgeImage.Source = _assets.CatJudge;
        DancerBreakImage.Source = _assets.CatBellyUp;
        DancerPawImage.Source = _assets.CatLongPaws;

        // Phase Oiia Spin: Extreme Zoom (5)
        OiiaSpinCatImage.Source = _assets.CatExtremeZoom ?? _assets.CatLoaf;

        // Phase Chaos: Corners
        ChaosCornerLeftImage.Source = _assets.CatStatue;
        ChaosCornerRightImage.Source = _assets.CatTilted;
        ChaosCenterImage.Source = _assets.CatLoaf;

        // Phase Victory: Handsome Cat (3)
        VictoryCatImage.Source = _assets.CatHandsome ?? _assets.CatLoaf;
    }

    private void SetupOrbitingSatellites()
    {
        SatellitesCanvas.Children.Clear();
        _orbitingCats.Clear();

        for (int i = 0; i < 8; i++)
        {
            int catIndex = (i % 12) + 1;
            var img = new Image
            {
                Width = 65,
                Height = 65,
                Stretch = Stretch.Uniform,
                Source = _assets.GetImageSource(catIndex),
                RenderTransformOrigin = new Windows.Foundation.Point(0.5, 0.5),
                RenderTransform = new CompositeTransform()
            };
            _orbitingCats.Add(img);
            SatellitesCanvas.Children.Add(img);
        }
    }

    private void SetupRainCats()
    {
        RainCanvas.Children.Clear();
        _rainCats.Clear();

        for (int col = 0; col < 9; col++)
        {
            int catIndex = (col % 12) + 1;
            var img = new Image
            {
                Width = 50,
                Height = 50,
                Opacity = 0.4,
                Stretch = Stretch.Uniform,
                Source = _assets.GetImageSource(catIndex),
                RenderTransformOrigin = new Windows.Foundation.Point(0.5, 0.5),
                RenderTransform = new CompositeTransform()
            };
            _rainCats.Add(img);
            RainCanvas.Children.Add(img);
        }
    }

    private readonly List<Line> _laserLines = new();

    private void SetupLaserBeams()
    {
        LaserCanvas.Children.Clear();
        _laserLines.Clear();

        for (int i = 0; i < 12; i++)
        {
            var line = new Line
            {
                StrokeThickness = 2,
                Stroke = new SolidColorBrush(ColorHelper.FromArgb(60, 255, 64, 129))
            };
            _laserLines.Add(line);
            LaserCanvas.Children.Add(line);
        }
    }

    private void OnAudioPropertyChanged(object? sender, System.ComponentModel.PropertyChangedEventArgs e)
    {
        DispatcherQueue.TryEnqueue(UpdateUI);
    }

    private void UpdateUI()
    {
        double t = _audio.CurrentTime;
        double pulse = _audio.BeatPulse;

        // Flash stroboscopique
        StrobeBorder.Opacity = (pulse > 1.18) ? 0.08 : 0.0;

        // Visualiseur 16 barres
        var bars = _audio.VisualizerBars;
        if (bars != null)
        {
            for (int i = 0; i < Math.Min(bars.Length, _visualizerRects.Count); i++)
            {
                _visualizerRects[i].Height = Math.Max(6, bars[i] * 28);
            }
        }

        // Titre de phase
        PhaseTitleText.Text = _audio.CurrentPhase.GetTitle();

        // Affichage de la phase
        StageIntro.Visibility = (_audio.CurrentPhase == EasterEggPhase.Intro) ? Visibility.Visible : Visibility.Collapsed;
        StageDancing.Visibility = (_audio.CurrentPhase == EasterEggPhase.Dancing) ? Visibility.Visible : Visibility.Collapsed;
        StageOiia.Visibility = (_audio.CurrentPhase == EasterEggPhase.OiiaSpin) ? Visibility.Visible : Visibility.Collapsed;
        StageChaos.Visibility = (_audio.CurrentPhase == EasterEggPhase.DiscoChaos) ? Visibility.Visible : Visibility.Collapsed;
        StageFinished.Visibility = (_audio.CurrentPhase == EasterEggPhase.Finished) ? Visibility.Visible : Visibility.Collapsed;

        // Pluie de chats (OiiaSpin + DiscoChaos)
        bool showRain = (_audio.CurrentPhase == EasterEggPhase.OiiaSpin || _audio.CurrentPhase == EasterEggPhase.DiscoChaos);
        RainCanvas.Visibility = showRain ? Visibility.Visible : Visibility.Collapsed;
        if (showRain)
        {
            UpdateRainAnimation(t);
        }

        // Animation spécifique à la phase
        switch (_audio.CurrentPhase)
        {
            case EasterEggPhase.Intro:
                ApplyScale(IntroCatImage, pulse);
                ApplyRotation(IntroHalo, t * 30);
                break;

            case EasterEggPhase.Dancing:
                ApplyRotation(DancerJudgeImage, Math.Sin(t * 14) * 22, pulse);
                ApplyRotation(DancerBreakImage, Math.Sin(t * 8) * 35, pulse * 1.1);
                ApplyTranslationX(DancerPawImage, Math.Sin(t * 6) * 25, pulse);
                UpdateMemeTicker(t);
                break;

            case EasterEggPhase.OiiaSpin:
                ApplyRotation(OiiaSpinCatImage, (t - 28.0) * 600, pulse * 1.15);
                UpdateOrbitingSatellites(t);
                break;

            case EasterEggPhase.DiscoChaos:
                int beatCatIdx = (_audio.BeatCount % 12) + 1;
                ChaosCenterImage.Source = _assets.GetImageSource(beatCatIdx);
                ApplyRotation(ChaosCenterImage, ((_audio.BeatCount % 4) - 2) * 8, pulse * 1.12);
                ApplyRotation(ChaosCornerLeftImage, Math.Sin(t * 10) * 25);
                ApplyRotation(ChaosCornerRightImage, -Math.Sin(t * 10) * 25);
                break;

            case EasterEggPhase.Finished:
                break;
        }

        // Lasers disco
        UpdateLasers(t, pulse);

        // Timeline
        TimelineProgress.Maximum = _audio.Duration > 0 ? _audio.Duration : 64.6;
        TimelineProgress.Value = Math.Clamp(t, 0.0, TimelineProgress.Maximum);

        double progressRatio = TimelineProgress.Maximum > 0 ? t / TimelineProgress.Maximum : 0.0;
        double progressWidth = ActualWidth > 48 ? ActualWidth - 48 : 800;
        CatCursorEmoji.Margin = new Thickness(Math.Max(0, progressRatio * progressWidth - 10), -4, 0, 0);

        CurrentTimeText.Text = FormatTime(t);
        DurationText.Text = FormatTime(_audio.Duration);
        PlayPauseIcon.Glyph = _audio.IsPlaying ? "\uE769" : "\uE768";

        // Mettre à jour les particules interactives
        UpdateParticles();
    }

    private void UpdateLasers(double t, double pulse)
    {
        double w = ActualWidth > 0 ? ActualWidth : 1180;
        double h = ActualHeight > 0 ? ActualHeight : 780;
        double cx = w / 2;
        double cy = h / 2;

        for (int i = 0; i < _laserLines.Count; i++)
        {
            double angle = (i * (Math.PI * 2.0 / _laserLines.Count)) + (t * 0.7);
            double cos = Math.Cos(angle);
            double sin = Math.Sin(angle);

            // Compute distance to boundary of [0, w] x [0, h] from center (cx, cy)
            double dist = double.MaxValue;
            if (cos > 1e-5) dist = Math.Min(dist, (w - cx) / cos);
            else if (cos < -1e-5) dist = Math.Min(dist, -cx / cos);

            if (sin > 1e-5) dist = Math.Min(dist, (h - cy) / sin);
            else if (sin < -1e-5) dist = Math.Min(dist, -cy / sin);

            if (dist == double.MaxValue || dist < 0) dist = Math.Min(cx, cy);

            var line = _laserLines[i];
            line.X1 = cx;
            line.Y1 = cy;
            line.X2 = Math.Clamp(cx + cos * dist, 0, w);
            line.Y2 = Math.Clamp(cy + sin * dist, 0, h);
            line.StrokeThickness = Math.Max(1.5, 3.0 * pulse);
        }
    }

    private void UpdateOrbitingSatellites(double t)
    {
        double radius = 230;
        double cx = StageOiia.ActualWidth > 0 ? StageOiia.ActualWidth / 2 : 300;
        double cy = StageOiia.ActualHeight > 0 ? StageOiia.ActualHeight / 2 : 250;

        for (int i = 0; i < _orbitingCats.Count; i++)
        {
            double angle = (i * (2.0 * Math.PI / _orbitingCats.Count)) - (t * 2.5);
            double x = cx + Math.Cos(angle) * radius - 32;
            double y = cy + Math.Sin(angle) * radius - 32;

            var img = _orbitingCats[i];
            Canvas.SetLeft(img, x);
            Canvas.SetTop(img, y);
            ApplyRotation(img, t * 360 + (i * 45));
        }
    }

    private void UpdateRainAnimation(double t)
    {
        double w = ActualWidth > 0 ? ActualWidth : 1000;
        double h = ActualHeight > 0 ? ActualHeight : 700;
        int cols = _rainCats.Count;
        double colWidth = w / cols;

        for (int col = 0; col < cols; col++)
        {
            double speed = 120.0 + ((col * 37) % 80);
            double offsetPhase = col * 53;
            double y = ((t * speed + offsetPhase) % (h + 200)) - 100;

            var img = _rainCats[col];
            Canvas.SetLeft(img, col * colWidth + (colWidth / 2) - 25);
            Canvas.SetTop(img, y);
            ApplyRotation(img, t * 120 + (col * 30));
        }
    }

    private void UpdateMemeTicker(double t)
    {
        var quotes = new[]
        {
            _loc.GetString("easteregg_quote_1"),
            _loc.GetString("easteregg_quote_2"),
            _loc.GetString("easteregg_quote_3"),
            _loc.GetString("easteregg_quote_4")
        };
        int idx = (int)(t / 3.5) % quotes.Length;
        MemeTickerText.Text = quotes[idx];
    }

    private static void ApplyScale(FrameworkElement elem, double scale)
    {
        elem.RenderTransformOrigin = new Windows.Foundation.Point(0.5, 0.5);
        if (elem.RenderTransform is CompositeTransform ct)
        {
            ct.ScaleX = scale;
            ct.ScaleY = scale;
        }
        else
        {
            elem.RenderTransform = new CompositeTransform { ScaleX = scale, ScaleY = scale };
        }
    }

    private static void ApplyRotation(FrameworkElement elem, double angleDegrees, double scale = 1.0)
    {
        elem.RenderTransformOrigin = new Windows.Foundation.Point(0.5, 0.5);
        if (elem.RenderTransform is CompositeTransform ct)
        {
            ct.Rotation = angleDegrees;
            ct.ScaleX = scale;
            ct.ScaleY = scale;
        }
        else
        {
            elem.RenderTransform = new CompositeTransform { Rotation = angleDegrees, ScaleX = scale, ScaleY = scale };
        }
    }

    private static void ApplyTranslationX(FrameworkElement elem, double tx, double scale = 1.0)
    {
        elem.RenderTransformOrigin = new Windows.Foundation.Point(0.5, 0.5);
        if (elem.RenderTransform is CompositeTransform ct)
        {
            ct.TranslateX = tx;
            ct.ScaleX = scale;
            ct.ScaleY = scale;
        }
        else
        {
            elem.RenderTransform = new CompositeTransform { TranslateX = tx, ScaleX = scale, ScaleY = scale };
        }
    }

    // GESTION PARTICULES INTERACTIVES (Clics souris)
    private void OnContainerPointerPressed(object sender, PointerRoutedEventArgs e)
    {
        var pt = e.GetCurrentPoint(ParticlesCanvas).Position;
        SpawnInteractiveCat(pt.X, pt.Y);
    }

    public void SpawnInteractiveCat(double x, double y)
    {
        _clickCount++;
        SummonedBadge.Visibility = Visibility.Visible;
        SummonedCountText.Text = _loc.Format("easteregg_summoned_count", _clickCount);

        int randomImg = _rand.Next(1, 13);
        double scale = 0.8 + _rand.NextDouble() * 0.5;

        var img = new Image
        {
            Width = 80 * scale,
            Height = 80 * scale,
            Stretch = Stretch.Uniform,
            Source = _assets.GetImageSource(randomImg),
            RenderTransformOrigin = new Windows.Foundation.Point(0.5, 0.5),
            RenderTransform = new CompositeTransform()
        };

        var p = new ActiveParticle
        {
            Element = img,
            X = x - (40 * scale),
            Y = y - (40 * scale),
            Vx = (_rand.NextDouble() * 80) - 40,
            Vy = -(_rand.NextDouble() * 60 + 30),
            Rotation = (_rand.NextDouble() * 60) - 30,
            RotationSpeed = (_rand.NextDouble() * 200) - 100,
            CreatedAt = DateTime.UtcNow
        };

        Canvas.SetLeft(img, p.X);
        Canvas.SetTop(img, p.Y);
        ParticlesCanvas.Children.Add(img);
        _particles.Add(p);
    }

    private void UpdateParticles()
    {
        var now = DateTime.UtcNow;
        for (int i = _particles.Count - 1; i >= 0; i--)
        {
            var p = _particles[i];
            double elapsed = (now - p.CreatedAt).TotalSeconds;
            if (elapsed >= p.LifespanSeconds)
            {
                ParticlesCanvas.Children.Remove(p.Element);
                _particles.RemoveAt(i);
                continue;
            }

            p.X += p.Vx * 0.016;
            p.Y += p.Vy * 0.016;
            p.Rotation += p.RotationSpeed * 0.016;

            Canvas.SetLeft(p.Element, p.X);
            Canvas.SetTop(p.Element, p.Y);
            p.Element.Opacity = Math.Max(0.0, 1.0 - (elapsed / p.LifespanSeconds));

            if (p.Element.RenderTransform is CompositeTransform ct)
            {
                ct.Rotation = p.Rotation;
            }
        }
    }

    private void OnPlayPauseClicked(object sender, RoutedEventArgs e)
    {
        _audio.Toggle();
    }

    private void OnMeowClicked(object sender, RoutedEventArgs e)
    {
        double cx = ActualWidth > 0 ? ActualWidth / 2 : 500;
        double cy = ActualHeight > 0 ? ActualHeight / 2 : 350;

        for (int i = 0; i < 5; i++)
        {
            SpawnInteractiveCat(cx + _rand.Next(-120, 120), cy + _rand.Next(-120, 120));
        }
    }

    private void OnRestartClicked(object sender, RoutedEventArgs e)
    {
        _audio.Restart();
    }

    private void OnQuitClicked(object sender, RoutedEventArgs e)
    {
        Close();
    }

    private static string FormatTime(double seconds)
    {
        int totalSecs = (int)Math.Max(0, seconds);
        int mins = totalSecs / 60;
        int secs = totalSecs % 60;
        return $"{mins:D2}:{secs:D2}";
    }
}
