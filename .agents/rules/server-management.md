# Server Management

Règles pour la gestion des serveurs dans l'application macOS Overnode.

## When this applies

- Création ou modification des vues, modèles, services ou view models liés à la gestion des serveurs (console, fichiers, renouvellement, sous-domaines, sous-utilisateurs, packages, plugins, logs, paramètres).

## Rules

- **Modularité**: Chaque sous-onglet (Console, Fichiers, Sous-domaines, Sous-utilisateurs, Paramètres, Plugins, etc.) doit être isolé dans son propre fichier Swift dédié (< 150-200 lignes).
- **Actions destructives**: Toujours afficher une confirmation visuelle avant toute action critique (Suppression de serveur, réinstallation de serveur, suppression de fichier/dossier, arrêt forcé/kill).
- **Suppression de serveur**: La suppression s'effectue via DELETE /api/v5/servers/:id, restitue les quotas de ressources au pool utilisateur et purge le cache local.
- **Gestion réseau sécurisée**: Les appels API doivent réutiliser `APIClient.shared` avec persistance des cookies de session.
- **Support bilingue**: Chaque chaîne d'interface liée aux serveurs doit exister en Français (`fr.json`) et en Anglais (`en.json`).
- **Charte graphique Overnode**: Respecter le thème sombre (#101218, #181B22, #202229), les bordures subtiles et les accents colorés Overnode.
- **Serveurs Partagés & Permissions (Subusers)**:
  - Les serveurs où l'utilisateur est invité/sous-utilisateur doivent être récupérés et affichés aux côtés des serveurs propres, avec un badge "Partagé" distinctif (`person.2.fill`).
  - Chaque `ServerInstance` doit tracker `isOwner` et `permissions`.
  - Les actions d'alimentation (`start`, `restart`, `stop`, `kill`) doivent vérifier les permissions de l'utilisateur (`canStart`, `canRestart`, `canStop`) et être désactivées avec tooltip explicatif si non autorisées.
  - Le renouvellement (`canRenew`) et la suppression définitive (`canDelete`) sont réservés au propriétaire (`isOwner == true`).
- **Actualisation & Rate Limiting**:
  - Lors de la navigation vers la section Serveurs, la liste des serveurs doit s'actualiser automatiquement.
  - Un rate limiter (cooldown d'au moins 5 secondes) doit obligatoirement être appliqué sur `refreshServersOnNavigatingToServersSection` pour éviter de spammer les endpoints API.
- **Édition externe & Synchronisation (External Editor)**:
  - L'ouverture d'un fichier serveur dans un éditeur externe s'effectue via `ExternalEditorManager`.
  - Lors d'une modification enregistrée en local, la synchronisation vers le serveur (`writeFile`) doit être déclenchée automatiquement en arrière-plan sans bloquer l'UI.
  - L'option "Toujours ouvrir avec un éditeur externe" doit être configurable dans les Paramètres et respectée au double-clic.
- **Téléversement de Fichiers & Dossiers (Drag & Drop)**:
  - L'upload s'effectue exclusivement par glisser-déposer (`.onDrop(of: [UTType.fileURL])`) dans l'onglet Fichiers, sans bouton ni logo additionnel sur l'interface.
  - La sécurité et la conformité des fichiers sont vérifiées par `FileUploadSecurity` :
    - Exclusion automatique des résidus système macOS (`.DS_Store`, `__MACOSX`, `._*`, `.localized`, `.Trashes`).
    - Protection stricte contre les traversées de chemin (`..`, `\`, caractères de contrôle, doubles barres obliques).
    - Respect des limites d'upload : limite unitaire de 100 Mo par fichier, maximum 500 éléments par lot, et contrôle systématique de l'espace disque disponible restant par rapport au quota serveur (`server.diskLimitMB - server.diskUsedMB`).
  - Pour les dossiers, la hiérarchie des sous-dossiers est créée sur le serveur avant le transfert multipart des fichiers vers l'endpoint sécurisé Wings (`ServerFilesService.shared.getUploadURL`).
