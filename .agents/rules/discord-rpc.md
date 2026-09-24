# Discord Rich Presence (RPC)

Règles pour l'intégration de Discord Rich Presence dans l'application macOS.

## When this applies

- Modifications du service Discord RPC, gestion de présence ou paramètres associés.

## Rules

- **Client ID officiel**: Utiliser l'identifiant d'application Discord officiel `972921155205877860`.
- **Respect de la vie privée**: Ne JAMAIS afficher les actions précises de l'utilisateur (serveurs gérés, fichiers, consoles). Afficher uniquement qu'il est sur Overnode App.
- **Logo & Liens**: Toujours afficher le logo officiel Overnode et inclure le bouton de redirection vers `https://overnode.fr`.
- **Connexion non-bloquante**: Les communications IPC via socket Unix (`discord-ipc-*`) doivent être exécutées en tâche d'arrière-plan sans jamais bloquer le thread UI principal.
- **Reconnexion résiliente**: Gérer l'absence de Discord au démarrage, les redémarrages de Discord et les fermetures de session proprement avec reconnexion automatique.
- **Activité permanente**: Discord Rich Presence doit rester constamment actif quand l'application est ouverte et ne peut pas être désactivé par l'utilisateur.
- **Silence dans l'interface**: Aucune carte, mention ou contrôle n'est visible dans l'interface utilisateur de l'application. Le service s'exécute de façon transparente et silencieuse en tâche d'arrière-plan.
