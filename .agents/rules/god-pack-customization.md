# Personnalisation Pack God (macOS & Updater)

Règles et architecture du module de personnalisation totale réservé aux possesseurs du Pack God (Toledo & Updater VIP).

## When this applies

- Modification du thème de l'application macOS (`Sources/Overnode/Theme/`), des réglages (`GodPackThemeSettingsCardView.swift`), ou du service d'accès `GodPackService.swift`.
- Gestion des VIP Pack God dans `OvernodeApp-Updater` (`db.js`, `routes/api.js`, `views/dashboard.ejs`).

## Rules

- **CRITICAL (Zero Server-Side Touch)**: Ne JAMAIS modifier le dossier `server-side/` (backend Toledo). La vérification du Pack God s'effectue via l'endpoint existant `/api/bundles/status` et/ou via l'API Updater VIP (`/api/v1/godpack/check/:discordId`).
- **CRITICAL (Accès Exclusif)**: Les options de personnalisation avancée (couleurs, image de fond incrustée, onglet d'arrivée, disposition de la sidebar, rayon de courbure, export/import de configuration) sont strictement réservées aux utilisateurs possédant le Pack God. En l'absence du pack, afficher une bannière informative incitant à l'obtention du pack sur la Boutique.
- **CRITICAL (Format de Configuration)**: L'export et l'import de configuration utilisent le fichier `.overnode.app` (nom par défaut : `config.overnode.app`), contenant un JSON typé et validé (`AppThemeConfig`).
- **CRITICAL (Non-Régression Graphique)**: Les couleurs par défaut de l'application doivent rester strictement identiques à la charte originale (fond `#0B0D13` / `#101218`, accents `#E5B842` / `#F59E0B`). L'application dynamique du thème (`ThemeManager`) ne doit jamais casser le rendu ni afficher de texte sombre sur fond sombre.
- **CRITICAL (Image d'Incrustation)**: L'arrière-plan personnalisé accepte une URL web ou un fichier local Mac avec contrôle précis de l'opacité, du flou gaussien et de l'assombrissement pour garantir la lisibilité du contenu.
- **CRITICAL (Gestion VIP Updater)**: Le portail OvernodeApp-Updater permet aux administrateurs d'ajouter et retirer des identifiants Discord pour accorder l'accès au Pack God sans toucher au serveur de jeu.
