# Easter Egg Félin (macOS)

Spécifications et conventions pour l'Easter Egg secret sur l'application macOS.

## When this applies

- Modification des réglages de l'application macOS (`DashboardView` / `settingsContent`) ou du module `Sources/Overnode/EasterEgg/`.

## Rules

- **CRITICAL**: L'Easter Egg se déclenche via le raccourci clavier `Command + T` uniquement lorsque l'utilisateur se trouve dans l'onglet Réglages (`Settings`).
- **CRITICAL**: Le morceau audio joué est "Dancing Rat x OIIA Cat" (137 BPM, durée ~64.6s).
- **CRITICAL**: La photo `5242E2B2-7A35-4A75-B865-D381C8A47636_1_105_c` est expressément exclue. Seules les 12 poses de chat autorisées (`cat_01` à `cat_12`) sont intégrées.
- **CRITICAL**: L'overlay doit pouvoir être fermé immédiatement via la touche `Échap`, `Command + T` ou le bouton Quitter, coupant proprement le flux audio.
