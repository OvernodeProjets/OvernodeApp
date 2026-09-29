using System;
using System.Collections.Generic;
using System.Text.Json;
using Overnode.App.Models;

namespace Overnode.Tests;

public class SecondaryModulesTests
{
    public void Test_Wallet_Models_And_Balances()
    {
        string json = """
        {
            "balances": {
                "coins": 1500,
                "credit_eur": 12.50
            },
            "coin_packages": [
                { "amount": 500, "price_eur": 4.99 },
                { "amount": 1000, "price_eur": 8.99 }
            ]
        }
        """;

        var billingInfo = JsonSerializer.Deserialize<BillingInfo>(json);
        Assert.IsNotNull(billingInfo);
        Assert.IsNotNull(billingInfo.Balances);
        Assert.AreEqual(1500, billingInfo.Balances.Coins);
        Assert.AreEqual(12.50, billingInfo.Balances.CreditEur);
        Assert.IsNotNull(billingInfo.CoinPackages);
        Assert.AreEqual(2, billingInfo.CoinPackages.Count);
        Assert.AreEqual(500, billingInfo.CoinPackages[0].Amount);
    }

    public void Test_DailyReward_Models_And_Status()
    {
        string json = """
        {
            "canClaim": true,
            "currentStreak": 7,
            "longestStreak": 14,
            "totalCoinsEarned": 850,
            "nextReward": {
                "amount": 50,
                "baseAmount": 25,
                "multiplier": 1.5,
                "milestoneBonus": 10,
                "milestoneMessage": "Bonus Série 7 jours !"
            }
        }
        """;

        var status = JsonSerializer.Deserialize<DailyRewardStatus>(json);
        Assert.IsNotNull(status);
        Assert.IsTrue(status.CanClaim);
        Assert.AreEqual(7, status.CurrentStreak);
        Assert.AreEqual(14, status.LongestStreak);
        Assert.IsNotNull(status.NextReward);
        Assert.AreEqual(50, status.NextReward.Amount);
        Assert.AreEqual("Bonus Série 7 jours !", status.NextReward.MilestoneMessage);
    }

    public void Test_Store_Pricing_And_Bundles()
    {
        string json = """
        {
            "prices": {
                "resources": {
                    "ram": 600,
                    "disk": 400,
                    "cpu": 500,
                    "servers": 200
                }
            }
        }
        """;

        var storeConfig = JsonSerializer.Deserialize<StoreConfigResponse>(json);
        Assert.IsNotNull(storeConfig);
        Assert.IsNotNull(storeConfig.Prices);
        Assert.IsNotNull(storeConfig.Prices.Resources);
        Assert.AreEqual(600, storeConfig.Prices.Resources["ram"]);
        Assert.AreEqual(400, storeConfig.Prices.Resources["disk"]);
        Assert.AreEqual(500, storeConfig.Prices.Resources["cpu"]);
        Assert.AreEqual(200, storeConfig.Prices.Resources["servers"]);

        var bundle = new StoreBundle("b1", "Starter Pack", "9.99 €", "/ mois", "Idéal pour débuter", new List<string> { "2 GB RAM", "1 VCore" }, "\uE719", "#F59E0B");
        Assert.AreEqual("Starter Pack", bundle.Title);
        Assert.AreEqual(2, bundle.Features.Count);
    }

    public void Test_Support_Ticket_Models()
    {
        var ticket = new SupportTicket
        {
            Id = "TICK-101",
            Subject = "Problème RAM",
            Category = "Serveurs",
            Status = "open",
            CreatedAt = "2026-09-29 12:00"
        };

        ticket.Messages.Add(new TicketMessage
        {
            Id = "MSG-1",
            Sender = "Hugo",
            Content = "Bonjour, mon serveur manque de RAM",
            IsStaff = false,
            CreatedAt = "12:00"
        });

        ticket.Messages.Add(new TicketMessage
        {
            Id = "MSG-2",
            Sender = "Support Overnode",
            Content = "Nous venons d'ajuster votre quota.",
            IsStaff = true,
            CreatedAt = "12:05"
        });

        Assert.AreEqual("TICK-101", ticket.Id);
        Assert.AreEqual(2, ticket.Messages.Count);
        Assert.IsFalse(ticket.Messages[0].IsStaff);
        Assert.IsTrue(ticket.Messages[1].IsStaff);
    }

    public void Test_NavigationTabs_And_Glyphs()
    {
        Assert.AreEqual("nav_dashboard", NavigationTab.Dashboard.ToKey());
        Assert.AreEqual("nav_servers", NavigationTab.Servers.ToKey());
        Assert.AreEqual("nav_wallet", NavigationTab.Wallet.ToKey());
        Assert.AreEqual("nav_daily_reward", NavigationTab.DailyReward.ToKey());
        Assert.AreEqual("nav_store", NavigationTab.Store.ToKey());
        Assert.AreEqual("nav_support", NavigationTab.Support.ToKey());
        Assert.AreEqual("nav_afk", NavigationTab.Afk.ToKey());
        Assert.AreEqual("nav_settings", NavigationTab.Settings.ToKey());

        Assert.AreEqual("\uE80F", NavigationTab.Dashboard.ToGlyph());
        Assert.AreEqual("\uE7F8", NavigationTab.Servers.ToGlyph());
        Assert.AreEqual("\uE8C7", NavigationTab.Wallet.ToGlyph());
        Assert.AreEqual("\uE8F8", NavigationTab.DailyReward.ToGlyph());
        Assert.AreEqual("\uE719", NavigationTab.Store.ToGlyph());
        Assert.AreEqual("\uE8BD", NavigationTab.Support.ToGlyph());
        Assert.AreEqual("\uE823", NavigationTab.Afk.ToGlyph());
        Assert.AreEqual("\uE713", NavigationTab.Settings.ToGlyph());
    }
}
