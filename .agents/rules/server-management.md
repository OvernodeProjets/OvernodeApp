# Server Management

Règles pour la gestion des serveurs dans les applications natives Overnode (macOS & Windows).

## When this applies

- Création ou modification des vues, modèles, services ou view models liés à la gestion des serveurs (console, fichiers, renouvellement, sous-domaines, sous-utilisateurs, packages, plugins, logs, paramètres).

## Rules

- **Modularité**: Chaque sous-onglet (Console, Fichiers, Sous-domaines, Sous-utilisateurs, Paramètres, Plugins, etc.) doit être isolé dans son propre composant dédié (< 150-200 lignes).
- **Sous-domaines (Subdomains)**:
  - Le seul domaine autorisé et proposé en option dans le sélecteur est obligatoirement **`overnode.fr`**.
  - Ne JAMAIS mentionner "Cloudflare" ou "Cloudflare DNS" dans l'UI ou les statuts (utiliser sobrement "Actif" / "Active").
- **Signaux d'alimentation & Console (Server Power & Live Console)**:
  - L'envoi des signaux d'alimentation (`start`, `restart`, `stop`, `kill`) doit être transmis via WebSocket (`set state`) avec repli REST API.
  - L'état local affiché ne doit pas être révoqué si la connexion WebSocket est active.
  - Toutes les modifications de collections de logs console ou de métriques issues du WebSocket doivent obligatoirement être marshalisées sur le thread UI (via `SynchronizationContext` ou `DispatcherQueue`) pour éviter les violations de threading (ex: `COMException` 0x8001010E sous WinUI 3).
  - La console serveur doit supporter la sélection de texte à la souris et la copie directe (`Ctrl+C`), tout en préservant et affichant fidèlement les couleurs (codes ANSI du serveur et coloration sémantique) sans ajout de bouton d'interface superflu.
- **Actions destructives**: Toujours afficher une confirmation visuelle avant toute action critique (Suppression de serveur, réinstallation de serveur, suppression de fichier/dossier, arrêt forcé/kill).
- **Suppression de serveur**: La suppression s'effectue via DELETE /api/v5/servers/:id, restitue les quotas de ressources au pool utilisateur et purge le cache local.
- **Gestion réseau sécurisée**: Les appels API doivent réutiliser `APIClient.shared` avec persistance des cookies de session.
- **Support bilingue**: Chaque chaîne d'interface liée aux serveurs doit exister en Français (`fr.json`) et en Anglais (`en.json`).
- **Charte graphique Overnode**: Respecter le thème sombre (#0B0D13 / #101218, #181B22), les bordures subtiles et les accents colorés Overnode (#E5B842).
- **Serveurs Partagés & Permissions (Subusers)**:
  - Les serveurs où l'utilisateur est invité/sous-utilisateur doivent être récupérés et affichés aux côtés des serveurs propres, avec un badge "Partagé" distinctif (`person.2.fill` ou glyphe WinUI).
  - Chaque `ServerInstance` doit tracker `isOwner` et `permissions`.
  - Les actions d'alimentation (`start`, `restart`, `stop`, `kill`) doivent vérifier les permissions de l'utilisateur (`canStart`, `canRestart`, `canStop`) et être désactivées avec tooltip explicatif si non autorisées.
  - Le renouvellement (`canRenew`) et la suppression définitive (`canDelete`) sont réservés au propriétaire (`isOwner == true`).
- **Actualisation & Rate Limiting**:
  - Lors de la navigation vers la section Serveurs, la liste des serveurs doit s'actualiser automatiquement.
  - Un rate limiter (cooldown d'au moins 5 secondes) doit obligatoirement être appliqué sur `refreshServersOnNavigatingToServersSection` pour éviter de spammer les endpoints API.
- **Édition externe & Synchronisation (External Editor)**:
  - L'ouverture d'un fichier serveur dans un éditeur externe s'effectue via `ExternalEditorManager`.
  - Sous Windows, les fichiers sont ouverts dans un éditeur de texte/code dédié (VS Code, Notepad++, Bloc-notes). Ne JAMAIS exécuter de fichier script (.bat, .cmd, .sh, .ps1) directement via le shell (`ProcessStartInfo.UseShellExecute`) et ne JAMAIS ouvrir de fenêtre d'invite de commandes (`cmd`). Toujours utiliser `CreateNoWindow = true` et `UseShellExecute = false`.
  - Lors d'une modification enregistrée en local (détectée via `FileSystemWatcher` avec gestion de `Renamed` pour les écritures atomiques et polling d'intégrité de secours), la synchronisation vers le serveur (`writeFile`) doit être déclenchée automatiquement en arrière-plan sans bloquer l'UI, et une confirmation visuelle doit être affichée.
  - L'option "Toujours ouvrir avec un éditeur externe" ainsi que le choix de l'éditeur de code doivent être configurables dans les Paramètres et respectés au double-clic ou à l'ouverture de fichier.
- **Téléversement de Fichiers & Dossiers (Drag & Drop)**:
  - L'upload s'effectue exclusivement par glisser-déposer dans l'onglet Fichiers, sans bouton ni logo additionnel sur l'interface.
  - La sécurité et la conformité des fichiers sont vérifiées par `FileUploadSecurity` :
    - Exclusion automatique des résidus système macOS (`.DS_Store`, `__MACOSX`, `._*`, `.localized`, `.Trashes`).
    - Protection stricte contre les traversées de chemin (`..`, `\`, caractères de contrôle, doubles barres obliques).
    - Respect des limites d'upload : limite unitaire de 100 Mo par fichier, maximum 500 éléments par lot, et contrôle systématique de l'espace disque disponible restant par rapport au quota serveur (`server.diskLimitMB - server.diskUsedMB`).
  - Pour les dossiers, la hiérarchie des sous-dossiers est créée sur le serveur avant le transfert multipart des fichiers vers l'endpoint sécurisé Wings (`ServerFilesService.shared.getUploadURL`).
