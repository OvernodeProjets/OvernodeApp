using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Runtime.CompilerServices;
using System.Threading;
using Microsoft.UI.Dispatching;
using Overnode.App.Localization;
using Overnode.App.Models;

namespace Overnode.App.Services;

/// <summary>
/// Lecteur audio et métronome synchronisé pour le morceau "Dancing Rat x OIIA Cat" (137 BPM).
/// </summary>
public sealed class EasterEggAudioPlayer : INotifyPropertyChanged
{
    private static readonly Lazy<EasterEggAudioPlayer> _lazy = new(() => new EasterEggAudioPlayer());
    public static EasterEggAudioPlayer Shared => _lazy.Value;

    public event PropertyChangedEventHandler? PropertyChanged;

    private bool _isPlaying;
    private double _currentTime;
    private double _duration = 64.60;
    private EasterEggPhase _currentPhase = EasterEggPhase.Intro;
    private double _beatPulse = 1.0;
    private int _beatCount;
    private double[] _visualizerBars = new double[16];

    private Windows.Media.Playback.MediaPlayer? _mediaPlayer;
    private Timer? _timer;
    private readonly Stopwatch _simStopwatch = new();
    private double _simBaseTime;
    private readonly double _bpm = 137.0;
    private double BeatInterval => 60.0 / _bpm;

    private DispatcherQueue? _dispatcherQueue;

    public bool IsPlaying
    {
        get => _isPlaying;
        private set => SetField(ref _isPlaying, value);
    }

    public double CurrentTime
    {
        get => _currentTime;
        private set => SetField(ref _currentTime, value);
    }

    public double Duration
    {
        get => _duration;
        private set => SetField(ref _duration, value);
    }

    public EasterEggPhase CurrentPhase
    {
        get => _currentPhase;
        private set => SetField(ref _currentPhase, value);
    }

    public double BeatPulse
    {
        get => _beatPulse;
        private set => SetField(ref _beatPulse, value);
    }

    public int BeatCount
    {
        get => _beatCount;
        private set => SetField(ref _beatCount, value);
    }

    public double[] VisualizerBars
    {
        get => _visualizerBars;
        private set => SetField(ref _visualizerBars, value);
    }

    public EasterEggAudioPlayer()
    {
        for (int i = 0; i < 16; i++)
        {
            _visualizerBars[i] = 0.2;
        }

        try
        {
            _dispatcherQueue = DispatcherQueue.GetForCurrentThread();
        }
        catch { }

        PrepareAudio();
    }

    public void SetDispatcherQueue(DispatcherQueue? dispatcher)
    {
        if (dispatcher != null)
        {
            _dispatcherQueue = dispatcher;
        }
    }

    public void PrepareAudio()
    {
        var audioUri = EasterEggAssetManager.Shared.AudioUri;
        if (audioUri == null) return;

        try
        {
            if (_mediaPlayer == null)
            {
                _mediaPlayer = new Windows.Media.Playback.MediaPlayer
                {
                    AutoPlay = false
                };
                _mediaPlayer.MediaEnded += (s, e) =>
                {
                    ExecuteOnUI(() =>
                    {
                        IsPlaying = false;
                        CurrentPhase = EasterEggPhase.Finished;
                        StopTimer();
                    });
                };
            }

            _mediaPlayer.Source = Windows.Media.Core.MediaSource.CreateFromUri(audioUri);
        }
        catch
        {
            // Environnement sans audio ou WinRT headless
            _mediaPlayer = null;
        }
    }

    public void Play()
    {
        if (IsPlaying) return;

        if (_mediaPlayer == null)
        {
            PrepareAudio();
        }

        try
        {
            if (_mediaPlayer != null)
            {
                _mediaPlayer.PlaybackSession.Position = TimeSpan.FromSeconds(CurrentTime);
                _mediaPlayer.Play();
            }
        }
        catch
        {
            // Fallback vers horloge simulateur
        }

        _simBaseTime = CurrentTime;
        _simStopwatch.Restart();
        IsPlaying = true;
        StartTimer();
    }

    public void Pause()
    {
        try
        {
            _mediaPlayer?.Pause();
        }
        catch { }

        _simStopwatch.Stop();
        IsPlaying = false;
        StopTimer();
    }

