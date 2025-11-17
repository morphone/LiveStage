# 🗓️ PLAN D'ACTION: 40-50 HEURES

## Phase 1: FONDATION (Semaine 1) - 14-16 heures

### Sprint 1.1: OAuth Authentification Complète (6 heures)

**Objectif:** Utilisateur peut se connecter avec Google et obtenir tokens

**Tasks:**
```
1. [1h] Configurer URL schemes dans Info.plist
   - Ajouter com.livestage://oauth-callback
   - Tester avec xcrun openurl

2. [2h] Implémenter ASWebAuthenticationSession
   - Nouvelle fonction authenticate() complète
   - Gestion callback URL
   - Extraction du code d'autorisation
   - Gestion annulation utilisateur

3. [1h] Améliorer exchangeCodeForToken()
   - Appel POST /token
   - Extraction access_token, refresh_token, expires_in
   - Stockage dans Keychain

4. [1h] Ajouter logout
   - Suppression tokens Keychain
   - Revenir à login

5. [1h] Tests unitaires OAuth
   - Mock ASWebAuthenticationSession
   - Test échange code/token
   - Test gestion erreurs

Fichiers à modifier: YouTubeAPIService.swift, Info.plist
```

---

### Sprint 1.2: Refresh Token Automatique (4 heures)

**Objectif:** Token se renouvelle automatiquement avant expiration

**Tasks:**
```
1. [1h] Ajouter Timer de refresh
   - Calculer expires_in
   - Programmer refresh 5min avant expiration
   - Stocker l'heure d'expiration

2. [1.5h] Implémenter refreshToken()
   - Appel POST avec refresh_token
   - Nouveau access_token
   - Mise à jour Keychain
   - Re-programmer le timer

3. [1h] Gestion erreur "invalid_grant"
   - Relancer authenticate()
   - Afficher message à l'utilisateur
   - Clear tokens

4. [0.5h] Tests
   - Mock Timer
   - Test expiration correcte
   - Test gestion erreur

Fichiers à modifier: YouTubeAPIService.swift, LiveStageTests.swift
```

---

### Sprint 1.3: Gestion Erreurs Fondamentale (4-5 heures)

**Objectif:** Erreurs affichées clairement à l'utilisateur

**Tasks:**
```
1. [1h] Créer enum d'erreurs complètes
   enum AppError: LocalizedError {
       case networkError(Error)
       case invalidResponse
       case authenticationFailed
       case apiError(statusCode: Int)
       case tokenExpired
       case streamingError(String)
   }

2. [1h] Implémenter localizedDescription
   - Message français pour chaque erreur
   - Suggestions action (Réessayer, Paramètres, etc.)

3. [1h] Ajouter Alert d'erreur dans vues
   - @State var error: AppError?
   - .alert quand error != nil
   - Action Retry/Cancel/Settings

4. [1h] Logging avec OSLog
   - Créer Logger(subsystem: "com.livestage")
   - Logger API calls (sans tokens!)
   - Logger erreurs avec contexte

5. [0.5h] Tests
   - Test types erreurs
   - Test messages localisés
   - Test Alert affichage

Fichiers: YouTubeAPIService.swift, AppError.swift (nouveau), Views
```

---

**Fin Phase 1:** ✅ Utilisateur peut se connecter, tokens se renouvellent, erreurs affichées

---

## Phase 2: STREAMING DE BASE (Semaine 2) - 16-20 heures

### Sprint 2.1: HaishinKit Setup et Configuration (5-6 heures)

**Objectif:** Streaming RTMP fonctionnel avec H.264/AAC

**Tasks:**
```
1. [1h] Ajouter HaishinKit via SPM
   - https://github.com/shogo4405/HaishinKit.swift.git
   - Configuration XCFramework
   - Vérifier import compile

2. [1.5h] Configuration encodeurs
   - H.264 video encoder
   - AAC audio encoder
   - Bitrate: 2500 kbps (configurable)
   - FPS: 30 (configurable)
   - Résolution: 720p (configurable)

3. [1h] Configuration audio
   - AVAudioSession
   - Input audio depuis microphone
   - Mélange avec caméra

4. [1h] Configuration vidéo
   - Décommenter RTMPStreamManager
   - Intégrer CameraManager
   - Attachment du flux caméra

5. [0.5h] Tests
   - Vérifier initialisation
   - Vérifier pas de crash au démarrage

Fichiers: RTMPStreamManager.swift (décommenter), Package.swift, Config.swift
```

---

### Sprint 2.2: Connexion Serveur RTMP (4-5 heures)

