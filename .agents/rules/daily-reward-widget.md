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
  - Le widget est configuré exclusivement en **anglais** ("Daily Reward", "Ready to Claim", "Next Reward in", etc.).
  - Le temps restant avant minuit / la prochaine récompense est affiché d'abord en **heures**, puis en **minutes** (ex: "5h 24m remaining", ou "Ready to Claim!" quand disponible).
  - Support des formats de widget macOS (.systemSmall, .systemMedium).
  - Utilisation de la charte graphique Overnode : fond sombre (#14161c), accents dorés (#D4AF37) et typographie SF Pro / Monospaced pour le timer.
  - Stockage partagé (UserDefaults partagés ou suite d'app) pour lire l'état du claim et synchroniser le statut du widget.
- **CRITICAL UI**: Ne jamais mentionner `console.overnode.fr` dans l'UI du widget ou de l'application.

