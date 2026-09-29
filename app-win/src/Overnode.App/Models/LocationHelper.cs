using System;
using System.Linq;
using Overnode.App.Localization;

namespace Overnode.App.Models;

public record FormattedLocationInfo(
    string Flag,
    string CountryName,
    string RegionName,
    string DefaultCity,
    string PingText
);

public record FormattedNodeInfo(
    string DisplayName,
    string City,
    string Tag,
    string IconGlyph
);

public static class LocationHelper
{
    public static FormattedLocationInfo Format(ServerLocation location)
    {
        var raw = (location.Name ?? string.Empty).Trim().ToLowerInvariant();
        var idRaw = (location.Id ?? string.Empty).Trim().ToLowerInvariant();
        var flags = location.Flags ?? new();

        bool isFr = raw == "fr" || raw.Contains("france") || idRaw == "fr" || flags.Any(f => f.Equals("fr", StringComparison.OrdinalIgnoreCase));
        bool isUs = raw == "us" || raw.Contains("united states") || raw.Contains("usa") || idRaw == "us" || flags.Any(f => f.Equals("us", StringComparison.OrdinalIgnoreCase));
        bool isDe = raw == "de" || raw.Contains("germany") || raw.Contains("allemagne") || idRaw == "de" || flags.Any(f => f.Equals("de", StringComparison.OrdinalIgnoreCase));
        bool isCa = raw == "ca" || raw.Contains("canada") || idRaw == "ca" || flags.Any(f => f.Equals("ca", StringComparison.OrdinalIgnoreCase));
        bool isGb = raw == "gb" || raw == "uk" || raw.Contains("kingdom") || idRaw == "gb" || flags.Any(f => f.Equals("gb", StringComparison.OrdinalIgnoreCase));

        bool isFrench = LocalizationManager.Instance.CurrentLanguage == AppLanguage.Fr;

        if (isFr)
        {
            return new FormattedLocationInfo(
                "🇫🇷",
                "France",
                isFrench ? "Europe Ouest • Gravelines / Marseille" : "EU West • Gravelines / Marseille",
                "Marseille",
                "< 15 ms"
            );
        }
        if (isUs)
        {
            return new FormattedLocationInfo(
                "🇺🇸",
                isFrench ? "États-Unis" : "United States",
                isFrench ? "Amérique du Nord • New York" : "US East • New York",
                "New York",
                "< 75 ms"
            );
        }
        if (isDe)
        {
            return new FormattedLocationInfo(
                "🇩🇪",
                isFrench ? "Allemagne" : "Germany",
                isFrench ? "Europe Centrale • Francfort" : "Central Europe • Frankfurt",
                "Francfort",
                "< 22 ms"
            );
        }
        if (isCa)
        {
            return new FormattedLocationInfo(
                "🇨🇦",
                "Canada",
                isFrench ? "Amérique du Nord • Beauharnois" : "North America • Beauharnois",
                "Beauharnois",
                "< 80 ms"
            );
        }
        if (isGb)
        {
            return new FormattedLocationInfo(
                "🇬🇧",
                isFrench ? "Royaume-Uni" : "United Kingdom",
                isFrench ? "Europe Ouest • Londres" : "Western Europe • London",
                "Londres",
                "< 20 ms"
            );
        }

        string fallbackName = string.IsNullOrEmpty(location.Name) ? (isFrench ? "Datacenter Cloud" : "Cloud Datacenter") : location.Name;
        return new FormattedLocationInfo(
            "🌐",
            fallbackName,
            string.IsNullOrEmpty(location.Description) ? "Global Cloud Network" : location.Description,
            "Datacenter",
            "< 30 ms"
        );
    }

