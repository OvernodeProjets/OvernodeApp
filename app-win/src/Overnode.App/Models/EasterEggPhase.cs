using System;
using Overnode.App.Localization;

namespace Overnode.App.Models;

/// <summary>
/// Phase chronologique du montage de l'Easter Egg (durée totale : ~64.6s).
/// </summary>
public enum EasterEggPhase
{
    Intro,      // 00.0s - 14.0s : L'éveil du chat suprême
    Dancing,    // 14.0s - 28.0s : Dancing Rat groove
    OiiaSpin,   // 28.0s - 45.0s : Oiia Oiia Turbo
    DiscoChaos, // 45.0s - 64.6s : Chaos Disco Total
    Finished    // 64.6s+        : Célébration finale / Victoire
}

public static class EasterEggPhaseExtensions
{
    public static string GetTitle(this EasterEggPhase phase)
    {
        var loc = LocalizationManager.Instance;
        return phase switch
        {
            EasterEggPhase.Intro => loc.GetString("easteregg_phase_intro_title"),
            EasterEggPhase.Dancing => loc.GetString("easteregg_phase_dancing_title"),
            EasterEggPhase.OiiaSpin => loc.GetString("easteregg_phase_oiia_title"),
            EasterEggPhase.DiscoChaos => loc.GetString("easteregg_phase_chaos_title"),
            EasterEggPhase.Finished => loc.GetString("easteregg_phase_finished_title"),
            _ => string.Empty
        };
    }

    public static string GetSubtitle(this EasterEggPhase phase)
    {
        var loc = LocalizationManager.Instance;
        return phase switch
        {
            EasterEggPhase.Intro => loc.GetString("easteregg_phase_intro_sub"),
            EasterEggPhase.Dancing => loc.GetString("easteregg_phase_dancing_sub"),
            EasterEggPhase.OiiaSpin => loc.GetString("easteregg_phase_oiia_sub"),
            EasterEggPhase.DiscoChaos => loc.GetString("easteregg_phase_chaos_sub"),
            EasterEggPhase.Finished => loc.GetString("easteregg_phase_finished_sub"),
            _ => string.Empty
        };
    }
}