    public void Stop()
    {
        try
        {
            if (_mediaPlayer != null)
            {
                _mediaPlayer.Pause();
                _mediaPlayer.PlaybackSession.Position = TimeSpan.Zero;
            }
        }
        catch { }

        _simStopwatch.Reset();
        _simBaseTime = 0.0;
        CurrentTime = 0.0;
        IsPlaying = false;
        CurrentPhase = EasterEggPhase.Intro;
        BeatPulse = 1.0;
        StopTimer();
    }

    public void Restart()
    {
        Stop();
        Play();
    }

    public void Toggle()
    {
        if (IsPlaying)
        {
            Pause();
        }
        else
        {
            Play();
        }
    }

    public void Seek(double seconds)
    {
        var clamped = Math.Clamp(seconds, 0.0, Duration);
        CurrentTime = clamped;
        _simBaseTime = clamped;
        if (_simStopwatch.IsRunning)
        {
            _simStopwatch.Restart();
        }

        try
        {
            if (_mediaPlayer != null)
            {
                _mediaPlayer.PlaybackSession.Position = TimeSpan.FromSeconds(clamped);
            }
        }
        catch { }

        UpdatePlaybackState();
    }

    private void StartTimer()
    {
        StopTimer();
        // ~60 FPS (16ms)
        _timer = new Timer(_ =>
        {
            ExecuteOnUI(UpdatePlaybackState);
        }, null, 0, 16);
    }

    private void StopTimer()
    {
        _timer?.Dispose();
        _timer = null;
    }

    private void UpdatePlaybackState()
    {
        if (!IsPlaying) return;

        double t = _simBaseTime + _simStopwatch.Elapsed.TotalSeconds;

        try
        {
            if (_mediaPlayer != null && _mediaPlayer.PlaybackSession.PlaybackState == Windows.Media.Playback.MediaPlaybackState.Playing)
            {
                var pos = _mediaPlayer.PlaybackSession.Position.TotalSeconds;
                if (pos > 0)
                {
                    t = pos;
                }
                var dur = _mediaPlayer.PlaybackSession.NaturalDuration.TotalSeconds;
                if (dur > 0 && Math.Abs(Duration - dur) > 0.5)
                {
                    Duration = dur;
                }
            }
        }
        catch { }

        CurrentTime = t;

        // Calcul de la phase courante
        if (t < 14.0)
        {
            CurrentPhase = EasterEggPhase.Intro;
        }
        else if (t < 28.0)
        {
            CurrentPhase = EasterEggPhase.Dancing;
        }
        else if (t < 45.0)
        {
            CurrentPhase = EasterEggPhase.OiiaSpin;
        }
        else if (t < Duration)
        {
            CurrentPhase = EasterEggPhase.DiscoChaos;
        }
        else
        {
            CurrentPhase = EasterEggPhase.Finished;
            IsPlaying = false;
            StopTimer();
            return;
        }

        // Métronome 137 BPM
        double phaseInBeat = (t % BeatInterval) / BeatInterval;
        double attackDecay = Math.Max(0.0, 1.0 - phaseInBeat * 3.0);
        BeatPulse = 1.0 + (attackDecay * 0.22);
        BeatCount = (int)(t / BeatInterval);

        // Visualiseur 16 barres
        var bars = new double[16];
        for (int i = 0; i < 16; i++)
        {
            double offset = i * 0.4;
            double wave = Math.Sin(t * 12.0 + offset) * 0.4 + 0.5;
            double pulseFactor = (attackDecay > 0.1) ? 0.3 : 0.0;
            bars[i] = Math.Min(1.0, Math.Max(0.15, wave + pulseFactor));
        }
        VisualizerBars = bars;
    }

    private void ExecuteOnUI(Action action)
    {
        if (_dispatcherQueue != null && !_dispatcherQueue.HasThreadAccess)
        {
            _dispatcherQueue.TryEnqueue(() => action());
        }
        else
        {
            action();
        }
    }

    private void SetField<T>(ref T field, T value, [CallerMemberName] string? propertyName = null)
    {
        if (!EqualityComparer<T>.Default.Equals(field, value))
        {
            field = value;
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
