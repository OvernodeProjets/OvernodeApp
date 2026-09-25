# Widgets Overnode pour Windows

Ce guide présente les solutions d'implémentation des widgets Overnode sous Windows, équivalents aux widgets WidgetKit de macOS (Daily Reward & Server Renewals).

---

## 1. Solution 1 : Le panneau officiel des Widgets Windows 11 (Recommandé)

Windows 11 propose un volet des widgets officiel accessible via le raccourci `Win + W` ou la barre des tâches.

### Architecture Technique
- **API** : `Microsoft.Windows.Widgets.Providers` (inclus dans le Windows App SDK).
- **Format de rendu** : **Adaptive Cards JSON** (standard déclaratif multiplateforme développé par Microsoft).
- **Cycle de vie** : Windows active le `WidgetProvider` en tâche de fond quand le widget est visible ou doit être mis à jour.

### Exemple de template Adaptive Card pour le Daily Reward (`DailyRewardWidget.json`)

```json
{
  "type": "AdaptiveCard",
  "version": "1.5",
  "backgroundImage": {
    "url": "https://overnode.fr/assets/widget_bg.png"
  },
  "body": [
    {
      "type": "ColumnSet",
      "columns": [
        {
          "type": "Column",
          "width": "auto",
          "items": [
            {
              "type": "Image",
              "url": "https://overnode.fr/assets/overnode_icon.png",
              "size": "Small"
            }
          ]
        },
        {
          "type": "Column",
          "width": "stretch",
          "items": [
            {
              "type": "TextBlock",
              "text": "OVERNODE",
              "weight": "Bolder",
              "size": "Small",
              "color": "Light"
            },
            {
              "type": "TextBlock",
              "text": "DAILY REWARD",
              "size": "ExtraSmall",
              "color": "Warning"
            }
          ]
        },
        {
          "type": "Column",
          "width": "auto",
          "items": [
            {
              "type": "TextBlock",
              "text": "🔥 ${streak}d",
              "weight": "Bolder",
              "color": "Warning"
            }
          ]
        }
      ]
    },
    {
      "type": "Container",
      "spacing": "Medium",
      "items": [
        {
          "type": "TextBlock",
          "text": "${statusMessage}",
          "size": "Large",
          "weight": "Bolder",
          "color": "Light"
        },
        {
          "type": "TextBlock",
          "text": "+${rewardAmount} coins disponibles",
          "size": "Small",
          "color": "Default"
        }
      ]
    }
  ],
  "actions": [
    {
      "type": "Action.Execute",
      "title": "Réclamer la récompense",
      "verb": "claimReward"
    }
  ]
}
```

---

## 2. Solution 2 : Le Widget de Bureau Flottant (Desktop Overlay)

Pour une expérience identique aux widgets sur le bureau de macOS Sonoma :

### Implémentation WinUI 3
Une fenêtre WinUI 3 légère sans bordure avec effet de transparence Acrylic / Mica :

```csharp
using Microsoft.UI.Xaml;
using System;
using System.Runtime.InteropServices;

public sealed partial class DesktopWidgetWindow : Window
{
    private const int GWL_EXSTYLE = -20;
    private const int WS_EX_TOOLWINDOW = 0x00000080;
    private static readonly IntPtr HWND_BOTTOM = new IntPtr(1);
    private const uint SWP_NOSIZE = 0x0001;
    private const uint SWP_NOMOVE = 0x0002;
    private const uint SWP_NOACTIVATE = 0x0010;

    [DllImport("user32.dll")]
    private static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

    [DllImport("user32.dll")]
    private static extern int GetWindowLong(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll")]
    private static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    public DesktopWidgetWindow()
    {
        this.InitializeComponent();
        
        var hwnd = WinRT.Interop.WindowNative.GetWindowHandle(this);
        
        // Empêcher l'apparition dans Alt+Tab
        int exStyle = GetWindowLong(hwnd, GWL_EXSTYLE);
        SetWindowLong(hwnd, GWL_EXSTYLE, exStyle | WS_EX_TOOLWINDOW);

        // Épingler au fond du bureau Windows
        SetWindowPos(hwnd, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
    }
}
```

---

## 3. Solution 3 : System Tray Flyout (Barre des Tâches)

Sur Windows, la zone de notification (près de l'horloge) est l'équivalent direct de la Menu Bar macOS :
- **Clic Gauche** : Ouvre une petite fenêtre moderne XAML façon carte widget (Daily Reward streak, compte à rebours, état des renouvellements et solde de coins).
- **Clic Droit** : Affiche le menu contextuel rapide (Démarrer le serveur, Redémarrer, Forcer l'arrêt, Ouvrir Overnode, Quitter).
