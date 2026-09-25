# Architecture de l'Application Overnode Windows

Ce document détaille la correspondance architecturale 1:1 entre l'application macOS (Swift 6 / SwiftUI) et l'application Windows (C# 12 / .NET 9 / WinUI 3).

---

## 1. Vue d'Ensemble & Correspondances de Stack

| Domaine | Implémentation macOS | Implémentation Windows |
| :--- | :--- | :--- |
| **Framework UI** | SwiftUI (macOS 14+) | WinUI 3 / Windows App SDK 1.5+ |
| **Langage & Runtime** | Swift 6 / Swift Native Runtime | C# 12 / .NET 9 (Native AOT ou CoreCLR) |
| **Architecture UI** | MVVM avec `ObservableObject` / `@Published` | MVVM avec `CommunityToolkit.Mvvm` (`[ObservableProperty]`) |
| **Composants WebView** | WebKit / `WKWebView` | Microsoft Edge WebView2 (`CoreWebView2`) |
| **OAuth2 Discord** | `ASWebAuthenticationSession` | Fenêtre modale WebView2 sandboxée isolée |
| **Passkeys / WebAuthn** | `AuthenticationServices` (Touch ID) | Windows Hello via `webauthn.dll` |
| **Chiffrement de Session** | macOS Keychain (`Security.framework`) | Windows DPAPI (`ProtectedData`) + `PasswordVault` |
| **Temps Réel Serveur** | `URLSessionWebSocketTask` | `System.Net.WebSockets.ClientWebSocket` |
| **Présence Discord** | IPC Unix Socket (`/tmp/discord-ipc-0`) | Win32 Named Pipe (`\\.\pipe\discord-ipc-0`) |
| **Présence Barre d'état** | `NSStatusItem` / `NSMenu` | `AppNotification` / WinUI 3 `NotifyIcon` (System Tray) |
| **Widgets** | WidgetKit (`.systemSmall`, `.systemMedium`) | Windows 11 Widget Provider (Adaptive Cards) + Desktop Widget |
| **Mise à Jour Automatique**| `UpdateService.swift` (zip/dmg + script détaché)| `UpdateService.cs` (zip/msix + script PowerShell détaché) |
| **Localisation (i18n)** | `LocalizationManager.swift` + `fr.json`/`en.json` | `LocalizationManager.cs` + `fr.json`/`en.json` |

---

## 2. Découpage Modulaire des Dossiers

### `Models/` (Modèles purs)
Contient les entités de données sérialisables en JSON avec `System.Text.Json` :
- `User.cs` : Profil utilisateur connecté (id, username, email, role, etc.).
- `ResourceStats.cs` : Quotas et consommation (RAM, Disque, CPU, Serveurs).
- `ServerInstance.cs` / `ServerManagementModels.cs` : Données des serveurs, statut d'alimentation, ressources allouées, renouvellements.
- `DailyRewardModels.cs` : Données de streak, récompenses, historique et classement.
- `StoreModels.cs`, `WalletModels.cs`, `SupportModels.cs`, `UpdateModels.cs`.

### `Services/` (Logique Métier & Réseau)
- `APIClient.cs` : Client HTTP singleton (`HttpClient`) avec persistance des cookies et en-têtes standardisés.
- `AuthService.cs` : Connexion, validation `/api/v5/state`, vérification 2FA (`/auth/2fa/verify`), challenge Passkey et déconnexion.
- `DiscordAuthCoordinator.cs` : Orchestration de la fenêtre WebView2 pour l'authentification OAuth2 Discord et capture des cookies de redirection.
- `PasskeyCoordinator.cs` : Interfaçage avec `webauthn.dll` pour appeler Windows Hello et transmettre l'assertion signée.
- `SessionPersistence.cs` : Sauvegarde chiffrée par **DPAPI** des cookies de session.
- `ServerWebSocketManager.cs` : Gestion du WebSocket de la console serveur avec reconnexion automatique.
- `DiscordRPCService.cs` : Client Named Pipe pour Discord Rich Presence.
- `UpdateService.cs` : Vérification des mises à jour auprès d'`OvernodeApp-Updater`, téléchargement et validation SHA256.

### `ViewModels/` (Couche de Présentation Réactive)
Utilise le toolkit officiel `CommunityToolkit.Mvvm` :
- Hérite de `ObservableObject`.
- Propriétés décorées de `[ObservableProperty]` générant automatiquement les notifications `INotifyPropertyChanged`.
- Commandes déclarées via `[RelayCommand]` avec support asynchrone (`Task`).

### `Views/` (Interface Graphique XAML)
- `AuthView.xaml` : Écran de bienvenue avec logo Overnode, boutons Discord OAuth2 et Passkey.
- `TwoFactorVerificationView.xaml` : Saisie sécurisée du code TOTP à 6 chiffres.
- `DashboardView.xaml` : Vue principale avec les 4 jauges de ressources et la liste des serveurs.
- `ServerDetailView.xaml` : Vue détaillée d'un serveur (Console WebSocket, Fichiers, Variables, Renouvellement).
- `DailyRewardView.xaml`, `StoreView.xaml`, `WalletView.xaml`, `SupportView.xaml`.

---

## 3. Règle UI Stricte
> **IMPORTANT** : Conformément à la charte universelle Overnode, ne **jamais** afficher l'adresse `console.overnode.fr` à l'utilisateur dans l'interface graphique. Utiliser systématiquement **"Console Cloud"** ou **"Overnode"**.
