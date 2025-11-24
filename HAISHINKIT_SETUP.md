# 🎬 HaishinKit Setup Guide - LiveStage

## Vue d'ensemble

Ce guide explique comment ajouter et configurer **HaishinKit** dans le projet LiveStage pour activer le streaming RTMP complet avec encodage H.264/AAC.

## ⚠️ État Actuel

Le `RTMPStreamManager.swift` est **prêt pour HaishinKit** mais utilise actuellement un mode **sans dépendances externes**. Cela permet de tester et développer sans installer HaishinKit immédiatement.

## 📦 Ajout de HaishinKit via SPM

### Étape 1 : Ajouter le package dans Xcode

```
1. Ouvrir LiveStage.xcodeproj dans Xcode
2. Aller à : File → Add Packages...
3. URL du repository : https://github.com/shogo4405/HaishinKit.swift
4. Version : 1.5.0 ou supérieure (branch: main)
5. Cliquer sur "Add Package"
```

### Étape 2 : Ajouter HaishinKit au target

```
1. Dans l'interface Build Phases
2. Lier HaishinKit au target LiveStage
3. Ajouter l'import dans les fichiers nécessaires
```

## 🔧 Configuration du RTMPStreamManager

Une fois HaishinKit ajouté, décommenter les sections marquées `/* Décommentez après avoir ajouté HaishinKit */` dans `RTMPStreamManager.swift`.

### Zones à décommenter :

1. **Import HaishinKit** (ligne ~25)
```swift
import HaishinKit
```

2. **setupRTMP()** (lignes 123-160)
   - Configure l'encodeur vidéo H.264
   - Configure l'encodeur audio AAC
   - Règle le framerate et la résolution

3. **attachCamera()** (lignes 184-201)
   - Attache la caméra au stream RTMPStream

4. **attachAudio()** (lignes 204-221)
   - Attache le microphone au stream

5. **toggleMicrophone()** (lignes 236-240)
   - Contrôle le flux audio

6. **startStreaming()** (lignes 270-283)
   - Connexion au serveur RTMP
   - Publication du stream

7. **stopStreaming()** (lignes 309-317)
   - Fermeture propre de la connexion

8. **updateMetrics()** (lignes 346-358)
   - Monitoring FPS/Bitrate
   - Calcul de la santé du stream

9. **setVideoQuality()** (lignes 395-401)
   - Ajustement dynamique de la qualité

10. **enableAdaptiveBitrate()** (lignes 410-417)
    - Activation du bitrate adaptatif

## 🎯 Configuration Vidéo HaishinKit

### Encodeur H.264

```swift
stream.videoSettings = [
    .width: 1280,                    // 720p width
    .height: 720,                    // 720p height
    .bitrate: 3_000_000,            // 3 Mbps
    .maxKeyFrameIntervalDuration: 2, // Keyframe tous les 2s
    .profileLevel: kVTProfileLevel_H264_High_AutoLevel
]
```

**Paramètres recommandés par résolution :**

| Résolution | Bitrate | Framerate | FPS |
|-----------|---------|-----------|-----|
| 480p      | 1.5 Mbps| 30        | 30  |
| 720p      | 3 Mbps  | 30        | 30  |
| 1080p     | 6 Mbps  | 30        | 30  |
| 4K        | 15 Mbps | 24-30     | 24  |

## 🎵 Configuration Audio HaishinKit

```swift
stream.audioSettings = [
    .bitrate: 128_000,      // 128 kbps
    .sampleRate: 44100,     // 44.1 kHz
    .channels: 2            // Stéréo
]
```

## 🔌 Connexion RTMP

### Format URL YouTube Live

```
rtmps://a.rtmp.youtube.com/live2/{STREAM_KEY}
```

### Exemple d'utilisation

```swift
let streamManager = RTMPStreamManager()

// Demander les permissions
await streamManager.requestPermissions()

// Démarrer le stream
try await streamManager.startStreaming(
    to: "rtmps://a.rtmp.youtube.com/live2",
    key: "YOUR_STREAM_KEY"
)
```

## 📊 Monitoring et Santé du Stream

Le `RTMPStreamManager` suit :

- **FPS** : Images par seconde (cible 30)
- **Bitrate** : Bitrate actuel (en kbps)
- **Santé du stream** :
  - 🟢 **Excellent** : >80% succès packets
  - 🟡 **Bon** : 60-80% succès
  - 🟠 **Juste** : 40-60% succès
  - 🔴 **Pauvre** : <40% succès

### Accéder aux métriques

