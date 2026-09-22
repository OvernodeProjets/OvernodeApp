# Overnode (macOS 27+ / Apple Silicon)

Application native macOS pour l'écosystème cloud **Overnode**.
Porte l'expérience de gestion cloud de [console.overnode.fr](https://console.overnode.fr) directement sur macOS dans une application moderne, ultra-rapide et optimisée Apple Silicon.

## ✨ Fonctionnalités

- 🔐 **Authentification Hybride & Sécurisée** :
  - **Discord OAuth2** avec redirection Web sécurisée via `ASWebAuthenticationSession`.
  - **Passkeys (WebAuthn)** spécifiques à `console.overnode.fr` avec support biométrique Touch ID / Apple Security Keys (`AuthenticationServices`).
- 📊 **Tableau de Bord des Ressources & Quotas** :
  - Métriques d'utilisation en temps réel pour la RAM (GB), le Disque (GB), le processeur CPU (%) et le nombre de serveurs alloués.
  - Jauges de progression visuelles avec alerte de saturation.
- 🌐 **Système d'Internationalisation (i18n)** :
  - Support natif complet du **Français (FR)** et de l'**Anglais (EN)**.
  - Changement de langue dynamique instantané sans rechargement.
- 🎨 **Design Système Overnode** :
  - Thème sombre épuré, accents ambre/dorés Overnode, bordures subtiles et typographie optimisée.
  - Fenêtre idéale (1100 × 740 px) intégrée nativement avec barre de titre masquée et coins arrondis macOS.
- 📦 **Architecture Modulaire** :
  - Organisation stricte en petits fichiers ciblés (Models, Services, ViewModels, Views, Theme, Localization).

## 🚀 Compilation & Exécution

### Prérequis
- macOS 14.0+ (Optimisé pour macOS 27 Golden Gate & Apple Silicon arm64)
- Swift 6.0+ / Xcode 16+

### Commandes de Build
```bash
cd app
# Compilation release
swift build -c release

# Générer le bundle Overnode.app complet
./build_app.sh
```
