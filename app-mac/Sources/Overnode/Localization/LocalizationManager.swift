import Foundation
import SwiftUI
import Combine

public enum AppLanguage: String, CaseIterable, Identifiable {
    case french = "fr"
    case english = "en"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .french: return "Français"
        case .english: return "English"
        }
    }
    
    public var flag: String {
        switch self {
        case .french: return "🇫🇷"
        case .english: return "🇬🇧"
        }
    }
}

public extension Bundle {
    static func appResourceURL(named name: String, withExtension ext: String) -> URL? {
        // 1. Direct inside Bundle.main (in .app Contents/Resources)
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            return url
        }
        // 2. Explicit in Contents/Resources
        if let resURL = Bundle.main.resourceURL?.appendingPathComponent("\(name).\(ext)"),
           FileManager.default.fileExists(atPath: resURL.path) {
            return resURL
        }
        // 3. Fallback inside app root directory or bundle subfolder
        let candidates = [
            Bundle.main.bundleURL.appendingPathComponent("\(name).\(ext)"),
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/\(name).\(ext)"),
            Bundle.main.bundleURL.appendingPathComponent("Overnode_Overnode.bundle/\(name).\(ext)"),
            Bundle.main.resourceURL?.appendingPathComponent("Overnode_Overnode.bundle/\(name).\(ext)")
        ]
        for c in candidates {
            if let url = c, FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        // 4. Development / test path fallback
        let devPaths = [
            "Sources/Overnode/Resources/\(name).\(ext)",
            "app/Sources/Overnode/Resources/\(name).\(ext)",
            "../Sources/Overnode/Resources/\(name).\(ext)"
        ]
        for p in devPaths {
            let u = URL(fileURLWithPath: p)
            if FileManager.default.fileExists(atPath: u.path) {
                return u
            }
        }
        return nil
    }
}

@MainActor
public final class LocalizationManager: ObservableObject {
    public static let shared = LocalizationManager()
    
    @Published public private(set) var currentLanguage: AppLanguage = .french
    @Published private var strings: [String: String] = [:]
    
    private let userDefaultsKey = "overnode_app_language"
    
    private init() {
        if let savedLang = UserDefaults.standard.string(forKey: userDefaultsKey),
           let lang = AppLanguage(rawValue: savedLang) {
            self.currentLanguage = lang
        } else {
            let preferred = Locale.preferredLanguages.first ?? "fr"
            self.currentLanguage = preferred.starts(with: "en") ? .english : .french
        }
        loadStrings(for: currentLanguage)
    }
    
    public func setLanguage(_ language: AppLanguage) {
        guard language != currentLanguage else { return }
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: userDefaultsKey)
        loadStrings(for: language)
    }
    
    public func string(_ key: String) -> String {
        return strings[key] ?? key
    }
    
    private func loadStrings(for language: AppLanguage) {
        if let url = Bundle.appResourceURL(named: language.rawValue, withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let dict = try? JSONDecoder().decode([String: String].self, from: data) {
            self.strings = dict
            return
        }
        
        // Fallback embedded strings if bundle resource lookup fails in test or CLI environment
        self.strings = FallbackStrings.dictionary(for: language)
    }
}

