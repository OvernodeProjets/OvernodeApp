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
    
    public func string(_ key: String, _ args: CVarArg...) -> String {
        let format = strings[key] ?? key
        return String(format: format, arguments: args)
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
                "update_btn_install": "Installer la version",
                "easteregg_quit_btn": "Quitter (Échap)",
                "easteregg_summoned_count": "%d chats invoqués",
                "easteregg_meow_btn": "Miaou !",
                "easteregg_phase_intro_title": "👑 L'ÉVEIL DU CHAT OVERNODE",
                "easteregg_phase_intro_sub": "Un visiteur inattendu s'empare des réglages...",
                "easteregg_intro_banner": "LE CHAT OVERNODE A PRIS LE CONTRÔLE",
                "easteregg_intro_hint": "Montez le son, installez-vous confortablement. 1m04 de dinguerie.",
                "easteregg_phase_dancing_title": "🕺 DANCING RAT x GROOVE FÉLIN",
                "easteregg_phase_dancing_sub": "Les serveurs Overnode tournent à 137 BPM !",
                "easteregg_dancer_judge": "DJ Juge",
                "easteregg_dancer_breakdancer": "Breakdancer Suprême",
                "easteregg_dancer_velvet_paw": "Patte de Velours",
                "easteregg_phase_oiia_title": "🌀 TURBO OIIA OIIA MODE 3000",
                "easteregg_phase_oiia_sub": "Rotation féline maximale engagée !",
                "easteregg_phase_chaos_title": "🎉 DISCO CHAOS TOTAL",
                "easteregg_phase_chaos_sub": "Overclocking félin illimité, aucun bug détecté !",
                "easteregg_chaos_banner": "🔥 OVERCLOCKING FÉLIN : 9999 MHz",
                "easteregg_badge_lag_purr": "⚡ 0% Lag, 100% Ronronnement",
                "easteregg_badge_salmon": "🐟 Alimenté à la pâtée royale",
                "easteregg_badge_silicon": "🚀 macOS Silicon Optimisé",
                "easteregg_phase_finished_title": "🏆 FÉLICITATIONS, TU AS SURVÉCU !",
                "easteregg_phase_finished_sub": "Tu es officiellement certifié Maître des Chats Overnode.",
                "easteregg_victory_title": "🎉 TU AS SURVÉCU À LA DINGUERIE FÉLINE !",
                "easteregg_victory_desc": "1 minute et 4 secondes de pure légende féline.",
                "easteregg_restart_btn": "Recommencer la fête 🔁",
                "easteregg_back_settings_btn": "Retourner aux réglages ↩️",
                "easteregg_quote_1": "🎶 You're free to do what you want to do... MIAOU 🎶",
                "easteregg_quote_2": "Serveurs Overnode propulsés par 12 chats surpuissants",
                "easteregg_quote_3": "Consommation CPU : 100% dédiée au bonheur félin",
                "easteregg_quote_4": "Le protocole ⌘T a atteint la perfection",
                "bundle_god_f4": "Personnalisation intégrale de l'application (Thèmes & Fond)",
                "godpack_title": "Personnalisation Overnode",
                "godpack_subtitle": "Fonctionnalités exclusives aux détenteurs du Pack God",
                "godpack_badge_active": "Pack God Actif 👑",
                "godpack_badge_locked": "Pack God Requis",
                "godpack_tab_presets": "Thèmes Préconçus",
                "godpack_tab_colors": "Couleurs",
                "godpack_tab_background": "Fond & Incrustation",
                "godpack_tab_layout": "Disposition & Accueil",
                "godpack_tab_share": "Import / Export",
                "godpack_locked_title": "Débloquez la personnalisation totale de votre application",
                "godpack_locked_desc": "Avec le Pack God sur Toledo, vous pouvez personnaliser Overnode à 100% : installer des thèmes préconçus de la communauté, ajuster toutes les couleurs, incruster une image de fond personnalisée avec flou réglable, choisir votre page d'accueil par défaut, déplacer la disposition de l'interface et exporter votre configuration dans un fichier config.overnode.app partageable avec vos proches.",
                "godpack_btn_discover_store": "Découvrir le Pack God dans la Boutique",
                "godpack_btn_check_sub": "Vérifier mon abonnement",
                "godpack_alert_success_active": "Pack God validé avec succès !",
                "godpack_alert_no_pack": "Aucun Pack God actif détecté pour ce compte.",
                "godpack_presets_desc": "Choisissez un thème conçu par nous et la communauté :",
                "godpack_preset_active": "Actif",
                "godpack_preset_apply": "Appliquer",
                "godpack_preset_applied_alert": "Thème '%@' appliqué !",
                "godpack_colors_desc": "Personnalisez la palette de couleurs de l'application :",
                "godpack_color_accent_gold": "Accent Principal (Doré)",
                "godpack_color_background": "Arrière-plan principal",
                "godpack_color_card_bg": "Cartes & Surfaces",
                "godpack_color_card_secondary": "Panneaux secondaires",
                "godpack_color_text_primary": "Texte Principal",
                "godpack_color_text_secondary": "Texte Secondaire",
                "godpack_color_border": "Bordures",
                "godpack_color_accent_cyan": "Accent Secondaire (Cyan)",
                "godpack_bg_desc": "Incrustation d'un arrière-plan personnalisé :",
                "godpack_bg_url_label": "Lien de l'image (URL Web) :",
                "godpack_bg_apply_btn": "Appliquer",
                "godpack_bg_clear_btn": "Effacer",
                "godpack_bg_choose_file_btn": "Choisir une image sur mon Mac...",
                "godpack_bg_opacity_label": "Opacité de l'incrustation",
                "godpack_bg_blur_label": "Flou d'arrière-plan (Blur)",
                "godpack_bg_darkness_label": "Masque sombre de contraste",
                "godpack_bg_file_panel_title": "Sélectionner une image de fond pour Overnode",
                "godpack_bg_applied_alert": "Image de fond locale appliquée !",
                "godpack_layout_desc": "Disposition & Préférences de Navigation :",
                "godpack_landing_label": "Page d'arrivée au lancement d'Overnode :",
                "godpack_landing_tab_dashboard": "Aperçu (Dashboard)",
                "godpack_landing_tab_servers": "Mes Serveurs",
                "godpack_landing_tab_wallet": "Portefeuille",
                "godpack_landing_tab_daily_reward": "Récompense Quotidienne",
                "godpack_landing_tab_store": "Boutique (Store)",
                "godpack_landing_tab_support": "Support Overnode",
                "godpack_landing_tab_afk": "Gains AFK",
                "godpack_landing_tab_settings": "Paramètres",
                "godpack_sidebar_pos_label": "Position de la barre latérale (Sidebar) :",
                "godpack_sidebar_left": "Gauche (Défaut)",
                "godpack_sidebar_right": "Droite (Inversée)",
                "godpack_card_radius_label": "Rayon de courbure des cartes :",
                "godpack_share_desc": "Exportez votre thème pour vos amis ou importez une création :",
                "godpack_export_btn": "Extraire ma configuration (config.overnode.app)",
                "godpack_import_btn": "Importer une configuration...",
                "godpack_reset_btn": "Réinitialiser",
                "godpack_export_panel_title": "Enregistrer votre configuration Overnode",
                "godpack_export_success_alert": "Fichier config.overnode.app exporté avec succès !",
                "godpack_export_error_alert": "Échec de l'export : %@",
                "godpack_import_panel_title": "Importer un fichier de configuration Overnode",
                "godpack_import_success_alert": "Configuration importée et appliquée avec succès !",
                "godpack_import_error_alert": "Format de configuration invalide : %@",
                "godpack_reset_success_alert": "Thème réinitialisé aux paramètres Overnode par défaut.",
                "godpack_vip_section_title": "Activation VIP Discord (Updater)",
                "godpack_vip_section_desc": "Si votre identifiant Discord a été ajouté par un administrateur sur le portail OvernodeApp-Updater, vous pouvez l'activer directement ici :",
                "godpack_vip_modal_title": "Activation VIP Discord",
                "godpack_vip_modal_subtitle": "Raccourci secret ⌘D",
                "godpack_vip_modal_desc": "Entrez votre identifiant Discord (ex: 966633645144158209) pour vérifier et débloquer vos fonctionnalités Pack God :",
                "godpack_vip_input_placeholder": "Identifiant Discord (ex: 966633645144158209)",
                "godpack_vip_btn_verify": "Vérifier & Activer",
                "godpack_vip_detected_discord": "Détecté via Discord : %@",
                "godpack_alert_vip_activated": "Pack God VIP activé avec succès !",
                "godpack_alert_vip_failed": "Aucun accès Pack God VIP trouvé pour cet identifiant Discord sur le portail Updater.",
                "godpack_vip_active_badge": "VIP Discord : %@",
                "godpack_vip_unlink_btn": "Dissocier",
                "godpack_alert_vip_unlinked": "Identifiant VIP Discord dissocié."
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
                "update_btn_install": "Install version",
                "easteregg_quit_btn": "Exit (Esc)",
                "easteregg_summoned_count": "%d cats summoned",
                "easteregg_meow_btn": "Meow!",
                "easteregg_phase_intro_title": "👑 THE OVERNODE CAT AWAKENS",
                "easteregg_phase_intro_sub": "An unexpected visitor takes over settings...",
                "easteregg_intro_banner": "THE OVERNODE CAT HAS TAKEN CONTROL",
                "easteregg_intro_hint": "Turn up the volume, get comfortable. 1m04 of pure madness.",
                "easteregg_phase_dancing_title": "🕺 DANCING RAT x FELINE GROOVE",
                "easteregg_phase_dancing_sub": "Overnode servers running at 137 BPM!",
                "easteregg_dancer_judge": "DJ Judge",
                "easteregg_dancer_breakdancer": "Supreme Breakdancer",
                "easteregg_dancer_velvet_paw": "Velvet Paw",
                "easteregg_phase_oiia_title": "🌀 TURBO OIIA OIIA MODE 3000",
                "easteregg_phase_oiia_sub": "Maximum feline spin engaged!",
                "easteregg_phase_chaos_title": "🎉 TOTAL DISCO CHAOS",
                "easteregg_phase_chaos_sub": "Unlimited feline overclocking, zero bugs detected!",
                "easteregg_chaos_banner": "🔥 FELINE OVERCLOCKING: 9999 MHz",
                "easteregg_badge_lag_purr": "⚡ 0% Lag, 100% Purring",
                "easteregg_badge_salmon": "🐟 Powered by royal salmon feast",
                "easteregg_badge_silicon": "🚀 macOS Silicon Optimized",
                "easteregg_phase_finished_title": "🏆 CONGRATULATIONS, YOU SURVIVED!",
                "easteregg_phase_finished_sub": "You are officially certified Overnode Cat Master.",
                "easteregg_victory_title": "🎉 YOU SURVIVED THE FELINE MADNESS!",
                "easteregg_victory_desc": "1 minute and 4 seconds of pure feline legend.",
                "easteregg_restart_btn": "Restart the party 🔁",
                "easteregg_back_settings_btn": "Back to settings ↩️",
                "easteregg_quote_1": "🎶 You're free to do what you want to do... MEOW 🎶",
                "easteregg_quote_2": "Overnode servers powered by 12 overpowered cats",
                "easteregg_quote_3": "CPU Usage: 100% dedicated to feline happiness",
                "easteregg_quote_4": "Protocol ⌘T has reached perfection",
                "bundle_god_f4": "Full application customization (Themes & Backgrounds)",
                "godpack_title": "Overnode Customization",
                "godpack_subtitle": "Exclusive features for God Pack owners",
                "godpack_badge_active": "God Pack Active 👑",
                "godpack_badge_locked": "God Pack Required",
                "godpack_tab_presets": "Preset Themes",
                "godpack_tab_colors": "Colors",
                "godpack_tab_background": "Background & Overlay",
                "godpack_tab_layout": "Layout & Landing",
                "godpack_tab_share": "Import / Export",
                "godpack_locked_title": "Unlock full application customization",
                "godpack_locked_desc": "With the God Pack on Toledo, you can customize Overnode 100%: install community presets, tweak all colors, overlay a custom background image with adjustable blur, choose your default landing page, rearrange the interface layout, and export your config into a config.overnode.app file to share with friends.",
                "godpack_btn_discover_store": "Discover God Pack in the Store",
                "godpack_btn_check_sub": "Check my subscription",
                "godpack_alert_success_active": "God Pack verified successfully!",
                "godpack_alert_no_pack": "No active God Pack detected for this account.",
                "godpack_presets_desc": "Choose a theme designed by us and the community:",
                "godpack_preset_active": "Active",
                "godpack_preset_apply": "Apply",
                "godpack_preset_applied_alert": "Theme '%@' applied!",
                "godpack_colors_desc": "Customize the application color palette:",
                "godpack_color_accent_gold": "Primary Accent (Gold)",
                "godpack_color_background": "Main Background",
                "godpack_color_card_bg": "Cards & Surfaces",
                "godpack_color_card_secondary": "Secondary Panels",
                "godpack_color_text_primary": "Primary Text",
                "godpack_color_text_secondary": "Secondary Text",
                "godpack_color_border": "Borders",
                "godpack_color_accent_cyan": "Secondary Accent (Cyan)",
                "godpack_bg_desc": "Custom background image overlay:",
                "godpack_bg_url_label": "Image link (Web URL):",
                "godpack_bg_apply_btn": "Apply",
                "godpack_bg_clear_btn": "Clear",
                "godpack_bg_choose_file_btn": "Choose an image on my Mac...",
                "godpack_bg_opacity_label": "Overlay Opacity",
                "godpack_bg_blur_label": "Background Blur",
                "godpack_bg_darkness_label": "Contrast Darkening Mask",
                "godpack_bg_file_panel_title": "Select a background image for Overnode",
                "godpack_bg_applied_alert": "Local background image applied!",
                "godpack_layout_desc": "Layout & Navigation Preferences:",
                "godpack_landing_label": "Landing page on Overnode launch:",
                "godpack_landing_tab_dashboard": "Overview (Dashboard)",
                "godpack_landing_tab_servers": "My Servers",
                "godpack_landing_tab_wallet": "Wallet",
                "godpack_landing_tab_daily_reward": "Daily Reward",
                "godpack_landing_tab_store": "Store",
                "godpack_landing_tab_support": "Overnode Support",
                "godpack_landing_tab_afk": "AFK Session",
                "godpack_landing_tab_settings": "Settings",
                "godpack_sidebar_pos_label": "Sidebar Position:",
                "godpack_sidebar_left": "Left (Default)",
                "godpack_sidebar_right": "Right (Inverted)",
                "godpack_card_radius_label": "Cards Corner Radius:",
                "godpack_share_desc": "Export your theme for friends or import a creation:",
                "godpack_export_btn": "Extract my configuration (config.overnode.app)",
                "godpack_import_btn": "Import a configuration...",
                "godpack_reset_btn": "Reset",
                "godpack_export_panel_title": "Save your Overnode configuration",
                "godpack_export_success_alert": "config.overnode.app file exported successfully!",
                "godpack_export_error_alert": "Export failed: %@",
                "godpack_import_panel_title": "Import an Overnode configuration file",
                "godpack_import_success_alert": "Configuration imported and applied successfully!",
                "godpack_import_error_alert": "Invalid configuration format: %@",
                "godpack_reset_success_alert": "Theme reset to Overnode default settings.",
                "godpack_vip_section_title": "Discord VIP Activation (Updater)",
                "godpack_vip_section_desc": "If your Discord ID was added by an administrator on the OvernodeApp-Updater portal, you can activate it directly here:",
                "godpack_vip_modal_title": "Discord VIP Activation",
                "godpack_vip_modal_subtitle": "Secret shortcut ⌘D",
                "godpack_vip_modal_desc": "Enter your Discord ID (e.g. 966633645144158209) to verify and unlock your God Pack features:",
                "godpack_vip_input_placeholder": "Discord ID (e.g. 966633645144158209)",
                "godpack_vip_btn_verify": "Verify & Activate",
                "godpack_vip_detected_discord": "Detected via Discord: %@",
                "godpack_alert_vip_activated": "God Pack VIP successfully activated!",
                "godpack_alert_vip_failed": "No God Pack VIP access found for this Discord ID on the Updater portal.",
                "godpack_vip_active_badge": "Discord VIP: %@",
                "godpack_vip_unlink_btn": "Unlink",
                "godpack_alert_vip_unlinked": "VIP Discord ID unlinked."
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
