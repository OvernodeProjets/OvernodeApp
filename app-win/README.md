# Overnode for Windows (WinUI 3 / Windows App SDK / .NET 9)

Application Windows native pour l'écosystème cloud **Overnode**, conçue avec **C# 12 / .NET 9** et **WinUI 3 (Windows App SDK)** pour offrir les mêmes performances, le même design Dark/Gold et les mêmes fonctionnalités que la version macOS.

---

## ✨ Fonctionnalités Windows

- 🔐 **Authentification Native & Sécurisée** :
  - **Discord OAuth2** avec session isolée via **Microsoft Edge WebView2** (`Microsoft.Web.WebView2.Core`).
  - **Passkeys (WebAuthn)** avec prise en charge directe de **Windows Hello** (caméra infrarouge faciale, lecteur d'empreinte digitale, code PIN TPM) via `webauthn.dll`.
  - **Double Facteur TOTP (2FA)** avec saisie directe du code à 6 chiffres.
  - **Chiffrement des Cookies DPAPI & PasswordVault** : Protection matérielle des identifiants et des cookies de session liée à la session Windows de l'utilisateur actif (`ProtectedData.Protect` / `Windows.Security.Credentials.PasswordVault`).
- 📊 **Tableau de Bord & Gestion Cloud** :
  - Métriques d'utilisation en temps réel (RAM, Disque, CPU, Serveurs).
  - Terminal interactif et statistiques en direct par **WebSocket** (`ClientWebSocket`).
  - Gestion des fichiers, sauvegardes, variables de démarrage et sous-utilisateurs.
- 🧩 **Widgets Windows** :
  - **Windows 11 Widgets Board** via le *Windows App SDK Widget Provider API* (`Microsoft.Windows.Widgets.Providers`) au format **Adaptive Cards JSON** (Daily Reward streak, compte à rebours, état des renouvellements serveurs).
  - **Desktop Floating Widget** (widget transparent épinglé au bureau façon macOS Sonoma).
  - **System Tray Flyout interactif** avec mini-tableau de bord et actions d'alimentation rapides.
- ⚡ **Barre d'état & Quick Actions (System Tray)** :
  - Icône dans la zone de notification avec menu contextuel fluide.
  - Raccourcis d'alimentation : Démarrer, Redémarrer, Forcer l'arrêt du serveur sélectionné.
- 🎮 **Discord Rich Presence (RPC)** :
  - Connexion locale via **Named Pipe Win32** (`\\.\pipe\discord-ipc-0` à `9`) en tâche de fond.
  - Respect strict de la vie privée (aucune fuite d'informations sur les serveurs hébergés).
- 🔄 **Système de Mise à Jour Automatique** :
  - Communication avec le portail officiel `OvernodeApp-Updater`.
  - Vérification cryptographique SHA256 et signature numérique Authenticode (`WinVerifyTrust`).

---

## 🛠️ Prérequis & Compilation

### Prérequis
- Windows 10 (version 1809+) ou Windows 11
- [.NET 9 SDK](https://dotnet.microsoft.com/download)
- [Visual Studio 2022](https://visualstudio.microsoft.com/) avec la charge :
  - *Développement .NET Desktop*
  - *Composants Windows App SDK C#*
  - Ou **VS Code** avec l'extension *C# Dev Kit*.

### Commandes de Compilation (.NET CLI)

```powershell
# Cloner et accéder au dossier Windows
cd app-win

# Restaurer les dépendances NuGet
dotnet restore

# Compiler en mode Debug
dotnet build

# Exécuter l'application
dotnet run --project src/Overnode.App

# Lancer la suite de tests
dotnet test
```

### Publication & Packaging Release (Binaire Autonome & AOT)

```powershell
# Publication en binaire unique autonome (Self-Contained Single File)
dotnet publish src/Overnode.App -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:PublishReadyToRun=true -o bin/Release/publish

# Ou compilation native Native AOT (Code machine x64 pur sans IL)
dotnet publish src/Overnode.App -c Release -r win-x64 -p:PublishAot=true -o bin/Release/aot
```

Pour créer un installeur Windows (.exe / .msix) :
```powershell
.\scripts\publish.ps1 -Version "1.1.0"
```

---

## 📁 Architecture du Code Windows

```
app-win/
├── Overnode.Windows.sln             # Solution Visual Studio
├── README.md                        # Documentation générale Windows
├── ARCHITECTURE.md                  # Correspondance détaillée MVVM vs Swift
├── SECURITY.md                      # Guide de sécurité Windows (DPAPI, WebAuthn, Authenticode)
├── WIDGETS.md                       # Guide d'implémentation des widgets Windows 11
├── scripts/                         # Scripts PowerShell de build et packaging
│   ├── build.ps1
│   └── publish.ps1
└── src/
    ├── Overnode.App/                # Application principale WinUI 3
    │   ├── Overnode.App.csproj
    │   ├── App.xaml / App.xaml.cs   # Point d'entrée de l'application
    │   ├── MainWindow.xaml / .cs    # Fenêtre principale avec Mica / Dark theme
    │   ├── Models/                  # Modèles de données (User, Server, DailyReward...)
    │   ├── Services/                # Services (API, AuthService, DPAPI, DiscordRPC...)
    │   ├── ViewModels/              # ViewModels MVVM (CommunityToolkit.Mvvm)
    │   ├── Views/                   # Vues XAML (Auth, Dashboard, Server...)
    │   ├── Theme/                   # Styles XAML Overnode (Dark/Gold, Accents)
    │   └── Localization/            # Fichiers i18n (fr.json / en.json)
    └── Overnode.Widgets/            # Fournisseur de Widgets Windows 11 (Adaptive Cards)
        ├── Overnode.Widgets.csproj
        ├── DailyRewardWidget.cs
        └── ServerRenewalWidget.cs
```
