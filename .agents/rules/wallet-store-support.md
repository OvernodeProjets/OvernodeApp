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
  - L'achat de ressources (RAM, Disque, CPU, Slots serveurs) se fait nativement via coins via `POST /api/store/buy` et crédite instantanément les quotas du compte.
  - **Homogénéité visuelle des boutons de ressource**: Les boutons d'achat des 4 cartes de ressource (RAM, Disque, CPU, Slot Serveur) doivent arborer strictement le même style visuel (fond glassmorphic discret `#15FFFFFF`, bordure subtile, texte blanc SemiBold `OvernodeTextPrimaryBrush`). Le bouton du slot serveur ne doit jamais se démarquer avec un aplat or discordant.
  - **Alignement des Bundles & Abonnements**: Les cartes de bundles doivent être alignées de manière esthétique et uniforme en grille de 3 colonnes (`ColumnDefinition Width="*"`), avec des hauteurs de cartes étirées uniformément (`VerticalAlignment="Stretch"`), une puce d'icône aux couleurs distinctives du pack (`IconColorHex`), une hauteur minimale de description pour éviter tout décalage, et des boutons de souscription obligatoirement ancrés au bas de la carte.
  - Les abonnements bundles s'affichent avec leurs avantages et redirigent vers la page de souscription.
- **Support**:
  - Permettre l'ouverture de tickets natifs (`POST /api/tickets`), la consultation du fil de discussion et l'envoi de messages.
- **AFK**:
  - La session AFK exigeant un WebSocket maintenu en continu, l'écran natif informe l'utilisateur et propose le bouton de redirection vers la session web.
- **CRITICAL UI**: Ne jamais mentionner `console.overnode.fr` dans les libellés de boutons ou textes visibles.

