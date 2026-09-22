# Overnode macOS Native App

Application native macOS pour Overnode (macOS 27+, Apple Silicon arm64).
Porte l'expérience de gestion cloud nativement sur macOS avec authentification Discord OAuth2, Passkeys WebAuthn, tableau de bord des ressources et internationalisation.

## Tech Stack

- Swift 6.4 / SwiftUI (Target: macOS 27+ / macOS 14+ compatible Apple Silicon arm64)
- WebKit & AuthenticationServices
- Combine & Async/Await pour le réseau et la réactivité
- Localisation i18n JSON/Strings (FR/EN)

## Commands

- `cd app && swift build -c release` - Compiler l'application macOS
- `cd app && ./build_app.sh` - Générer le bundle macOS Overnode.app complet

## Rules

The detailed rules live in `.agents/rules/`. Read the relevant file before acting:

- **Architecture** - [.agents/rules/architecture.md](.agents/rules/architecture.md) - Structure modulaire, séparation des responsabilités et petits fichiers
- **i18n** - [.agents/rules/i18n.md](.agents/rules/i18n.md) - Conventions de traduction FR/EN et localisation
- **UI & Content** - [.agents/rules/ui-rules.md](.agents/rules/ui-rules.md) - Règles d'interface, interdiction de mentionner console.overnode.fr sur l'UI, logos
- **Server Management** - [.agents/rules/server-management.md](.agents/rules/server-management.md) - Règles et architecture de la gestion des serveurs
- **Wallet, Store & Support** - [.agents/rules/wallet-store-support.md](.agents/rules/wallet-store-support.md) - Règles d architecture et flux pour le Wallet, la Boutique, le Support et l AFK
 - **Daily Reward & Widget** - [.agents/rules/daily-reward-widget.md](.agents/rules/daily-reward-widget.md) - Règles du module Daily Reward et du widget macOS

## Universal Rules

- **CRITICAL**: Tout le code doit être modulaire, typé et découpé en fichiers ciblés (pas de fichiers monolithiques).
- **CRITICAL**: Ne JAMAIS afficher `console.overnode.fr` à l'utilisateur dans l'interface. Utiliser "Console Cloud" ou "Overnode".
- **CRITICAL**: Supporter nativement Apple Silicon avec UI ultra-fluide respectant la charte Overnode (Dark theme, accents dorés/bleus, police système SF Pro / Inter).
- **CRITICAL**: Gérer l'authentification avec persistance sécurisée des sessions (cookies HTTP / Bearer) et écran natif de saisie TOTP pour le double facteur (2FA).
