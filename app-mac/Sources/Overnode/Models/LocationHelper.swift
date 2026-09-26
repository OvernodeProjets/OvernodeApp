import Foundation

public struct FormattedLocationInfo: Sendable {
    public let flag: String
    public let countryName: String
    public let regionName: String
    public let defaultCity: String
    public let pingText: String
}

public struct FormattedNodeInfo: Sendable {
    public let displayName: String
    public let city: String
    public let tag: String
    public let icon: String
}

@MainActor
public enum LocationHelper {
    public static func format(location: ServerLocation) -> FormattedLocationInfo {
        let raw = location.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let idRaw = location.id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let isFr = raw == "fr" || raw.contains("france") || idRaw == "fr" || location.flags.contains(where: { $0.lowercased() == "fr" })
        let isUs = raw == "us" || raw.contains("united states") || raw.contains("usa") || idRaw == "us" || location.flags.contains(where: { $0.lowercased() == "us" })
        let isDe = raw == "de" || raw.contains("germany") || raw.contains("allemagne") || idRaw == "de" || location.flags.contains(where: { $0.lowercased() == "de" })
        let isCa = raw == "ca" || raw.contains("canada") || idRaw == "ca" || location.flags.contains(where: { $0.lowercased() == "ca" })
        let isGb = raw == "gb" || raw == "uk" || raw.contains("kingdom") || idRaw == "gb" || location.flags.contains(where: { $0.lowercased() == "gb" })
        
        let isFrenchApp = LocalizationManager.shared.currentLanguage == .french
        
        if isFr {
            return FormattedLocationInfo(
                flag: "🇫🇷",
                countryName: isFrenchApp ? "France" : "France",
                regionName: isFrenchApp ? "Europe Ouest • Gravelines / Marseille" : "EU West • Gravelines / Marseille",
                defaultCity: "Marseille",
                pingText: "< 15 ms"
            )
        } else if isUs {
            return FormattedLocationInfo(
                flag: "🇺🇸",
                countryName: isFrenchApp ? "États-Unis" : "United States",
                regionName: isFrenchApp ? "Amérique du Nord • New York" : "US East • New York",
                defaultCity: "New York",
                pingText: "< 75 ms"
            )
        } else if isDe {
            return FormattedLocationInfo(
                flag: "🇩🇪",
                countryName: isFrenchApp ? "Allemagne" : "Germany",
                regionName: isFrenchApp ? "Europe Centrale • Francfort" : "Central Europe • Frankfurt",
                defaultCity: "Francfort",
                pingText: "< 22 ms"
            )
        } else if isCa {
            return FormattedLocationInfo(
                flag: "🇨🇦",
                countryName: "Canada",
                regionName: isFrenchApp ? "Amérique du Nord • Beauharnois" : "North America • Beauharnois",
                defaultCity: "Beauharnois",
                pingText: "< 80 ms"
            )
        } else if isGb {
            return FormattedLocationInfo(
                flag: "🇬🇧",
                countryName: isFrenchApp ? "Royaume-Uni" : "United Kingdom",
                regionName: isFrenchApp ? "Europe Ouest • Londres" : "Western Europe • London",
                defaultCity: "Londres",
                pingText: "< 20 ms"
            )
        }
        
        // Fallback for custom or backend-provided detailed names
        let fallbackName = location.name.isEmpty ? (isFrenchApp ? "Datacenter Cloud" : "Cloud Datacenter") : location.name
        return FormattedLocationInfo(
            flag: "🌐",
            countryName: fallbackName,
            regionName: location.description.isEmpty ? (isFrenchApp ? "Global Cloud Network" : "Global Cloud Network") : location.description,
            defaultCity: "Datacenter",
            pingText: "< 30 ms"
        )
    }
    
    public static func format(node: ServerNode) -> FormattedNodeInfo {
        let rawName = node.name.lowercased()
        
        var city = "Datacenter"
        var tag = "Tier III"
        
        if rawName.contains("mrs") {
            city = "Marseille"
            tag = "Game Anti-DDoS"
        } else if rawName.contains("par") {
            city = "Paris"
            tag = "NVMe Fast"
        } else if rawName.contains("gra") {
            city = "Gravelines"
            tag = "Anti-DDoS Pro"
        } else if rawName.contains("rbx") {
            city = "Roubaix"
            tag = "Anti-DDoS Pro"
        } else if rawName.contains("nyc") {
            city = "New York"
            tag = "US Tier III"
        } else if rawName.contains("chi") {
            city = "Chicago"
            tag = "Low Latency"
        } else if rawName.contains("fra") {
            city = "Francfort"
            tag = "Central Hub"
        } else if rawName.contains("bhs") {
            city = "Beauharnois"
            tag = "Game DDoS"
        }
        
        return FormattedNodeInfo(
            displayName: node.name,
            city: city,
            tag: tag,
            icon: "bolt.fill"
        )
    }
    
    public static func isMatch(node: ServerNode, location: ServerLocation) -> Bool {
        let nLoc = node.locationId.lowercased()
        let nName = node.name.lowercased()
        let locId = location.id.lowercased()
        let locName = location.name.lowercased()
        
        if !locId.isEmpty && nLoc == locId { return true }
        if !locName.isEmpty && nLoc == locName { return true }
        if !locId.isEmpty && nName.hasPrefix(locId + ".") { return true }
        if !locName.isEmpty && nName.hasPrefix(locName + ".") { return true }
        if location.flags.contains(where: { $0.lowercased() == nLoc }) { return true }
        
        return false
    }
}
