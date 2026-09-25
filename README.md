# Overnode Desktop (macOS & Windows)

Dépôt officiel des applications desktop natives pour l'écosystème cloud **Overnode**.
Porte l'expérience de gestion cloud de la Console Cloud directement sur desktop avec performance native, sécurité matérielle, widgets et design moderne.

---

## 🗂️ Organisation du Dépôt

```
OvernodeApp/
├── app-mac/                 # Application native macOS (Swift 6 / SwiftUI / Apple Silicon)
│   ├── README.md            # Guide de compilation et architecture macOS
│   ├── SPECS.md             # Spécifications et intentions techniques macOS
│   ├── Sources/             # Code source Swift (Overnode & WidgetKit)
│   ├── Tests/               # Suite de tests unitaires automatisés
│   └── build_app.sh         # Script de génération du bundle Overnode.app signé
├── app-win/                 # Spécifications & Architecture Windows (C# 12 / .NET 9 / WinUI 3)
│   ├── README.md            # Guide complet de l'application Windows
│   ├── ARCHITECTURE.md      # Correspondances architecturales 1:1 Swift vs WinUI 3
│   ├── SECURITY.md          # Guide de sécurité Windows (DPAPI, WebAuthn, Authenticode)
│   └── WIDGETS.md           # Guide d'implémentation des widgets Windows 11
├── app -> app-mac           # Lien symbolique de compatibilité descendante
├── OvernodeApp-Updater/     # Portail web & API d'administration des mises à jour
├── server-side/             # Backend Overnode (Heliactyl Next Toledo)
├── docs/                    # Captures d'écran et documentation visuelle
└── .agents/rules/           # Règles d'architecture et standards de développement
```

---

## 🚀 Démarrage Rapide

### Application macOS
```bash
# Se rendre dans le dossier macOS (ou via le raccourci `app`)
cd app-mac

# Lancer la suite de tests
swift test

# Compiler l'application macOS
swift build -c release

# Générer le bundle Overnode.app complet
./build_app.sh
```

### Portail Auto-Updater
```bash
cd OvernodeApp-Updater
npm install
npm start
```

---

## 🛡️ Règles & Conventions

- **Règle UI Absolue** : Ne **jamais** afficher l'adresse `console.overnode.fr` à l'utilisateur dans l'interface graphique. Utiliser systématiquement **"Console Cloud"** ou **"Overnode"**.
- **Authentification Sécurisée** : Persistance chiffrée des sessions (Keychain sur macOS, DPAPI sur Windows) et support natif du double facteur (2FA TOTP).
- **Internationalisation (i18n)** : Support complet et dynamique du Français (FR) et de l'Anglais (EN).
