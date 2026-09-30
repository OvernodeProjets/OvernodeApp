# Menu Bar & Quick Actions (macOS & Windows)

Règles pour la gestion du Menu Bar macOS (NSStatusItem) et du System Tray Windows (Shell_NotifyIcon) pour les Quick Actions Overnode.

## When this applies

- Création, modification ou maintenance de la présence en barre de menus macOS (`MenuBarManager`) ou de la zone de notification Windows (`TrayIconManager`), des raccourcis rapides d'actions serveur (Démarrer / Arrêter / Redémarrer / Forcer l'arrêt), ou des paramètres associés.

## Rules

- **Présence en tâche de fond**: L'icône de la barre des menus (`MenuBarManager` sur macOS) et de la zone de notification (`TrayIconManager` sur Windows) doit rester active dès le lancement de l'application et lorsque la fenêtre principale est masquée ou fermée (`AppWindow.Closing`), sans quitter le processus.
- **Icône système native**:
  - **macOS**: Utiliser le logo silhouette monochrome Overnode en mode `isTemplate = true` (`statusbar_icon.png`).
  - **Windows**: Utiliser l'icône silhouette transparente Overnode sans fond (`statusbar_icon.ico` / nuage monochrome) pour s'adapter à la barre des tâches et aux thèmes Windows 10/11.
- **Sélection du serveur cible**: L'utilisateur sélectionne son serveur Quick Action dans les Paramètres. La sélection est persistée de façon fiable (`UserDefaults` sur macOS, `QuickActionServerStorage` JSON sur Windows) avec écoute des notifications et synchronisation temps réel.
- **Contrôle d'alimentation sécurisé**: Les commandes Start, Stop, Restart et Kill doivent invoquer le service d'API serveur (`ServerService.shared.sendPowerSignal` sur macOS, `ServerService.Shared.SendPowerSignalAsync` sur Windows) et rafraîchir l'état du serveur de façon asynchrone sans bloquer l'UI.
- **Actions rapides du menu**:
  - En-tête : Overnode
  - Statut du serveur (Nom, Statut, CPU, RAM)
  - Démarrer (Start)
  - Arrêter (Stop)
  - Redémarrer (Restart)
  - Forcer l'arrêt (Kill) avec confirmation
  - Accéder à l'application / Ouvrir Overnode (restaurer la fenêtre principale)
  - Quitter Overnode (fermeture définitive et nettoyage de l'icône)
- **Support bilingue**: Chaque chaîne du menu bar / tray et des réglages associés doit exister en Français (`fr.json`) et en Anglais (`en.json`).
