# Overnode for macOS (Apple Silicon arm64)

Application macOS native pour l'écosystème cloud **Overnode**, optimisée pour Apple Silicon (M1/M2/M3/M4) et compatible avec macOS 14.0+ (Sonoma, Sequoia et macOS 27+).

---

## ✨ Fonctionnalités macOS

- 🔐 **Authentification Hybride & Sécurisée** :
  - **Discord OAuth2** avec capture sécurisée de session via `ASWebAuthenticationSession`.
  - **Passkeys (WebAuthn)** avec support biométrique Touch ID et clés matérielles (`AuthenticationServices`).
  - **Double Facteur TOTP (2FA)** natif pour la validation du code à 6 chiffres.
  - **Stockage Trousseau d'accès (Keychain)** : Persistance chiffrée des cookies de session via `SessionPersistence`.
- 📊 **Gestion Cloud & Console Serveur** :
  - Métriques d'utilisation en temps réel (RAM, Disque, CPU, Serveurs).
  - Terminal interactif et statistiques en direct par **WebSocket** (`ServerWebSocketManager`).
  - Gestion des fichiers, sauvegardes, variables de démarrage et sous-utilisateurs.
- 🧩 **Widgets Apple macOS (WidgetKit)** :
  - `OvernodeDailyRewardWidget` : Suivi des séries (streaks), récompenses de pièces et compte à rebours avant la prochaine réclamation (formats `.systemSmall` et `.systemMedium`).
  - `OvernodeServerRenewalWidget` : Suivi en temps réel de l'échéance et de l'ouverture du renouvellement des serveurs.
  - Partage de données inter-processus via stockage local partagé sécurisé.
- ⚡ **Menu Bar & Actions Rapides** :
  - Présence discrète dans la barre des menus macOS (`MenuBarManager`).
  - Raccourcis pour surveiller l'état et exécuter les actions d'alimentation (Démarrer, Redémarrer, Forcer l'arrêt).
- 🎮 **Discord Rich Presence (RPC)** :
  - Connexion locale automatique via socket Unix (`/tmp/discord-ipc-0`) en arrière-plan sans bloquer l'UI.
  - Affichage respectueux de la vie privée (aucune fuite du nom des serveurs ou des fichiers).
- 🔄 **Système de Mise à Jour Automatique** :
  - Vérification silencieuse auprès du portail `OvernodeApp-Updater`.
  - Téléchargement, vérification d'intégrité SHA256 et remplacement propre de l'application.

---

## 🛠️ Compilation & Tests

### Prérequis
- Mac avec processeur Apple Silicon (M1, M2, M3, M4)
- macOS 14.0 ou ultérieur
- Xcode 16+ ou Swift Toolchain 6.0+

### Commandes de Compilation
```bash
# Se placer dans le dossier macOS
cd app-mac

# Lancer la suite complète de tests unitaires
swift test

# Compiler en mode Release
swift build -c release

# Générer le bundle Overnode.app complet et signé (avec l'extension Widget)
./build_app.sh
```

---

## 📁 Architecture du Code macOS

```
app-mac/
├── Package.swift                    # Définition du paquet Swift Package Manager
├── build_app.sh                     # Script de packaging et signature du bundle .app
├── app.entitlements                 # Droits Sandbox de l'application principale
├── widget.entitlements              # Droits Sandbox de l'extension Widget
├── widget-Info.plist                # Métadonnées de l'extension WidgetKit
├── Sources/
│   ├── Overnode/                    # Application principale macOS
│   │   ├── AppMain.swift            # Point d'entrée de l'application SwiftUI
│   │   ├── Models/                  # Modèles de données (User, Server, Stats, DailyReward...)
│   │   ├── Services/                # Services API, AuthService, WebSocket, DiscordRPC...
│   │   ├── ViewModels/              # ViewModels MVVM réactifs
│   │   ├── Views/                   # Composants et écrans SwiftUI
│   │   ├── Theme/                   # Charte graphique sombre et dorée Overnode
│   │   ├── Localization/            # Gestionnaire multilingue (fr.json / en.json)
│   │   └── Resources/               # Icônes, logos et fichiers de localisation
│   └── OvernodeWidget/              # Extension WidgetKit macOS
│       ├── WidgetBundle.swift       # Bundle exposant les 2 widgets
│       ├── OvernodeDailyRewardWidget.swift
│       ├── OvernodeServerRenewalWidget.swift
│       └── DailyRewardStorage.swift # Stockage partagé des données widget
└── Tests/
    └── OvernodeTests/               # Tests unitaires automatisés
```
