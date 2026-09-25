# Sécurité & Durcissement de l'Application Overnode Windows

Ce guide détaille les obligations et bonnes pratiques de sécurité à implémenter pour la version Windows d'Overnode.

---

## 1. Stockage Sécurisé des Sessions (L'équivalent Keychain)

Sous macOS, `SessionPersistence.swift` utilise le Keychain (`kSecClassGenericPassword`). Sous Windows, les données de session sensibles (cookies de session `connect.sid`, tokens d'authentification) doivent être impérativement chiffrées.

### Utilisation de DPAPI (Data Protection API)
Windows intègre l'API cryptographique **DPAPI** qui chiffre les données en utilisant une clé dérivée du mot de passe de l'utilisateur Windows et du matériel local (puce TPM 2.0).

```csharp
using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;

public static class SecureSessionStorage
{
    private static readonly byte[] Entropy = Encoding.UTF8.GetBytes("Overnode.SessionProtection.v1");
    private static readonly string StoragePath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "Overnode", "session.dat"
    );

    public static void SaveSession(string rawJson)
    {
        byte[] plainBytes = Encoding.UTF8.GetBytes(rawJson);
        byte[] encryptedBytes = ProtectedData.Protect(
            plainBytes, 
            Entropy, 
            DataProtectionScope.CurrentUser
        );

        Directory.CreateDirectory(Path.GetDirectoryName(StoragePath)!);
        File.WriteAllBytes(StoragePath, encryptedBytes);
    }

    public static string? LoadSession()
    {
        if (!File.Exists(StoragePath)) return null;

        try
        {
            byte[] encryptedBytes = File.ReadAllBytes(StoragePath);
            byte[] plainBytes = ProtectedData.Unprotect(
                encryptedBytes, 
                Entropy, 
                DataProtectionScope.CurrentUser
            );
            return Encoding.UTF8.GetString(plainBytes);
        }
        catch
        {
            return null; // Données corrompues ou autre utilisateur Windows
        }
    }
}
```

---

## 2. Passkeys (WebAuthn) avec Windows Hello

Pour reproduire le comportement de Touch ID sur macOS, l'application Windows doit solliciter **Windows Hello** via l'API officielle **`webauthn.dll`** (API Win32 C native supportée depuis Windows 10 version 1903) :

- L'application récupère le challenge serveur depuis `/api/auth/passkeys/options`.
- Elle invoque la fonction native `WebAuthNAuthenticatorGetAssertion`.
- Windows Hello affiche la boîte de dialogue système native (empreinte digitale, reconnaissance faciale ou code PIN matériel).
- L'assertion signée est ensuite renvoyée au backend Overnode (`/api/auth/passkeys/verify`).

---

## 3. Discord OAuth2 & Sandbox WebView2

Pour l'authentification Discord OAuth2 :
- Utiliser un dossier de profil isolé pour WebView2 :
  ```csharp
  var options = new CoreWebView2EnvironmentOptions();
  var env = await CoreWebView2Environment.CreateAsync(null, isolatedPath, options);
  await webView.EnsureCoreWebView2Async(env);
  ```
- Désactiver les fonctionnalités superflues (téléchargements, devtools en production, accès aux fichiers locaux).
- Intercepter la navigation de retour pour capturer les cookies de session et fermer immédiatement la fenêtre de connexion.

---

## 4. Sécurité des Named Pipes Discord RPC

Discord sous Windows écoute sur le pipe nommé `\\.\pipe\discord-ipc-0` :
- Utiliser `NamedPipeClientStream` avec un délai d'expiration strict (timeout 1000ms) pour éviter tout blocage réseau.
- Vérifier que l'exécutable Discord légitime est bien le détenteur du pipe pour prévenir toute usurpation de flux local.

---

## 5. Signature de Code (Authenticode) & SmartScreen

Sur Windows, tout exécutable non signé déclenche **Microsoft Defender SmartScreen** ("Windows a protégé votre ordinateur").
- **Signature obligatoire** : Signer les fichiers `.exe`, `.dll` et `.msix` avec l'outil `signtool.exe` lors de la release CI/CD.
  ```powershell
  signtool sign /f certificate.pfx /p $CertPassword /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 "bin\Release\publish\Overnode.exe"
  ```

---

## 6. Sécurité de l'Auto-Updater

L'auto-updater Windows doit suivre les mêmes règles strictes que la version macOS :
1. **HTTPS Strict** sur le domaine officiel `https://zBvoGzjDABxGuLuKux59LtECbKIpNPcp.overnode.fr`.
2. **Contrôle d'intégrité SHA256** calculé avant tout remplacement de fichier binaire.
3. **Vérification de signature** via l'API Win32 `WinVerifyTrust` pour s'assurer que le binaire provient bien d'Overnode.
4. **Pas d'élévation inutile** : Exécuter l'application dans le contexte utilisateur standard (sans droits administrateur UAC) pour minimiser la surface d'attaque.
