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
  - Filtrage de chemins strict : déclenché uniquement lors de modifications dans `app-mac/**` (ou tags `v*` / `workflow_dispatch`).
  - Vérification obligatoire de l'architecture `arm64` via `file` / `lipo`.
  - Signature de production Apple avec l'adresse e-mail `app@overnode.fr`.
  - Archivage `.zip`, image `.dmg` et calcul de somme de contrôle SHA256 pour la release.
- **Workflow GitHub Actions Windows**:
  - Exécution sur runner Windows (`windows-latest`).
  - Filtrage de chemins strict : déclenché uniquement lors de modifications dans `app-win/**` (ou tags `v*` / `workflow_dispatch`).
  - Compilation et publication self-contained `win-x64` (.NET 10).
  - Vérification de l'icône d'application PE intégrée (`app_icon.ico`).
  - Packaging MSI natif via WiX Toolset v4+ avec raccourcis Menu Démarrer et Bureau.
  - Archivage `.zip` portable et calcul de somme de contrôle SHA256 pour la release.
- **Versioning SemVer & Releases GitHub**:
  - **CRITICAL**: Ne JAMAIS utiliser `github.run_number` pour définir les numéros de version car les compteurs sont isolés par workflow et écrasent silencieusement les anciennes releases.
  - Déterminer systématiquement la version depuis les tags Git réels (`vX.Y.Z` explicite ou incrément automatique du patch sur le dernier tag SemVer existant).
  - Le serveur `OvernodeApp-Updater` doit toujours trier les releases par ordre SemVer décroissant (`compareVersions`) avec un quota de récupération suffisant (`per_page=100`) pour garantir la détection de la version la plus haute.
- **Cycle de Vie Client (macOS & Windows)**:
  - macOS : Vérification silencieuse à l'ouverture, modale Overnode, redémarrage via script nohup et support .dmg/.zip.
  - Windows : Vérification silencieuse à l'ouverture, modale Overnode WinUI 3 avec barre de progression, téléchargement et validation SHA256, exécution MSI passive via script détaché (`OVERNODE_AUTOUPDATE`), nettoyage préalable du System Tray (`TrayIconManager.Shared.Dispose()`), verrouillage par Mutex d'instance unique et relance automatique d'une seule instance de `Overnode.App.exe`.
- **Isolation Stricte des Plateformes (macOS vs Windows)**:
  - **CRITICAL**: Les releases GitHub peuvent être indépendantes et asynchrones par plateforme (ex: commit ciblant uniquement `app-win/**` générant un tag `v1.1.55` avec uniquement des assets Windows `.msi` et `.zip`).
  - Le serveur `OvernodeApp-Updater` DOIT filtrer strictement les releases par présence d'assets compatibles avec la plateforme (`hasMacAsset` pour `darwin-arm64`, `hasWinAsset` pour `win-x64`).
  - Une release Windows ne doit JAMAIS être notifiée à macOS, et une release macOS ne doit JAMAIS être notifiée à Windows.
  - Le proxy de téléchargement (`/api/v1/update/download`) ne doit JAMAIS servir un asset Windows à macOS ni un asset macOS à Windows.
  - L'application macOS (`UpdateService.swift`) applique une défense en profondeur rejetant activement toute URL `.msi`/`.exe` ou binaire contenant des signatures PE/MSI.

