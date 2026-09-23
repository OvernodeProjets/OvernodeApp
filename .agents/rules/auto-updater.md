# Auto-Updater & OvernodeApp-Updater

Règles pour le système de mise à jour automatique, le site de gestion et la CI/CD GitHub.

## When this applies

- Travail sur les services de mise à jour dans `app/Sources/Overnode/Services/UpdateService.swift`.
- Modification de l'interface de mise à jour (`UpdateModalView.swift`, `DashboardView.swift`).
- Maintenance du portail d'administration `OvernodeApp-Updater/`.
- Modification du workflow GitHub Actions `.github/workflows/build-and-release.yml`.

## Rules

- **URL Updater**: L'application macOS utilise l'URL officielle :
  `https://zBvoGzjDABxGuLuKux59LtECbKIpNPcp.overnode.fr`.
- **Contrat API Client**:
  - `GET /api/v1/update/check?version=<current>&platform=darwin-arm64` renvoie `updateAvailable`, `latestVersion`, `downloadUrl`, `releaseNotes`, `mandatory`.
- **Authentification Portail Updater**:
  - Inscription sécurisée par "Code Console" généré au démarrage (`UP-XXXX-XXXX` affiché dans les logs du serveur ou via `CONSOLE_CODE`).
  - Toute tentative sans code console valide DOIT être rejetée.
- **Workflow GitHub Actions**:
  - Exécution sur runner macOS Apple Silicon (`macos-14` / `macos-15`).
  - Vérification obligatoire de l'architecture `arm64` via `file` / `lipo`.
  - Signature de production Apple avec l'adresse e-mail `app@overnode.fr`.
  - Archivage `.zip` et calcul de somme de contrôle SHA256 pour la release.
- **Cycle de Vie Client macOS**:
  - Vérification automatique et silencieuse à l'ouverture de l'application.
  - Affichage de la modale Overnode avec notes de version et progression du téléchargement.
  - Remplacement et redémarrage propre via script d'installation détaché (nohup).
  - Support universel des archives .dmg (montage hdiutil) et .zip (ditto) avec validation d'intégrité avant substitution.