private enum FallbackStrings {
    static func dictionary(for language: AppLanguage) -> [String: String] {
        switch language {
        case .french:
            return [
                "app_name": "Overnode",
                "app_subtitle": "Console Cloud Native",
                "auth_title": "Bienvenue sur Overnode",
                "auth_subtitle": "Connectez-vous pour accéder à votre console et gérer vos ressources cloud.",
                "auth_login_discord": "Continuer avec Discord",
                "auth_login_passkey": "Se connecter avec Passkey",
                "auth_logging_in": "Connexion en cours...",
                "auth_passkey_notice": "Authentification biométrique ou clé de sécurité matérielle.",
                "auth_error_title": "Erreur d'authentification",
                "auth_error_cancelled": "La connexion a été annulée.",
                "auth_error_network": "Impossible de contacter le serveur Overnode.",
                "auth_error_passkey_failed": "Échec de l'authentification par Passkey.",
                "auth_error_generic": "Une erreur est survenue lors de la connexion.",
                "dashboard_title": "Tableau de Bord",
                "dashboard_welcome": "Bonjour",
                "dashboard_resources_title": "Ressources & Quotas",
                "dashboard_resources_desc": "Supervisez votre allocation matérielle en temps réel sur l'infrastructure Overnode.",
                "resource_ram": "Mémoire RAM",
                "resource_cpu": "Processeur CPU",
                "resource_disk": "Espace Disque",
                "resource_servers": "Serveurs Alloués",
                "resource_used": "utilisé",
                "resource_available": "disponible",
                "resource_allocated": "alloué",
                "resource_utilization": "d'utilisation",
                "resource_package": "Offre actuelle",
                "nav_dashboard": "Aperçu",
                "nav_servers": "Serveurs",
                "nav_daily_reward": "Récompense Quotidienne",
                "nav_wallet": "Wallet",
                "nav_store": "Boutique",
                "nav_support": "Support",
                "nav_afk": "Session AFK",
                "nav_settings": "Paramètres",
                "nav_logout": "Déconnexion",
                "status_connected": "Connecté",
                "status_connecting": "Connexion...",
                "status_refresh": "Actualiser",
                "lang_fr": "Français",
                "lang_en": "English",
                "links_console": "Ouvrir la console web",
                "links_mantle": "Mantle VPS Cloud",
                "links_website": "Site Overnode",
                "update_badge": "Mise à jour disponible",
                "update_title": "Nouvelle version d'Overnode",
                "update_notes_title": "Nouveautés & Correctifs",
                "update_default_notes": "Cette mise à jour apporte des améliorations de performance et de stabilité.",
                "update_downloading": "Téléchargement de la mise à jour...",
                "update_restarting": "Installation & redémarrage...",
                "update_later": "Plus tard",
                "update_now_button": "Mettre à jour",
                "update_check_button": "Rechercher des mises à jour",
                "update_checking": "Vérification en cours...",
                "update_up_to_date": "Votre application est à jour",
                "update_section_title": "Mises à jour du logiciel",
                "update_arch_label": "Architecture",
                "update_version_label": "Version installée",
                "update_btn_install": "Installer la version"
            ]
        case .english:
            return [
                "app_name": "Overnode",
                "app_subtitle": "Native Cloud Console",
                "auth_title": "Welcome to Overnode",
                "auth_subtitle": "Sign in to access your cloud console and manage infrastructure resources.",
                "auth_login_discord": "Continue with Discord",
                "auth_login_passkey": "Sign in with Passkey",
                "auth_logging_in": "Signing in...",
                "auth_passkey_notice": "Biometric authentication or hardware security key.",
                "auth_error_title": "Authentication Error",
                "auth_error_cancelled": "Authentication was cancelled.",
                "auth_error_network": "Unable to contact the Overnode server.",
                "auth_error_passkey_failed": "Passkey authentication failed.",
                "auth_error_generic": "An error occurred during authentication.",
                "dashboard_title": "Dashboard",
                "dashboard_welcome": "Hello",
                "dashboard_resources_title": "Resources & Quotas",
                "dashboard_resources_desc": "Monitor your hardware allocation in real-time across Overnode infrastructure.",
                "resource_ram": "RAM Memory",
                "resource_cpu": "CPU Processor",
                "resource_disk": "Disk Storage",
                "resource_servers": "Allocated Servers",
                "resource_used": "used",
                "resource_available": "available",
                "resource_allocated": "allocated",
                "resource_utilization": "utilized",
                "resource_package": "Current Plan",
                "nav_dashboard": "Overview",
                "nav_servers": "Servers",
                "nav_daily_reward": "Daily Reward",
                "nav_wallet": "Wallet",
                "nav_store": "Store",
                "nav_support": "Support",
                "nav_afk": "AFK Rewards",
                "nav_settings": "Settings",
                "nav_logout": "Sign Out",
                "status_connected": "Connected",
                "status_connecting": "Connecting...",
                "status_refresh": "Refresh",
                "lang_fr": "Français",
                "lang_en": "English",
                "links_console": "Open Web Console",
                "links_mantle": "Mantle VPS Cloud",
                "links_website": "Overnode Website",
                "update_badge": "Update available",
                "update_title": "New version of Overnode",
                "update_notes_title": "What's new & fixes",
                "update_default_notes": "This update includes performance and stability improvements.",
                "update_downloading": "Downloading update...",
                "update_restarting": "Installing & restarting...",
                "update_later": "Later",
                "update_now_button": "Update Now",
                "update_check_button": "Check for updates",
                "update_checking": "Checking for updates...",
                "update_up_to_date": "Your application is up to date",
                "update_section_title": "Software Updates",
                "update_arch_label": "Architecture",
                "update_version_label": "Installed version",
                "update_btn_install": "Install version"
            ]
        }
    }
}

// SwiftUI convenient extension
public extension View {
    func localizedText(_ key: String) -> some View {
        Text(LocalizationManager.shared.string(key))
    }
}
