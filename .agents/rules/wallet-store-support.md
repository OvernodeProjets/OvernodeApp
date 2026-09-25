# Wallet, Store & Support Modules

Règles de fonctionnement pour les modules Wallet, Store (Boutique), Support et AFK.

## When this applies

- Modifications ou ajouts dans `app-mac/Sources/Overnode/Views/Wallet/`, `Store/`, `Support/`, `AFK/` ou leurs modèles et services associés.

## Rules

- **Wallet**:
  - Afficher les soldes de coins et de crédits (EUR/USD) de manière synchronisée.
  - Les boutons d'ajout de crédits ("Add Funds") et d'achat de packs de coins redirigent de manière transparente vers l'URL web du Wallet (`https://console.overnode.fr/wallet`).
  - Intégrer le Top 25 du classement (Leaderboard) avec mise en avant du rang de l'utilisateur.
- **Store & Ressources**:
  - L'achat de ressources (RAM, Disque, CPU, Slots) se fait nativement via coins via `POST /api/store/buy` et crédite instantanément les quotas du compte.
  - Les abonnements bundles (Auto Renew, Upgraded Pack, God Pack) s'affichent avec leurs avantages et redirigent vers la page de souscription (`https://console.overnode.fr/coin/store`).
- **Support**:
  - Permettre l'ouverture de tickets natifs (`POST /api/tickets`), la consultation du fil de discussion et l'envoi de messages.
- **AFK**:
  - La session AFK exigeant un WebSocket maintenu en continu, l'écran natif informe l'utilisateur et propose le bouton de redirection vers la session web.
- **CRITICAL UI**: Ne jamais mentionner `console.overnode.fr` dans les libellés de boutons ou textes visibles.

