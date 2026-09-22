# Spécifications et Intentions du Projet Overnode macOS

## 1. Objectif du Projet
Créer une application native macOS 27 (Golden Gate) optimisée pour processeurs Apple Silicon (arm64) pour **Overnode** (nom de l'application : **Overnode**).
L'objectif est d'offrir une expérience de premier plan, fluide, sécurisée et native équivalente ou supérieure à la console web [console.overnode.fr](https://console.overnode.fr).

## 2. Écosystème & Sites de Référence
- **Site principal** : [overnode.fr](https://overnode.fr) (Écosystème cloud, design sombre, épuré, typographie nette, badge d'état).
- **Console Cloud** : [console.overnode.fr](https://console.overnode.fr) (Backend Heliactyl Next Toledo, gestion des serveurs de jeu / applications, authentification Discord et Passkeys, surveillance des ressources).
- **Mantle VPS Cloud** : [mantle.overnode.fr](https://mantle.overnode.fr) (Plateforme Cloud VPS Overnode haute performance).

## 3. Architecture Technique (SwiftUI & Modulaire)
Le code est situé dans le répertoire `app/` et suit une séparation stricte des responsabilités en petits fichiers ciblés :
- `Models/` :
  - `User.swift` : Données du profil connecté (id, username, email, rôle, etc.).
  - `ResourceStats.swift` : Quotas et consommation (RAM, Disk, CPU, Nombre de serveurs).
  - `Server.swift` : Liste des serveurs hébergés et état de fonctionnement.
  - `AuthState.swift` : État de session, token, challenges d'authentification.
- `Services/` :
  - `APIClient.swift` : Client réseau générique avec gestion des cookies de session, headers et timeouts.
  - `AuthService.swift` : Gestion de session, vérification `/api/v5/state`, déconnexion.
  - `DiscordAuthCoordinator.swift` : Flux OAuth2 Discord natif via `ASWebAuthenticationSession` avec redirection de retour d'authentification.
  - `PasskeyCoordinator.swift` : Flux Passkey / WebAuthn natif interrogeant `/auth/passkey/options` et `/auth/passkey/verify`.
  - `ResourceService.swift` : Récupération des ressources et quotas (`/api/v5/resources`).
- `Theme/` :
  - `OvernodeTheme.swift` : Palette de couleurs (Fonds sombres `#101218`, cartes `#181B22`, bordures `#2E3337`, texte atténué `#95A1AD`, gradients Overnode).
- `Localization/` :
  - `LocalizationManager.swift` : Moteur réactif de traduction à la i18n.
  - `fr.json` & `en.json` : Dictionnaires complets en Français et en Anglais.
- `ViewModels/` :
  - `AuthViewModel.swift` : Gestion des états de chargement, erreurs et connexion Discord/Passkey.
  - `DashboardViewModel.swift` : Rafraîchissement des ressources et métriques.
- `Views/` :
  - `AuthView.swift` : Écran de connexion moderne avec Discord OAuth2 et Passkeys.
  - `DashboardView.swift` : Écran principal affichant le profil et les 4 jauges de ressources (RAM, Disk, CPU, Serveurs).
  - `Components/` : Jauges de progression (`ResourceGaugeView`), en-tête avec profil et sélection de langue (`HeaderBarView`), etc.

## 4. Fonctionnalités Implémentées
1. **Authentification Hybride Sécurisée** :
   - Connexion **Discord OAuth2** avec session native et capture du cookie de session.
   - Connexion **Passkey** spécifique à `console.overnode.fr` (génération du challenge, extraction et validation des identifiants cryptographiques).
2. **Tableau de Bord des Ressources** :
   - Quotas et utilisation en temps réel pour la RAM (GB), le Disque (GB), le processeur CPU (%) et le nombre de serveurs alloués.
   - Jauges visuelles avec pourcentage d'utilisation, code couleur dynamique et indicateurs de saturation.
3. **Internationalisation (i18n)** :
   - Sélecteur de langue dynamique instantané (Français / Anglais).
   - Traduction intégrale sans rechargement nécessaire.
4. **Ergonomie Fenêtre macOS** :
   - Taille de fenêtre optimale : 1100x740 points (confortable, moderne, sans occuper tout l'écran, redimensionnable).
5. **Dépôt Git Privé** :
   - Publication du code sur l'organisation `OvernodeProjets` dans un dépôt privé dédié.
