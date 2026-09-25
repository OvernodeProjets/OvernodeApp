# Menu Bar & Quick Actions

Règles pour la gestion du Menu Bar (NSStatusItem) et des Quick Actions Overnode.

## When this applies

- Création, modification ou maintenance de l'élément de la barre de menus macOS (Menu Bar / Status Bar), des raccourcis rapides d'actions serveur (Démarrer / Redémarrer / Forcer l'arrêt), ou des paramètres associés.

## Rules

- **Présence en tâche de fond**: L'icône de la barre des menus (`MenuBarManager`) doit rester active dès le lancement de l'application et lorsque la fenêtre principale est masquée ou fermée, sans quitter le processus.
- **Icône système native**: Utiliser le logo silhouette monochrome Overnode en mode `isTemplate = true` pour s'adapter automatiquement aux modes Clair et Sombre de macOS.
- **Sélection du serveur cible**: L'utilisateur sélectionne son serveur Quick Action dans les Paramètres de l'application. La sélection est persistée de façon fiable dans `UserDefaults` (avec écoute des notifications et synchronisation temps réel).
- **Contrôle d'alimentation sécurisé**: Les commandes Start, Restart et Kill doivent invoquer `ServerService.shared.sendPowerSignal` et rafraîchir l'état du serveur de façon asynchrone sans bloquer l'UI.
- **Actions rapides du menu**:
  - Statut du serveur (Nom, Statut, CPU, RAM)
  - Démarrer (Start)
  - Redémarrer (Restart)
  - Forcer l'arrêt (Kill)
  - Accéder à l'application / Ouvrir Overnode
  - Quitter Overnode
- **Support bilingue**: Chaque chaîne du menu bar et des réglages associés doit exister en Français (`fr.json`) et en Anglais (`en.json`).