**Objectif:** Streaming vers serveur YouTube RTMP

**Tasks:**
```
1. [1h] Récupérer URL RTMP depuis YouTube
   - Depuis stream technique créé par API
   - Format: rtmps://a.rtmp.youtube.com/live2/xxx
   - Stocker dans YouTubeStream.streamURL

2. [1.5h] Initialiser HKStream avec URL
   - HKStream(URL: rtmpURL)
   - Publish vers serveur
   - Gestion connexion établie/fermée

3. [1h] Gestion reconnexion
   - Détecter déconnexion
   - Exponential backoff (1s, 2s, 4s, 8s, max 30s)
   - Réessayer max 5 fois
   - Afficher statut à l'utilisateur

4. [0.5h] Métriques basiques
   - Afficher "EN DIRECT"
   - Bouton "Stop Stream"
   - Indicateur connexion (connecté/reconnexion/erreur)

5. [0.5h] Tests
   - Mock RTMP server
   - Test connexion
   - Test reconnexion

Fichiers: RTMPStreamManager.swift, YouTubeStream.swift, StreamDetailView.swift
```

---

### Sprint 2.3: Tests Intégration Streaming (3-4 heures)

**Objectif:** Tests d'intégration complètes

**Tasks:**
```
1. [1h] Tests HaishinKit
   - Mock HKStream
   - Test publish
   - Test error handling

2. [1h] Tests reconnexion
   - Simuler déconnexion
   - Vérifier backoff
   - Vérifier max retries

3. [1h] Tests intégration
   - Créer stream YouTube → Obtenir RTMP URL → Start streaming → Stop streaming

4. [0.5h] Performance & Memory
   - Instruments: profiler
   - Vérifier memory leaks
   - Vérifier CPU usage
   - Vérifier batterie

Fichiers: LiveStageTests.swift, RTMPStreamManagerTests.swift (nouveau)
```

---

**Fin Phase 2:** ✅ Peut streamer vers YouTube RTMP, reconnexion automatique

---

## Phase 3: ROBUSTESSE (Semaine 2.5) - 8-10 heures

### Sprint 3.1: Validation Input Utilisateur (3-4 heures)

**Objectif:** Aucune donnée invalide ne peut être envoyée

**Tasks:**
```
1. [1h] Créer ValidatorHelper
   - isValidStreamTitle(String) -> Bool
   - isValidDescription(String) -> Bool
   - isValidScheduleDate(Date) -> Bool

2. [1h] Intégrer dans CreateStreamView
   - TextField avec onChange validation
   - Afficher erreur en temps réel
   - Désactiver bouton Create si invalide
   - Afficher caractères restants

3. [0.5h] Ajouter sanitization
   - Supprimer caractères spéciaux dangereux
   - Encoder les caractères spéciaux

4. [0.5h] Tests
   - Test titre vide
   - Test titre trop long
   - Test date passée
   - Test description > 5000 chars

Fichiers: ValidatorHelper.swift (nouveau), CreateStreamView.swift, LiveStageTests.swift
```

---

### Sprint 3.2: Logging Complèt (3-4 heures)

**Objectif:** Tous les événements loggés avec niveau approprié

**Tasks:**
```
1. [1h] Créer AppLogger helper
   - Wrapper OSLog
   - Catégories: API, Camera, Auth, Stream, UI
   - Niveaux: debug, info, warning, error

2. [1h] Ajouter logging dans services
   - YouTubeAPIService: API calls (URL, statut)
   - CameraManager: Permission, configuration
   - RTMPStreamManager: Connexion, reconnexion, bitrate
   - KeychainHelper: Erreurs (pas les valeurs!)

3. [0.5h] Logging erreurs
   - Tous les catch blocks
   - Contexte: fonction, paramètres, stacktrace

4. [0.5h] Tests
   - Vérifier logs générés
   - Vérifier no tokens dans logs

Fichiers: AppLogger.swift (nouveau), Tous les services, Tests
```

---

### Sprint 3.3: Amélioration Gestion Erreurs (2-3 heures)

**Objectif:** Retry automatique, meilleurs messages

**Tasks:**
```
1. [1h] Ajouter RetryHelper
   - Exponential backoff
   - Jitter pour éviter thundering herd
   - Max retries configurable

2. [1h] Appliquer retry
   - API calls: max 3 retries (sauf 4xx)
   - RTMP: max 5 retries (déjà fait)
   - Autres: max 2 retries

3. [0.5h] Améliorer messages erreurs
   - Spécifique par type erreur
   - Suggestions action claires
   - Pas de texte technique pour utilisateur

Fichiers: RetryHelper.swift (nouveau), YouTubeAPIService.swift, Views
```

