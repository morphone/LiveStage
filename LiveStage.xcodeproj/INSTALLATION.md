# Guide d'Installation - LiveStage

## ✅ Ce qui a été créé

Voici tous les fichiers créés pour votre application de streaming YouTube :

### 📁 Modèles de données
- `YouTubeStream.swift` - Modèle SwiftData pour les flux de diffusion

### 🔧 Services
- `YouTubeAPIService.swift` - Service pour l'API YouTube (authentification, création de streams)
- `CameraManager.swift` - Gestionnaire de caméra et capture vidéo/audio
- `KeychainHelper.swift` - Helper sécurisé pour stocker les tokens
- `Config.swift` - Configuration centralisée de l'application

### 🎨 Vues
- `ContentView.swift` - Vue principale avec onglets (mise à jour)
- `StreamListView.swift` - Liste de tous les streams YouTube
- `CreateStreamView.swift` - Formulaire de création de stream
- `StreamDetailView.swift` - Vue détaillée avec contrôles de diffusion
- `CameraPreviewView.swift` - Aperçu de la caméra en temps réel

### 📄 Configuration
- `Info.plist.example` - Exemple de configuration des permissions
- `README.md` - Documentation complète
- `INSTALLATION.md` - Ce fichier

## 🚀 Prochaines étapes

### 1. Configurer les permissions dans Info.plist

Ajoutez ces clés à votre `Info.plist` (ou copiez depuis `Info.plist.example`) :

```xml
<key>NSCameraUsageDescription</key>
<string>LiveStage a besoin d'accéder à votre caméra pour diffuser du contenu vidéo en direct sur YouTube.</string>

<key>NSMicrophoneUsageDescription</key>
<string>LiveStage a besoin d'accéder à votre microphone pour diffuser du contenu audio en direct sur YouTube.</string>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.livestage</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.yourcompany.livestage</string>
        </array>
    </dict>
</array>
```

### 2. Configurer l'API YouTube

#### A. Créer un projet Google Cloud

1. Allez sur https://console.cloud.google.com
2. Cliquez sur "Créer un projet" ou sélectionnez un projet existant
3. Nommez votre projet (ex: "LiveStage App")

#### B. Activer YouTube Data API v3

1. Dans le menu, allez à "APIs & Services" > "Library"
2. Recherchez "YouTube Data API v3"
3. Cliquez sur "Activer"

#### C. Créer des identifiants OAuth 2.0

1. Allez à "APIs & Services" > "Credentials"
2. Cliquez sur "Create Credentials" > "OAuth 2.0 Client ID"
3. Si demandé, configurez l'écran de consentement OAuth :
   - Choisissez "External"
   - Remplissez les informations requises
   - Ajoutez les scopes YouTube nécessaires
4. Créez l'identifiant OAuth :
   - Type : iOS
   - Nom : LiveStage iOS
   - Bundle ID : Votre Bundle ID (ex: `com.yourcompany.LiveStage`)
5. **Notez le Client ID généré**

#### D. Configurer le Client ID dans l'app

**Option 1 : Variables d'environnement (Recommandé)**

Dans Xcode :
1. Product > Scheme > Edit Scheme
2. Run > Arguments > Environment Variables
3. Ajoutez :
   - `YOUTUBE_CLIENT_ID` = votre client ID
   - `YOUTUBE_CLIENT_SECRET` = votre secret (si applicable)

**Option 2 : Modifier directement Config.swift**

⚠️ Attention : Ne committez jamais ce fichier avec vos vraies clés !

```swift
static var clientID: String {
    return "VOTRE_CLIENT_ID_REEL_ICI"
}
```

### 3. Mettre à jour le Bundle ID

Dans `Config.swift`, remplacez `com.yourcompany.livestage` par votre vrai Bundle ID partout où il apparaît.

### 4. Ajouter les dépendances pour le streaming RTMP (Optionnel mais recommandé)

Pour implémenter le streaming RTMP réel, ajoutez HaishinKit :

#### Via Swift Package Manager dans Xcode :

1. File > Add Packages...
2. Entrez l'URL : `https://github.com/shogo4405/HaishinKit.swift`
3. Sélectionnez la version (1.5.0 ou supérieure)
4. Cliquez sur "Add Package"

#### Ensuite, mettez à jour CameraManager.swift :

```swift
import HaishinKit

// Dans startStreaming()
let rtmpConnection = RTMPConnection()
let rtmpStream = RTMPStream(connection: rtmpConnection)

rtmpStream.attachCamera(DeviceUtil.device(withPosition: currentCamera))
rtmpStream.attachAudio(AVCaptureDevice.default(for: .audio))

let fullURL = "\(url)/\(key)"
rtmpConnection.connect(fullURL)
rtmpStream.publish("")
```