```swift
streamManager.$bitrate  // Reactive bitrate
streamManager.$fps      // Reactive FPS
streamManager.$streamHealth  // Stream health indicator
```

## 🔄 Reconnexion Automatique

En cas de déconnexion réseau, le manager tente une reconnexion automatique avec **exponential backoff** :

- Tentative 1 : 1 seconde
- Tentative 2 : 2 secondes
- Tentative 3 : 4 secondes
- Tentative 4 : 8 secondes
- Tentative 5 : 16 secondes

**Maximum 5 tentatives**, puis abandon avec message d'erreur.

## 📱 Intégration dans StreamDetailView

```swift
struct StreamDetailView: View {
    @Bindable var stream: YouTubeStream
    @StateObject private var streamManager = RTMPStreamManager()

    var body: some View {
        VStack {
            // Aperçu caméra (avec HaishinKit)
            // HKView(streamManager.rtmpStream)
            //     .frame(height: 300)

            // Statut de connexion
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)

                Text(streamManager.connectionStatus.description)
            }

            // Métriques
            Text("Bitrate: \(streamManager.bitrate) kbps")
            Text("FPS: \(streamManager.fps)")
            Text("Santé: \(streamManager.streamHealth.indicator)")

            // Bouton de contrôle
            Button {
                if streamManager.isStreaming {
                    streamManager.stopStreaming()
                } else {
                    Task {
                        try await streamManager.startStreaming(
                            to: stream.streamURL ?? "",
                            key: stream.streamKey ?? ""
                        )
                    }
                }
            } label: {
                Text(streamManager.isStreaming ? "Arrêter" : "Démarrer")
            }
        }
        .task {
            await streamManager.requestPermissions()
        }
    }

    private var statusColor: Color {
        switch streamManager.connectionStatus {
        case .connected: return .green
        case .connecting, .reconnecting: return .yellow
        case .disconnected: return .gray
        case .error: return .red
        }
    }
}
```

## 🛠️ Dépannage

### HaishinKit ne compile pas

**Solutions :**
1. Vérifier que SPM peut atteindre GitHub
2. Nettoyer le build : Product → Clean Build Folder
3. Vérifier la version de Xcode (15.0+)
4. Réinstaller le package

### Stream ne se connecte pas

**Vérifications :**
1. ✅ Permissions caméra/microphone accordées
2. ✅ URL RTMP correcte (rtmps://)
3. ✅ Stream key valide
4. ✅ Connexion internet stable
5. ✅ Logs dans Xcode Console

### La vidéo se saccade

**Solutions :**
1. Réduire la résolution (1080p → 720p)
2. Réduire le bitrate (6Mbps → 3Mbps)
3. Vérifier la connexion réseau
4. Activer le bitrate adaptatif

### Pas de son

**Vérifications :**
1. ✅ Permission microphone accordée
2. ✅ `AVAudioSession` configurée correctement
3. ✅ Microphone n'est pas muet
4. ✅ Logs pour erreurs attachement audio

## 📝 Logging

Tous les événements de streaming sont loggés via `AppLogger` :

```swift
// Logs dans Xcode Console ou Console.app
AppLogger.stream.info("▶️  Démarrage du stream")
AppLogger.stream.error("❌ Erreur de connexion RTMP")
AppLogger.logRTMPConnection(url: url, success: true)
```

## 🧪 Tests

Les tests existants dans `LiveStageTests.swift` incluent :

- État initial du manager
- Contrôle caméra/microphone
- Validation des paramètres
- Statuts de connexion

Exécuter les tests :

```bash
xcodebuild test -scheme LiveStage
```

## 📚 Ressources

- **HaishinKit GitHub** : https://github.com/shogo4405/HaishinKit.swift
- **YouTube API** : https://developers.google.com/youtube/v3
- **RTMP Specification** : https://www.adobe.com/devnet/rtmp.html
- **VideoToolbox** : https://developer.apple.com/documentation/videotoolbox

## ✅ Checklist Configuration

- [ ] HaishinKit ajouté via SPM
- [ ] Sections décommentées dans RTMPStreamManager
- [ ] Import HaishinKit ajouté
- [ ] AppError et AppLogger disponibles
- [ ] Permissions caméra/microphone configurées dans Info.plist
- [ ] Tests compilent et passent
- [ ] Logs fonctionnels dans Console
- [ ] StreamDetailView intégré avec RTMPStreamManager
- [ ] Streaming URL et clé testés

---

**Prochaines étapes :** Tester le streaming avec un vrai serveur RTMP (YouTube Live)