---

**Fin Phase 3:** ✅ Inputs validées, logging complet, erreurs robustes

---

## Phase 4: QUALITÉ & TESTS (Semaine 3) - 10-14 heures

### Sprint 4.1: Tests Unitaires Couverture 80% (6-8 heures)

**Objectif:** Au moins 80% des lignes testées

**Tasks:**
```
1. [2h] YouTubeAPIService Tests
   - authenticate() avec ASWebAuthenticationSession mock
   - exchangeCodeForToken() avec mock URLSession
   - refreshToken() flow
   - createBroadcast()
   - createStream()
   - bindStreamToBroadcast()
   - Tous les cas d'erreur (401, 403, 500, timeout)

2. [1.5h] CameraManager Tests
   - setupSession()
   - requestCameraPermission()
   - switchCamera()
   - toggleAudio()
   - Gestion permissions (denied, restricted)

3. [1h] RTMPStreamManager Tests
   - Initialisation
   - Publish
   - Erreurs connexion
   - Reconnexion

4. [1h] Models & Helpers Tests
   - YouTubeStream CRUD
   - ValidatorHelper
   - KeychainHelper (mock)
   - Config

5. [0.5h] Coverage Report
   - xcov ou Xcode coverage
   - Identifier code non testé
   - Remplir les gaps

Fichiers: LiveStageTests.swift (développer), Nouveau: YouTubeAPIServiceTests.swift
```

---

### Sprint 4.2: Tests UI (2-3 heures)

**Objectif:** Tester workflows critiques dans UI

**Tasks:**
```
1. [1h] Tests d'intégration StreamListView
   - Affichage liste vide
   - Affichage liste avec streams
   - Bouton créer
   - Suppression stream

2. [0.5h] Tests CreateStreamView
   - Affichage formulaire
   - Validation en temps réel
   - Bouton créer désactivé/activé

3. [0.5h] Tests StreamDetailView
   - Affichage détails
   - Bouton Start/Stop
   - Affichage erreurs

4. [0.5h] Tests Navigation
   - TabView switch
   - Navigation création → liste

Fichiers: LiveStageUITests.swift (nouveau)
```

---

### Sprint 4.3: Tests d'Intégration (2-3 heures)

**Objectif:** Workflows complets testés

**Tasks:**
```
1. [1h] Workflow complet OAuth
   - Login → Token obtenu → Token en Keychain → Refresh → Token updated

2. [1h] Workflow complet Streaming
   - Créer stream YouTube → Obtenir RTMP URL → Start streaming → Stop streaming

3. [0.5h] Performance & Memory
   - Instruments: profiler
   - Vérifier memory leaks
   - Vérifier CPU usage
   - Vérifier batterie

Fichiers: IntegrationTests.swift (nouveau)
```

---

### Sprint 4.4: Refinement Code & Documentation (2 heures)

**Objectif:** Code prêt production, bien documenté

**Tasks:**
```
1. [0.5h] Code Review
   - Identifier code smell
   - Simplifier functions complexes
   - Ajouter docstrings manquants

2. [0.5h] Linting
   - Configurer SwiftLint
   - Corriger violations
   - Ajouter au build

3. [0.5h] Documentation
   - Mettre à jour README avec OAuth flow
   - Ajouter guide RTMP setup
   - Documenter env variables
   - Troubleshooting section

4. [0.5h] Release prep
   - Bumper version 1.0.0
   - Créer RELEASE_NOTES.md
   - Vérifier todos supprimés

Fichiers: Tous, README.md, ARCHITECTURE.md
```

---

**Fin Phase 4:** ✅ Tests à 80%+, code propre, documenté, prêt production

---

## TIMELINE COMPLÈTE

| Phase | Sprint | Durée | Cumul | État |
|-------|--------|-------|-------|------|
| **Phase 1: Fondation** | | **14-16h** | **14-16h** | Semaine 1 |
| | 1.1 OAuth | 6h | 6h | |
| | 1.2 Refresh | 4h | 10h | |
| | 1.3 Erreurs | 4-5h | 14-15h | |
| **Phase 2: Streaming** | | **16-20h** | **30-35h** | Semaine 2 |
| | 2.1 HaishinKit | 5-6h | 19-21h | |
| | 2.2 RTMP Connexion | 4-5h | 23-26h | |
| | 2.3 Tests Stream | 3-4h | 26-30h | |
| **Phase 3: Robustesse** | | **8-10h** | **38-45h** | Semaine 2-3 |
| | 3.1 Validation | 3-4h | 29-34h | |
| | 3.2 Logging | 3-4h | 32-38h | |
| | 3.3 Erreurs Retry | 2-3h | 34-41h | |
| **Phase 4: Qualité** | | **10-14h** | **48-59h** | Semaine 3-4 |
| | 4.1 Unit Tests | 6-8h | 40-48h | |
| | 4.2 UI Tests | 2-3h | 42-51h | |
| | 4.3 Integration | 2-3h | 44-54h | |
| | 4.4 Code & Docs | 2h | 46-56h | |