### 5. Tester l'application

#### Test sans streaming réel :

L'application peut être testée sans implémenter le streaming RTMP complet :

1. ✅ Vous pouvez créer des streams (ils seront stockés localement)
2. ✅ Vous pouvez voir l'aperçu de la caméra
3. ✅ Vous pouvez gérer la liste des streams
4. ❌ Le streaming RTMP réel ne fonctionnera pas encore

#### Pour activer le streaming réel :

Suivez l'étape 4 ci-dessus pour ajouter HaishinKit et implémenter l'encodage RTMP.

## 🔐 Sécurité - Points importants

### ✅ À faire :

- Utiliser des variables d'environnement pour les clés API
- Stocker les tokens dans le Keychain (déjà implémenté)
- Ne jamais committer les vraies clés API dans Git
- Utiliser HTTPS pour toutes les requêtes API

### ❌ À ne pas faire :

- Hardcoder les clés API dans le code
- Stocker les tokens dans UserDefaults
- Partager les clés API publiquement
- Afficher les clés de stream en clair dans l'interface

## 📱 Configuration du .gitignore

Ajoutez ces lignes à votre `.gitignore` :

```gitignore
# Configuration locale avec clés API
Config.swift.local
APIKeys.plist

# Fichiers Xcode
*.xcuserstate
xcuserdata/
```

## 🧪 Test de l'authentification YouTube

Pour tester l'authentification OAuth sans terminer l'implémentation complète :

1. Le bouton "Se connecter à YouTube" affichera l'URL d'authentification dans la console
2. Vous pouvez copier cette URL et l'ouvrir dans Safari
3. Après autorisation, vous obtiendrez un code de redirection
4. Pour l'instant, vous devrez extraire le code manuellement de l'URL

Pour une implémentation complète, vous devrez ajouter :

```swift
import AuthenticationServices

// Dans YouTubeAPIService.authenticate()
let session = ASWebAuthenticationSession(
    url: authURL,
    callbackURLScheme: Config.YouTube.redirectURI.components(separatedBy: ":").first
) { callbackURL, error in
    // Extraire le code et appeler exchangeCodeForToken()
}
session.presentationContextProvider = self
session.start()
```

## 📚 Ressources utiles

- [Documentation YouTube Data API v3](https://developers.google.com/youtube/v3)
- [Guide OAuth 2.0 de Google](https://developers.google.com/identity/protocols/oauth2)
- [AVFoundation Programming Guide](https://developer.apple.com/av-foundation/)
- [HaishinKit Documentation](https://github.com/shogo4405/HaishinKit.swift)

## 🐛 Dépannage

### "Client ID invalide"
- Vérifiez que le Bundle ID correspond dans Google Cloud Console et Xcode
- Assurez-vous que le Client ID est correctement configuré

### "Permissions refusées"
- Vérifiez que les descriptions dans Info.plist sont présentes
- Réinitialisez les permissions : Réglages > Confidentialité > Caméra/Microphone

### "Session de capture ne démarre pas"
- Testez sur un appareil physique (pas le simulateur)
- Vérifiez les permissions dans les réglages iOS

### "API YouTube retourne une erreur"
- Vérifiez que l'API YouTube Data v3 est activée dans Google Cloud
- Vérifiez les quotas API dans la console Google Cloud
- Assurez-vous que les scopes OAuth sont corrects

## 💡 Fonctionnalités futures à implémenter

1. **Authentification complète** avec ASWebAuthenticationSession
2. **Streaming RTMP** avec HaishinKit ou solution personnalisée
3. **Refresh token automatique** quand l'access token expire
4. **Statistiques en temps réel** (viewers, likes, etc.)
5. **Chat en direct** avec l'API YouTube Live Streaming
6. **Miniatures personnalisées** pour les streams
7. **Enregistrement local** en même temps que le streaming
8. **Filtres et effets** pour la vidéo
9. **Mode paysage** optimisé
10. **Support iPad** avec interface adaptée

## 🎉 Vous êtes prêt !

Une fois ces étapes terminées, vous devriez avoir :
- ✅ Une interface fonctionnelle pour gérer les streams
- ✅ L'aperçu caméra fonctionnel
- ✅ La création de streams YouTube via l'API
- ✅ Le stockage sécurisé des tokens
- 🔄 Le streaming RTMP (à implémenter avec HaishinKit)

Bon développement ! 🚀
