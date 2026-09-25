# Daily Reward & Apple Widget Module

Règles de fonctionnement pour le module Daily Reward et l'extension Widget Apple macOS.

## When this applies

- Modifications ou ajouts dans `app/Sources/Overnode/Views/DailyReward/`, les widgets WidgetKit dans `app/Sources/OvernodeWidget/`, ou les services et modèles de récompense quotidienne.

## Rules

- **Daily Reward Core**:
  - Les endpoints utilisés sont `/api/daily-rewards/status`, `/claim`, `/protection`, `/leaderboard`, `/history`.
  - La réclamation d'une récompense doit instantanément mettre à jour le solde de l'utilisateur et déclencher l'actualisation globale du Dashboard.
  - Le serveur Overnode ne doit en aucun cas être modifié.
- **Apple WidgetKit Extension**:
  - Le widget est configuré exclusivement en **anglais** ("Daily Reward", "Ready to Claim", "Next Reward in", "SERVERS RENEWAL", "NEXT RENEWAL", etc.).
  - Le temps restant avant minuit / la prochaine récompense est affiché d'abord en **heures**, puis en **minutes** (ex: "5h 24m remaining", ou "Ready to Claim!" quand disponible).
  - Support des formats de widget macOS (.systemSmall, .systemMedium).
  - Utilisation de la charte graphique Overnode : fond sombre (#14161c), accents dorés (#D4AF37) et typographie SF Pro / Monospaced pour les timers.
  - Stockage partagé inter-processus via pont universel `/Users/Shared/Overnode/daily_reward_widget.json` et `/Library/Application Support/Overnode/` avec entitlements sandbox explicites (`temporary-exception.files.home-relative-path.read-write` et `absolute-path.read-write`).
- **Server Renewal Integration**:
  - Le petit widget (.systemSmall) affiche le prochain serveur arrivant à expiration (`nextExpiringServer`) sous forme de pill compact en bas (`[Rack] [Nom] [Temps]`), avec code couleur (rouge si expiré, ambre si < 24h, gris/doré sinon).
  - Le widget moyen (.systemMedium) intègre un panneau droit dédié `SERVERS RENEWAL` affichant jusqu'à 2-3 serveurs avec indicateur d'état, nom tronqué, temps restant (ex: "2d 4h", "10h 30m", "< 1m", "Expired") et bouton badge "Renew".
  - Synchronisation automatique orchestrée par `DailyRewardSyncManager` interrogeant `AuthService.shared.fetchServersStatus()` et `ServerService.shared.fetchRenewalStatus(serverId:)` en parallèle via `withTaskGroup`.
- **CRITICAL UI**: Ne jamais mentionner `console.overnode.fr` dans l'UI du widget ou de l'application.

