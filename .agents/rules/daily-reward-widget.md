# Daily Reward & Apple Widget Module

Règles de fonctionnement pour le module Daily Reward et l'extension Widget Apple macOS.

## When this applies

- Modifications ou ajouts dans `app-mac/Sources/Overnode/Views/DailyReward/`, les widgets WidgetKit dans `app-mac/Sources/OvernodeWidget/`, ou les services et modèles de récompense quotidienne.

## Rules

- **Daily Reward Core**:
  - Les endpoints utilisés sont `/api/daily-rewards/status`, `/claim`, `/protection`, `/leaderboard`, `/history`.
  - La réclamation d'une récompense doit instantanément mettre à jour le solde de l'utilisateur et déclencher l'actualisation globale du Dashboard.
  - Le serveur Overnode ne doit en aucun cas être modifié.
- **Apple WidgetKit Extension**:
  - Deux widgets natifs distincts sont exposés via `OvernodeWidgetBundle` :
    1. **`OvernodeDailyRewardWidget` ("Daily Reward")** : suivi des séries, bonus de pièces et compte à rebours avant la prochaine réclamation (.systemSmall et .systemMedium).
    2. **`OvernodeServerRenewalWidget` ("Server Renewals")** : suivi de l'ouverture du renouvellement des serveurs cloud (.systemSmall affiche en grand le compte à rebours avant que le serveur soit renouvelable "RENEWABLE IN" ex: "23h 58m", ou "READY TO RENEW" quand le serveur est renouvelable, .systemMedium affiche la timeline des serveurs avec le délai d'ouverture de chaque renouvellement).
  - Les deux widgets sont configurés exclusivement en **anglais** ("Daily Reward", "Server Renewals", "RENEWABLE IN", "READY TO RENEW", "SERVERS TIMELINE", "Renew", etc.).
  - Le temps restant avant ouverture de renouvellement ou avant expiration est affiché d'abord en **jours/heures**, puis en **heures/minutes** (ex: "23h 58m", "2d 14h", ou "< 1m", "Expired").
  - Support des formats macOS (.systemSmall, .systemMedium).
  - Utilisation de la charte graphique Overnode : fond sombre (#14161c), accents dorés (#D4AF37), alertes ambre (#FF7A2F), vert émeraude (#10B981) et rouge (#EF4444).
  - Stockage partagé inter-processus via pont universel `/Users/Shared/Overnode/daily_reward_widget.json` et `/Library/Application Support/Overnode/` avec entitlements sandbox explicites (`temporary-exception.files.home-relative-path.read-write` et `absolute-path.read-write`).
- **CRITICAL UI**: Ne jamais mentionner `console.overnode.fr` dans l'UI du widget ou de l'application.

