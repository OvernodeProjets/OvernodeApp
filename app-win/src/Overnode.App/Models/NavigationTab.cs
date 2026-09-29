using System;

namespace Overnode.App.Models;

public enum NavigationTab
{
    Dashboard,
    Servers,
    Wallet,
    DailyReward,
    Store,
    Support,
    Afk,
    Settings
}

public static class NavigationTabExtensions
{
    public static string ToKey(this NavigationTab tab) => tab switch
    {
        NavigationTab.Dashboard => "nav_dashboard",
        NavigationTab.Servers => "nav_servers",
        NavigationTab.Wallet => "nav_wallet",
        NavigationTab.DailyReward => "nav_daily_reward",
        NavigationTab.Store => "nav_store",
        NavigationTab.Support => "nav_support",
        NavigationTab.Afk => "nav_afk",
        NavigationTab.Settings => "nav_settings",
        _ => "nav_dashboard"
    };

    public static string ToGlyph(this NavigationTab tab) => tab switch
    {
        NavigationTab.Dashboard => "\uE80F", // ViewDashboard / Grid
        NavigationTab.Servers => "\uE7F8", // ServerRack
        NavigationTab.Wallet => "\uE8C7", // PaymentCard
        NavigationTab.DailyReward => "\uE8F8", // Gift
        NavigationTab.Store => "\uE719", // Shop
        NavigationTab.Support => "\uE8BD", // Chat
        NavigationTab.Afk => "\uE823", // Recent / Clock
        NavigationTab.Settings => "\uE713", // Setting
        _ => "\uE80F"
    };
}