    public static FormattedNodeInfo Format(ServerNode node)
    {
        var rawName = (node.Name ?? string.Empty).ToLowerInvariant();
        string city = "Datacenter";
        string tag = "Tier III";

        if (rawName.Contains("mrs"))
        {
            city = "Marseille";
            tag = "Game Anti-DDoS";
        }
        else if (rawName.Contains("par"))
        {
            city = "Paris";
            tag = "NVMe Fast";
        }
        else if (rawName.Contains("gra"))
        {
            city = "Gravelines";
            tag = "Anti-DDoS Pro";
        }
        else if (rawName.Contains("rbx"))
        {
            city = "Roubaix";
            tag = "Anti-DDoS Pro";
        }
        else if (rawName.Contains("nyc"))
        {
            city = "New York";
            tag = "US Tier III";
        }
        else if (rawName.Contains("chi"))
        {
            city = "Chicago";
            tag = "Low Latency";
        }
        else if (rawName.Contains("fra"))
        {
            city = "Francfort";
            tag = "Central Hub";
        }
        else if (rawName.Contains("bhs"))
        {
            city = "Beauharnois";
            tag = "Game DDoS";
        }
        else if (!string.IsNullOrEmpty(node.Fqdn))
        {
            city = node.Fqdn;
            tag = "Online";
        }

        return new FormattedNodeInfo(
            string.IsNullOrEmpty(node.Name) ? $"Node #{node.Id}" : node.Name,
            city,
            tag,
            "\uE945" // Bolt / Lightning
        );
    }

    public static bool IsMatch(ServerNode node, ServerLocation location)
    {
        var nLoc = (node.LocationId ?? string.Empty).Trim().ToLowerInvariant();
        var nName = (node.Name ?? string.Empty).Trim().ToLowerInvariant();
        var locId = (location.Id ?? string.Empty).Trim().ToLowerInvariant();
        var locName = (location.Name ?? string.Empty).Trim().ToLowerInvariant();

        // Direct ID match
        if (!string.IsNullOrEmpty(locId) && !string.IsNullOrEmpty(nLoc) && nLoc == locId) return true;
        if (!string.IsNullOrEmpty(locName) && !string.IsNullOrEmpty(nLoc) && nLoc == locName) return true;
        if (!string.IsNullOrEmpty(locId) && nName.StartsWith(locId + ".")) return true;
        if (!string.IsNullOrEmpty(locName) && nName.StartsWith(locName + ".")) return true;
        if (location.Flags != null && location.Flags.Any(f => f.Trim().Equals(nLoc, StringComparison.OrdinalIgnoreCase))) return true;

        // If both have numeric IDs that don't match, they belong to different datacenters
        if (int.TryParse(nLoc, out int nLocInt) && int.TryParse(locId, out int locIdInt))
        {
            return nLocInt == locIdInt;
        }

        // Heuristics based on country & datacenter abbreviations
        bool locIsFrance = locId == "fr" || locName.Contains("france") || locName.Contains("gravelines") || locName.Contains("marseille") || locName.Contains("paris") || (location.Flags != null && location.Flags.Any(f => f.Equals("fr", StringComparison.OrdinalIgnoreCase)));
        if (locIsFrance)
        {
            if (nLoc == "fr" || nLoc.Contains("france") || nName.Contains("-fr") || nName.Contains("fr-") || nName.Contains("gra") || nName.Contains("mrs") || nName.Contains("par") || nName.Contains("rbx"))
                return true;
        }

        bool locIsGermany = locId == "de" || locName.Contains("germany") || locName.Contains("allemagne") || locName.Contains("frankfurt") || locName.Contains("francfort") || (location.Flags != null && location.Flags.Any(f => f.Equals("de", StringComparison.OrdinalIgnoreCase)));
        if (locIsGermany)
        {
            if (nLoc == "de" || nLoc.Contains("germany") || nName.Contains("-de") || nName.Contains("de-") || nName.Contains("fra"))
                return true;
        }

        bool locIsUs = locId == "us" || locName.Contains("united states") || locName.Contains("usa") || locName.Contains("new york") || (location.Flags != null && location.Flags.Any(f => f.Equals("us", StringComparison.OrdinalIgnoreCase)));
        if (locIsUs)
        {
            if (nLoc == "us" || nLoc.Contains("usa") || nName.Contains("-us") || nName.Contains("us-") || nName.Contains("nyc") || nName.Contains("chi"))
                return true;
        }

        bool locIsCanada = locId == "ca" || locName.Contains("canada") || locName.Contains("beauharnois") || (location.Flags != null && location.Flags.Any(f => f.Equals("ca", StringComparison.OrdinalIgnoreCase)));
        if (locIsCanada)
        {
            if (nLoc == "ca" || nLoc.Contains("canada") || nName.Contains("-ca") || nName.Contains("ca-") || nName.Contains("bhs"))
                return true;
        }

        return false;
    }
}
