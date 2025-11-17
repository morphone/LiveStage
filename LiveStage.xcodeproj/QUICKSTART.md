# 🚀 Quick Start - LiveStage

## 3 Minutes pour Démarrer

### Option 1 : Test Rapide (Sans YouTube)

L'application fonctionne déjà pour tester l'interface !

```bash
1. Ouvrir le projet dans Xcode
2. Sélectionner votre iPhone/iPad ou simulateur
3. ⌘ + R (Compiler et lancer)
4. Autoriser l'accès caméra/micro quand demandé
```

✅ **Vous pouvez déjà :**
- Voir l'interface complète
- Tester l'aperçu de la caméra
- Créer des streams locaux (sans les envoyer à YouTube)
- Explorer toutes les vues

---

### Option 2 : Avec YouTube (Complet)

#### Étape 1 : Google Cloud (5 min)

1. **Aller sur** → https://console.cloud.google.com
2. **Créer un projet** → "Nouveau projet" → "LiveStage"
3. **Activer l'API** → "APIs & Services" → "Library" → Rechercher "YouTube Data API v3" → "Activer"
4. **Créer identifiants** → "Credentials" → "Create Credentials" → "OAuth 2.0 Client ID"
   - Type: iOS
   - Bundle ID: `com.yourcompany.LiveStage` (ou votre Bundle ID)
5. **Copier le Client ID** → Il ressemble à : `123456789-abcdefg.apps.googleusercontent.com`

#### Étape 2 : Xcode (2 min)

**A. Configurer Info.plist**

Ouvrir `Info.plist` et ajouter :

```xml
<key>NSCameraUsageDescription</key>
<string>Pour diffuser du contenu vidéo en direct</string>

<key>NSMicrophoneUsageDescription</key>
<string>Pour diffuser du contenu audio en direct</string>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.yourcompany.livestage</string>
        </array>
    </dict>
</array>
```

**B. Configurer le Client ID**

**Méthode 1 : Variables d'environnement (Recommandé)**

1. Product → Scheme → Edit Scheme
2. Run → Arguments → Environment Variables
3. Ajouter : `YOUTUBE_CLIENT_ID` = votre_client_id

**Méthode 2 : Directement dans Config.swift**

Ouvrir `Config.swift` ligne 37 :

```swift
static var clientID: String {
    return "VOTRE_CLIENT_ID_ICI"  // Remplacer
}
```

⚠️ **Ne committez pas ce fichier avec la vraie clé !**

#### Étape 3 : Lancer (30 sec)

```bash
⌘ + R
```

✅ **C'est tout !** L'authentification YouTube fonctionne maintenant.

---

## 🔧 Ajouter le Streaming RTMP (Optionnel)

Pour diffuser VRAIMENT sur YouTube :

### Installer HaishinKit

1. **Dans Xcode** → File → Add Packages...
2. **URL** → `https://github.com/shogo4405/HaishinKit.swift`
3. **Version** → 1.5.0 ou supérieure
4. **Add Package**

### Décommenter RTMPStreamManager

Ouvrir `RTMPStreamManager.swift` et décommenter tout le code entre les `/* */`

### L'utiliser dans StreamDetailView

Remplacer `CameraManager` par `RTMPStreamManager` dans `StreamDetailView.swift`

---

## 📱 Utilisation

### Créer un Stream

1. Lancer l'app
2. Onglet "Streams"
3. Bouton `+` en haut à droite
4. Se connecter à YouTube (première fois)
5. Remplir :
   - **Titre** : "Mon Premier Live"
   - **Description** : "Test de streaming"
   - **Heure** : Maintenant ou plus tard
6. Appuyer sur "Créer le flux"

✅ Le stream est créé sur YouTube !

### Démarrer la Diffusion

1. Sélectionner le stream dans la liste
2. Autoriser caméra et micro
3. Vérifier l'aperçu
4. Appuyer sur "▶️ Démarrer la diffusion"
5. L'indicateur "🔴 EN DIRECT" apparaît

### Arrêter

Appuyer sur "⏹️ Arrêter la diffusion"

---

## 🐛 Problèmes Courants

### "Client ID invalide"

→ Vérifier que le Bundle ID correspond entre Google Cloud et Xcode

### "Permission refusée"

→ Réglages → Confidentialité → Caméra → Activer LiveStage

### "Caméra ne fonctionne pas"

→ Tester sur un iPhone/iPad physique (pas le simulateur)

### "API retourne une erreur"

→ Vérifier que YouTube Data API v3 est activée dans Google Cloud

---

## 📚 Prochaines Lectures

- **README.md** → Documentation complète
- **INSTALLATION.md** → Guide détaillé
- **PROJECT_SUMMARY.md** → Vue d'ensemble du projet
- **RTMPStreamManager.swift** → Exemples de streaming

---

## 💡 Tips

### Raccourcis Xcode

- `⌘ + R` → Compiler et lancer
- `⌘ + B` → Compiler seulement
- `⌘ + .` → Arrêter
- `⌘ + Shift + K` → Clean build

### Déboguer

- **Console** → Afficher les logs (`⌘ + Shift + Y`)
- **Breakpoints** → Ajouter avec click gauche dans la marge
- **Print** → `print("Debug: \(variable)")`

### Tester

- Sur simulateur → Interface uniquement
- Sur appareil physique → Caméra et streaming

---

## 🎉 Voilà !

En 3 étapes vous avez :
- ✅ Une interface complète
- ✅ La connexion YouTube
- ✅ La gestion des streams
- 🔄 Le streaming (avec HaishinKit)

**Bon streaming ! 📹**
