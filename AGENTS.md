# Overnode Desktop Apps (macOS & Windows)

Applications natives pour Overnode :
- **macOS** (`app-mac/`, compatible Apple Silicon arm64, macOS 14+ et macOS 27+). Un lien symbolique `app -> app-mac` est maintenu pour la compatibilité descendante.
- **Windows** (`app-win/`, architecture C# / .NET 9 WinUI 3 et spécifications complètes).
- **Auto-Updater Portal** (`OvernodeApp-Updater/`, serveur Node.js de gestion des releases).
- **Backend Cloud** (`server-side/`, API Heliactyl Toledo).

## Tech Stack

- **macOS** : Swift 6 / SwiftUI, WebKit & AuthenticationServices, Combine & Async/Await, WidgetKit
- **Windows** : C# 12 / .NET 9, WinUI 3 (Windows App SDK), WebView2, Windows Hello (WebAuthn), Adaptive Cards Widgets
- **Localisation** : i18n JSON multilingue (FR/EN)

## Commands

- `cd app-mac && swift test` - Lancer les tests unitaires macOS
- `cd app-mac && swift build -c release` - Compiler l'application macOS
- `cd app-mac && ./build_app.sh` - Générer le bundle macOS Overnode.app complet
- `cd app-win && dotnet test tests/Overnode.Tests/Overnode.Tests.csproj` - Lancer les tests unitaires Windows
- `cd app-win && dotnet build src/Overnode.App/Overnode.App.csproj` - Compiler l'application Windows
- `cd OvernodeApp-Updater && npm start` - Démarrer le portail web de gestion des mises à jour

## Rules

The detailed rules live in `.agents/rules/`. Read the relevant file before acting:

- **Architecture** - [.agents/rules/architecture.md](.agents/rules/architecture.md) - Structure modulaire, séparation des responsabilités et petits fichiers
- **Auto-Updater** - [.agents/rules/auto-updater.md](.agents/rules/auto-updater.md) - Système de mise à jour automatique, portail OvernodeApp-Updater et CI/CD GitHub
- **i18n** - [.agents/rules/i18n.md](.agents/rules/i18n.md) - Conventions de traduction FR/EN et localisation
- **UI & Content** - [.agents/rules/ui-rules.md](.agents/rules/ui-rules.md) - Règles d'interface, interdiction de mentionner console.overnode.fr sur l'UI, logos
- **Server Management** - [.agents/rules/server-management.md](.agents/rules/server-management.md) - Règles et architecture de la gestion des serveurs
- **Wallet, Store & Support** - [.agents/rules/wallet-store-support.md](.agents/rules/wallet-store-support.md) - Règles d'architecture et flux pour le Wallet, la Boutique, le Support et l'AFK
- **Daily Reward & Widget** - [.agents/rules/daily-reward-widget.md](.agents/rules/daily-reward-widget.md) - Règles du module Daily Reward et du widget macOS
- **Discord Rich Presence** - [.agents/rules/discord-rpc.md](.agents/rules/discord-rpc.md) - Intégration Discord RPC, statut Overnode App et respect de la vie privée
- **Menu Bar & Quick Actions** - [.agents/rules/menu-bar.md](.agents/rules/menu-bar.md) - Menu Bar macOS, présence en arrière-plan et contrôle rapide du serveur
- **Easter Egg** - [.agents/rules/easter-egg.md](.agents/rules/easter-egg.md) - Raccourci secret ⌘T (macOS) / Ctrl+T (Windows) dans les réglages et montage félin WTF
 
## Universal Rules

- **CRITICAL**: Tout le code doit être modulaire, typé et découpé en fichiers ciblés (pas de fichiers monolithiques).
- **CRITICAL**: Ne JAMAIS afficher `console.overnode.fr` à l'utilisateur dans l'interface. Utiliser "Console Cloud" ou "Overnode".
- **CRITICAL**: Respecter la charte Overnode (Dark theme `#0B0D13`, accents dorés `#E5B842`, police système).
- **CRITICAL**: Gérer l'authentification avec persistance sécurisée des sessions (Keychain sur macOS, DPAPI/PasswordVault sur Windows) et écran natif de saisie TOTP pour le double facteur (2FA).
- **CRITICAL**: Pour les sous-domaines serveur, seul **`overnode.fr`** doit être proposé et autorisé. Ne JAMAIS mentionner "Cloudflare" ou "Cloudflare DNS" sur l'interface (utiliser sobrement "Actif").
- **CRITICAL**: Les boutons désactivés ou états inactifs (ex: "Déjà réclamé aujourd'hui") ne doivent JAMAIS afficher de texte sombre/noir sur fond sombre. Toujours garantir un contraste élevé et lisible.
- **CRITICAL**: L'édition de fichiers distants via éditeur externe doit être synchronisée automatiquement (`writeFile`) en arrière-plan à chaque sauvegarde locale (`ExternalEditorManager`), sans jamais exécuter de script ni afficher d'invite de commandes (`cmd`).
- **CRITICAL**: Ne JAMAIS créer de fichier de log de crash ou de debug temporaire sur le Bureau de l'utilisateur (ex: `overnode_crash.log`). Utiliser les sorties de diagnostic standard (`Debug.WriteLine` / stderr) ou les dossiers d'application dédiés.

