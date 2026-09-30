# Auto-Updater & OvernodeApp-Updater

Règles pour le système de mise à jour automatique, le site de gestion et la CI/CD GitHub.

## When this applies

- Travail sur les services de mise à jour dans `app-mac/Sources/Overnode/Services/UpdateService.swift` ou `app-win/src/Overnode.App/Services/UpdateService.cs`.
- Modification des interfaces de mise à jour (`UpdateModalView.swift`, `UpdateModalControl.xaml`, `SettingsControl.xaml.cs`).
- Maintenance du portail d'administration `OvernodeApp-Updater/`.
- Modification des workflows GitHub Actions `.github/workflows/build-and-release.yml` et `.github/workflows/build-and-release-windows.yml`.

## Rules

- **URL Updater**: Les applications macOS et Windows utilisent l'URL officielle :
  `https://zBvoGzjDABxGuLuKux59LtECbKIpNPcp.overnode.fr`.
- **Contrat API Client**:
  - macOS: `GET /api/v1/update/check?version=<current>&platform=darwin-arm64`
  - Windows: `GET /api/v1/update/check?version=<current>&platform=win-x64`
  - Renvoie `updateAvailable`, `latestVersion`, `downloadUrl`, `rawDownloadUrl`, `releaseNotes`, `mandatory`, `sha256`.
- **Authentification Portail Updater**:
  - Inscription sécurisée par "Code Console" généré au démarrage (`UP-XXXX-XXXX` affiché dans les logs du serveur ou via `CONSOLE_CODE`).
  - Toute tentative sans code console valide DOIT être rejetée.
- **Workflow GitHub Actions macOS**:
  - Exécution sur runner macOS Apple Silicon (`macos-14` / `macos-15`).
  - Vérification obligatoire de l'architecture `arm64` via `file` / `lipo`.
  - Signature de production Apple avec l'adresse e-mail `app@overnode.fr`.
  - Archivage `.zip`, image `.dmg` et calcul de somme de contrôle SHA256 pour la release.
- **Workflow GitHub Actions Windows**:
  - Exécution sur runner Windows (`windows-latest`).
  - Compilation et publication self-contained `win-x64` (.NET 10).
  - Vérification de l'icône d'application PE intégrée (`app_icon.ico`).
  - Packaging MSI natif via WiX Toolset v4+ avec raccourcis Menu Démarrer et Bureau.
  - Archivage `.zip` portable et calcul de somme de contrôle SHA256 pour la release.
- **Cycle de Vie Client (macOS & Windows)**:
  - macOS : Vérification silencieuse à l'ouverture, modale Overnode, redémarrage via script nohup et support .dmg/.zip.
  - Windows : Vérification silencieuse à l'ouverture, modale Overnode WinUI 3 avec barre de progression, téléchargement et validation SHA256, exécution MSI passive via script détaché et relance automatique de `Overnode.App.exe`.