**⚠️ Note:** Estimé 48-56 heures, ajuster selon complexité HaishinKit

---

## DÉPENDANCES & ORDRE

```
Phase 1.1: OAuth (6h)
    ↓
Phase 1.2: Refresh Token (4h)
    ↓
Phase 1.3: Error Handling (4-5h)
    ↓
Phase 2.1: HaishinKit Setup (5-6h)
    ↓
Phase 2.2: RTMP Connection (4-5h)
    ↓
Phase 2.3: Streaming Tests (3-4h)
    ↓
Phase 3.1: Input Validation (3-4h)
    ↓
Phase 3.2: Logging (3-4h)
    ↓
Phase 3.3: Retry Logic (2-3h)
    ↓
Phase 4.1: Unit Tests (6-8h)
    ↓
Phase 4.2: UI Tests (2-3h)
    ↓
Phase 4.3: Integration Tests (2-3h)
    ↓
Phase 4.4: Polish & Release (2h)
    ↓
✅ PRODUCTION READY
```

---

## RESSOURCES ADDITIONNELLES

### Liens Documentation
- **HaishinKit:** https://github.com/shogo4405/HaishinKit.swift
- **YouTube API:** https://developers.google.com/youtube/v3
- **RTMP Protocol:** https://en.wikipedia.org/wiki/Real-Time_Messaging_Protocol
- **ASWebAuthenticationSession:** https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession
- **OSLog:** https://developer.apple.com/documentation/os/logging

### Dépendances SPM à Ajouter
```swift
.package(url: "https://github.com/shogo4405/HaishinKit.swift.git", branch: "main")
```

### Files à Créer
```
LiveStage.xcodeproj/
├── AppError.swift (nouvelle)
├── AppLogger.swift (nouvelle)
├── ValidatorHelper.swift (nouvelle)
├── RetryHelper.swift (nouvelle)
└── Tests/
    ├── YouTubeAPIServiceTests.swift (nouvelle)
    ├── IntegrationTests.swift (nouvelle)
    └── LiveStageUITests.swift (nouvelle)
```

---

## CRITÈRES DE SUCCÈS

### Phase 1 ✅
- [x] Utilisateur peut se connecter avec Google
- [x] Tokens stockés en Keychain
- [x] Token se refresh automatiquement
- [x] Erreurs affichées clairement

### Phase 2 ✅
- [x] Streaming vers YouTube fonctionnel
- [x] H.264/AAC fonctionnant
- [x] Reconnexion automatique
- [x] Peut arrêter stream

### Phase 3 ✅
- [x] Aucune donnée invalide acceptée
- [x] Tous les événements loggés
- [x] Retry automatique des erreurs réseau

### Phase 4 ✅
- [x] 80%+ test coverage
- [x] Tous workflows testés
- [x] Pas de memory leaks
- [x] Documenté complètement

---

## RISQUES & MITIGATION

| Risque | Impact | Mitigation |
|--------|--------|-----------|
| HaishinKit complexe | 🔴 Bloque phase 2 | Commencer par simple (sans bitrate adaptatif), ajouter après |
| YouTube API rate limits | 🟡 Tests lents | Utiliser fixtures/mocks, pas appels API réels |
| RTMP instable | 🟡 Streams qui drop | Excellent logging, monitoring métriques |
| Memory leaks caméra | 🟡 Crash après 30min | Tester avec Instruments, cleanup complet |
| Tests fragiles | 🟡 CI/CD lent | Bien isoler, utiliser mocks fiables |

---

## PROCHAINES ÉTAPES

1. Choisir phase à commencer (recommandé: Phase 1 OAuth)
2. Créer branche feature: `git checkout -b feature/phase-1-oauth`
3. Commencer Sprint 1.1
4. Commiter après chaque sprint
5. Tester sur device réel
6. Merger via PR après chaque phase

Bon développement! 🚀
