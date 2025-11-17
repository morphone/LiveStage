# LiveStage - Application de Streaming YouTube

## Vue d'ensemble

LiveStage est une application iOS qui permet de créer et gérer des flux de diffusion en direct sur YouTube. L'application utilise SwiftUI, AVFoundation pour la capture vidéo, et l'API YouTube Data v3.

## Fonctionnalités

### ✅ Implémentées (Base)

- 📋 Liste des streams YouTube
- ➕ Création de nouveaux flux de diffusion
- 📹 Aperçu de la caméra
- 🔄 Changement de caméra (avant/arrière)
- 🎤 Contrôle du microphone
- 📊 Affichage du statut des streams
- 💾 Stockage local avec SwiftData

### 🚧 À implémenter

- 🔐 Authentification OAuth 2.0 complète avec YouTube
- 📡 Encodage et streaming RTMP réel
- 📈 Statistiques de streaming en temps réel
- 🎨 Filtres et effets vidéo
- 💬 Gestion du chat en direct
- 📝 Miniatures personnalisées

## Configuration

### 1. Prérequis

- Xcode 15.0 ou supérieur
- iOS 17.0 ou supérieur
- Un compte développeur Google/YouTube

### 2. Configuration de l'API YouTube

1. **Créer un projet dans Google Cloud Console:**
   - Allez sur https://console.cloud.google.com
   - Créez un nouveau projet ou sélectionnez-en un existant
   - Activez "YouTube Data API v3"

2. **Créer des identifiants OAuth 2.0:**
   - Dans "APIs & Services" > "Credentials"
   - Cliquez sur "Create Credentials" > "OAuth 2.0 Client ID"
   - Choisissez "iOS" comme type d'application
   - Ajoutez votre Bundle ID (com.yourcompany.LiveStage)
   - Notez le Client ID généré

3. **Configurer le fichier YouTubeAPIService.swift:**
   ```swift
   private let clientID = "VOTRE_CLIENT_ID_ICI"
   private let clientSecret = "VOTRE_CLIENT_SECRET_ICI" // Si applicable
   ```

### 3. Configuration Info.plist

Ajoutez les permissions nécessaires dans votre `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>LiveStage a besoin d'accéder à votre caméra pour diffuser du contenu vidéo en direct.</string>

<key>NSMicrophoneUsageDescription</key>
<string>LiveStage a besoin d'accéder à votre microphone pour diffuser du contenu audio en direct.</string>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.yourapp.livestage</string>
        </array>
    </dict>
</array>
```

### 4. Dépendances pour le streaming RTMP (Recommandé)

Pour implémenter le streaming RTMP réel, vous aurez besoin d'une bibliothèque tierce. Recommandations:

#### Option 1: HaishinKit (Recommandé)
```swift
// Dans Package.swift ou via SPM dans Xcode
dependencies: [
    .package(url: "https://github.com/shogo4405/HaishinKit.swift", from: "1.5.0")
]
```

#### Option 2: Implémentation personnalisée
- Encodeur H.264 avec VideoToolbox
- Encodeur AAC avec AudioToolbox
- Client RTMP personnalisé

## Architecture

### Modèles de données

- **YouTubeStream**: Représente un flux de diffusion YouTube
  - Propriétés: titre, description, URL, clé de stream, statut
  - Stocké avec SwiftData

### Services

- **YouTubeAPIService**: Gère l'authentification et les appels API YouTube
  - Authentification OAuth 2.0
  - Création de broadcasts
  - Création de streams
  - Liaison broadcast-stream

- **CameraManager**: Gère la capture vidéo et audio
  - Configuration AVCaptureSession
  - Gestion des permissions
  - Contrôle de la caméra et du microphone
  - Interface pour l'encodage (à implémenter)

### Vues

- **ContentView**: Vue principale avec onglets
- **StreamListView**: Liste de tous les streams
- **CreateStreamView**: Formulaire de création de stream
- **StreamDetailView**: Détails et contrôles de diffusion
- **CameraPreviewView**: Aperçu de la caméra

## Utilisation

### Créer un nouveau stream

1. Lancez l'application
2. Appuyez sur le bouton "+" dans l'onglet Streams
3. Connectez-vous à YouTube (première fois)
4. Remplissez les informations:
   - Titre du stream
   - Description
   - Heure de début prévue
5. Appuyez sur "Créer le flux"

### Démarrer une diffusion

1. Sélectionnez un stream dans la liste
2. Autorisez l'accès à la caméra et au microphone
3. Vérifiez l'aperçu de la caméra
4. Appuyez sur "Démarrer la diffusion"
5. L'indicateur "EN DIRECT" apparaît
6. Appuyez sur "Arrêter la diffusion" pour terminer

## Limitations actuelles

⚠️ **Important**: Le streaming RTMP réel n'est pas encore implémenté. Pour l'activer:

1. Ajoutez HaishinKit ou une bibliothèque similaire
2. Implémentez l'encodage H.264/AAC dans `CameraManager`
3. Configurez la connexion RTMP avec l'URL et la clé du stream
4. Gérez la reconnexion en cas d'erreur réseau

## Sécurité

### Recommandations

- ❌ **Ne committez jamais** vos clés API dans le code source
- ✅ Utilisez des variables d'environnement ou un fichier de configuration local
- ✅ Stockez les tokens OAuth dans le Keychain (pas UserDefaults)
- ✅ Masquez les clés de stream dans l'interface
- ✅ Utilisez HTTPS pour toutes les communications API

### Implémentation du Keychain

Remplacez les méthodes `saveTokenToKeychain` et `loadTokenFromKeychain` dans `YouTubeAPIService.swift` par une vraie implémentation Keychain:

```swift
import Security

func saveTokenToKeychain(_ token: String) {
    let data = token.data(using: .utf8)!
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: "YouTubeAccessToken",
        kSecValueData as String: data
    ]
    
    SecItemDelete(query as CFDictionary)
    SecItemAdd(query as CFDictionary, nil)
}
```

## Support

Pour toute question ou problème:
- Consultez la [documentation YouTube API](https://developers.google.com/youtube/v3)
- Vérifiez les [guides AVFoundation](https://developer.apple.com/av-foundation/)

## Licence

[Insérez votre licence ici]

## Auteur

Michael Chartier - 2025
