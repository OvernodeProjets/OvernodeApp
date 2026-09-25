# UI & Copywriting Rules

Règles de contenu et d'interface pour l'application macOS Overnode.

## When this applies

- Création ou modification de vues, textes d'interface, boutons ou messages d'erreur.

## Rules

- **CRITICAL**: Ne JAMAIS mentionner l'URL ou le domaine `console.overnode.fr` à l'utilisateur dans l'interface (titres, sous-titres, infobulles, dialogues).
- **Appellation recommandée**: Toujours utiliser **"Console Cloud"** ou **"Overnode"**.
- **Logos officiels**: Utiliser exclusivement `overnode_logo.png` et `overnode_icon.png` dans l'interface interne, et `statusbar_icon.png` exclusivement pour la barre de menus macOS (StatusBar). L'icône officielle de l'application (Dock, Finder, dossier Applications) est `AppIcon.icns` avec fond sombre `#1a1d25` (rgba(26, 29, 37)) et nuage blanc centré.
- **Authentification 2FA**: Les utilisateurs ayant la 2FA activée doivent être guidés sur l'écran natif `TwoFactorVerificationView` sans jamais être redirigés vers un navigateur externe.
