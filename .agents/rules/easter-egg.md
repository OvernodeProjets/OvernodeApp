# Easter Egg Félin (macOS & Windows)

Spécifications et conventions pour l'Easter Egg secret sur les applications macOS et Windows.

## When this applies

- Modification des réglages de l'application (`DashboardView` / `Settings`) ou des modules Easter Egg (`Sources/Overnode/EasterEgg/` sur macOS, `Overnode.App/Views/EasterEgg/` & `Overnode.App/Services/EasterEgg*.cs` sur Windows).

## Rules

- **CRITICAL**: L'Easter Egg se déclenche via le raccourci clavier `Command + T` sur macOS et `Control + T` (`Ctrl + T`) sur Windows, uniquement lorsque l'utilisateur se trouve dans l'onglet Réglages (`Settings`) sans serveur sélectionné.
- **CRITICAL**: Le morceau audio joué est "Dancing Rat x OIIA Cat" (137 BPM, durée ~64.6s).
- **CRITICAL**: La photo `5242E2B2-7A35-4A75-B865-D381C8A47636_1_105_c` est expressément exclue. Seules les 12 poses de chat autorisées (`cat_01` à `cat_12`) sont intégrées.
- **CRITICAL**: L'overlay doit pouvoir être fermé immédiatement via la touche `Échap`, le raccourci clavier (`Command + T` / `Ctrl + T`) ou le bouton Quitter, coupant proprement le flux audio.

