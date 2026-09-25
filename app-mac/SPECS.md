# Spécifications et Intentions du Projet Overnode macOS

## 1. Objectif du Projet
Créer une application native macOS 27 (Golden Gate) optimisée pour processeurs Apple Silicon (arm64) pour **Overnode** (nom de l'application : **Overnode**).
L'objectif est d'offrir une expérience de premier plan, fluide, sécurisée et native équivalente ou supérieure à la console web.

## 2. RÈGLES CRITIQUES D'INTERFACE ET DE COMMUNICATION (POUR LES IA & DÉVELOPPEURS)
- **RÈGLE CRITIQUE (UI)** : **NE JAMAIS** mentionner à l'utilisateur dans l'interface graphique (textes, boutons, sous-titres, infobulles, alertes) l'adresse ou le domaine web `console.overnode.fr`. Utiliser systématiquement l'appellation sobre et unifiée **"Console Cloud"** ou **"Overnode"**.
- **Logos & Charte Graphique** : Toujours utiliser le vrai logo officiel Overnode (`overnode_logo.png` et `overnode_icon.png`) extrait des assets graphiques officiels d'Overnode.
- **Support bilingue strict (i18n)** : Toutes les clés de chaînes doivent être présentes dans `fr.json` et `en.json` avec switch dynamique instantané.

## 3. Écosystème & Sites de Référence
- **Site principal** : [overnode.fr](https://overnode.fr) (Écosystème cloud, design sombre, épuré, typographie nette, badge d'état).
- **Console Cloud** : `console.overnode.fr` (Backend Heliactyl Next Toledo, gestion des serveurs, authentification Discord, Passkeys et TOTP 2FA).
- **Mantle VPS Cloud** : [mantle.overnode.fr](https://mantle.overnode.fr) (Plateforme Cloud VPS Overnode haute performance).

## 4. Architecture Technique (SwiftUI & Modulaire)
Le code est situé dans le répertoire `app/` et suit une séparation stricte des responsabilités en petits fichiers ciblés :
- `Models/` :
  - `User.swift` : Données du profil connecté (id, username, email, rôle, etc.).
  - `ResourceStats.swift` : Quotas et consommation (RAM, Disk, CPU, Nombre de serveurs).
  - `AuthModels.swift` : Modèles de payload et challenges d'authentification Passkey / WebAuthn.
- `Services/` :
  - `APIClient.swift` : Client réseau générique avec gestion des cookies de session (`HTTPCookieStorage`), headers et timeouts.
  - `AuthService.swift` : Gestion de session, vérification `/api/v5/state`, validation 2FA (`/auth/2fa/verify`), Passkeys et déconnexion.
  - `DiscordAuthCoordinator.swift` & `WebAuthModalView.swift` : Flux d'authentification Discord OAuth2 et Passkey WebAuthn intégrés, avec interception de redirection 2FA (`/auth/2fa`) et transfert transparent des cookies de session vers l'application.
- `Theme/` :
  - `OvernodeTheme.swift` : Palette de couleurs (Fonds sombres `#101218`, cartes `#181B22`, bordures `#2E3337`, texte atténué `#95A1AD`, accents dorés et Discord).
- `Localization/` :
  - `LocalizationManager.swift` : Moteur réactif de traduction à la i18n.
  - `fr.json` & `en.json` : Dictionnaires complets en Français et en Anglais.
- `ViewModels/` :
  - `AuthViewModel.swift` : Gestion des états de connexion, flux 2FA, ouverture de fenêtres d'authentification et session.
  - `DashboardViewModel.swift` : Rafraîchissement des ressources et métriques.
- `Views/` :
  - `AuthView.swift` : Écran de connexion moderne avec le vrai logo Overnode, boutons Discord OAuth2 et Passkey.
  - `TwoFactorVerificationView.swift` : Écran natif de saisie du code TOTP / code de secours à 6 chiffres pour les comptes avec double facteur activé.
  - `DashboardView.swift` : Écran principal affichant le profil et les 4 jauges de ressources (RAM, Disk, CPU, Serveurs).
  - `Components/` : Jauges de progression (`ResourceGaugeView`), en-tête avec vrai logo et sélection de langue (`HeaderBarView`), etc.

## 5. Gestion de l'Authentification Passkey et Double Facteur (2FA)
1. **Passkeys (WebAuthn)** :
   - L'erreur `The calling process does not have an application identifier` survenue lors de l'appel natif `ASAuthorizationPlatformPublicKeyCredentialProvider` est due au fait que les Passkeys WebAuthn de domaine (`console.overnode.fr`) nécessitent un domaine associé validé côté serveur (`/.well-known/apple-app-site-association`) et un profil de provisioning signé par une équipe développeur Apple.
   - Pour assurer un fonctionnement immédiat, robuste et sans configuration de certificat Apple Developer payant, la connexion par Passkey s'exécute via la modale WebAuthn sécurisée (`WebAuthModalView`) qui bénéficie du moteur Safari/WebKit officiel du système, prend en charge nativement Touch ID, Face ID et clés matérielles Yubikey, puis synchronise automatiquement la session utilisateur directement dans l'application native.
2. **Double Facteur (2FA TOTP)** :
   - Si un utilisateur a activé la 2FA (comme sur Toledo), la redirection `/auth/2fa` est capturée automatiquement : l'utilisateur ne reste pas bloqué sur une page web externe et arrive directement sur l'écran natif `TwoFactorVerificationView` de l'application pour saisir son code, puis entre directement sur son tableau de bord.
