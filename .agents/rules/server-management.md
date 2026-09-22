# Server Management

Règles pour la gestion des serveurs dans l'application macOS Overnode.

## When this applies

- Création ou modification des vues, modèles, services ou view models liés à la gestion des serveurs (console, fichiers, renouvellement, sous-domaines, sous-utilisateurs, packages, plugins, logs, paramètres).

## Rules

- **Modularité**: Chaque sous-onglet (Console, Fichiers, Sous-domaines, Sous-utilisateurs, Paramètres, Plugins, etc.) doit être isolé dans son propre fichier Swift dédié (< 150-200 lignes).
- **Actions destructives**: Toujours afficher une confirmation visuelle avant toute action critique (Réinstallation de serveur, suppression de fichier/dossier, arrêt forcé/kill).
- **Gestion réseau sécurisée**: Les appels API doivent réutiliser `APIClient.shared` avec persistance des cookies de session.
- **Support bilingue**: Chaque chaîne d'interface liée aux serveurs doit exister en Français (`fr.json`) et en Anglais (`en.json`).
- **Charte graphique Overnode**: Respecter le thème sombre (#101218, #181B22, #202229), les bordures subtiles et les accents colorés Overnode.

