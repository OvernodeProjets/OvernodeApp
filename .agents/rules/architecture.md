# Architecture & Code Standards

Conventions d'architecture pour l'application macOS Overnode.

## When this applies

- Création ou modification de composants, services, modèles ou vues dans le dossier `app/`.

## Rules

- **Modularité**: Découper chaque fonctionnalité en composants spécialisés :
  - `Models/` : Modèles de données purs (User, ResourceStats, Server, AuthState)
  - `Services/` : Services réseau et API (APIClient, AuthService, PasskeyCoordinator, DiscordOAuthCoordinator)
  - `ViewModels/` : Modèles de présentation conformes à `ObservableObject`
  - `Views/` : Composants SwiftUI indépendants (`AuthView`, `DashboardView`, `ResourceCardView`, `SidebarView`, `HeaderView`)
  - `Theme/` : Constantes de design, couleurs Overnode, typographie, espacements
  - `Localization/` : Gestionnaire de langue et dictionnaires de traduction
- **Taille des fichiers**: Ne jamais dépasser 150-200 lignes par fichier.
- **Gestion d'état**: Utiliser `@StateObject`, `@ObservedObject` et le pattern MVVM.
