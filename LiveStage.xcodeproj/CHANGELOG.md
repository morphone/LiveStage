# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/lang/fr/).

## [Non publié]

### À venir dans v1.0.0

- Streaming RTMP fonctionnel avec HaishinKit
- Authentification OAuth 2.0 complète avec ASWebAuthenticationSession
- Statistiques en temps réel (viewers, durée)
- Support complet iPad
- Tests sur TestFlight

---

## [0.1.0] - 2025-11-17

### ✨ Ajouté

#### Interface Utilisateur
- **ContentView** : Vue principale avec TabView (Streams + Réglages)
- **StreamListView** : Liste de tous les streams avec badges de statut
- **CreateStreamView** : Formulaire complet de création de stream
- **StreamDetailView** : Vue détaillée avec aperçu caméra et contrôles
- **CameraPreviewView** : Wrapper UIKit pour AVCaptureVideoPreviewLayer
- **StatusBadge** : Component réutilisable pour afficher le statut
- **LiveIndicator** : Indicateur animé "EN DIRECT"

#### Modèles de Données
- **YouTubeStream** : Modèle SwiftData complet
  - Propriétés : id, title, description, scheduledStartTime, streamKey, streamURL, status, createdAt
  - Enum StreamStatus : draft, scheduled, live, completed, cancelled
- Intégration avec SwiftData dans LiveStageApp

#### Services
- **YouTubeAPIService** : Service complet pour l'API YouTube
  - Méthodes d'authentification OAuth 2.0
  - Création de broadcasts YouTube
  - Création de streams techniques
  - Liaison broadcast-stream
  - Gestion des tokens (avec Keychain)
  - Structures : TokenResponse, LiveStreamResponse, StreamResponse
  - Erreurs personnalisées : YouTubeAPIError

- **CameraManager** : Gestionnaire de caméra et audio
  - Configuration AVCaptureSession
  - Gestion des permissions (caméra, microphone)
  - Changement de caméra (avant/arrière)
  - Contrôle du microphone (mute/unmute)
  - Interface pour le streaming (stub)
  - Délégués AVCaptureVideoDataOutput et AVCaptureAudioDataOutput

- **RTMPStreamManager** : Template pour streaming RTMP
  - Code complet pour HaishinKit (commenté)
  - Configuration vidéo H.264
  - Configuration audio AAC
  - Gestion de la connexion RTMP
  - Monitoring du bitrate
  - Documentation sur implémentation personnalisée
  - Exemples d'utilisation

- **KeychainHelper** : Stockage sécurisé
  - Sauvegarde dans Keychain iOS
  - Chargement depuis Keychain
  - Suppression d'entrées
  - Extensions pour YouTube tokens
  - Gestion d'erreurs (KeychainError)

- **Config** : Configuration centralisée
  - Config.YouTube : API URLs, Client ID, scopes
  - Config.Streaming : Résolutions, bitrates, framerate
  - Config.App : Version, reconnexion
  - Config.Keychain : Clés de stockage
  - Support variables d'environnement

#### Tests
- **LiveStageTests** : Suite de tests avec Swift Testing
  - YouTubeAPIServiceTests (8 tests)
  - YouTubeStreamTests (3 tests)
  - ConfigurationTests (4 tests)
  - TestDataHelper pour mock data
  - Total : 15 tests unitaires

#### Documentation
- **README.md** : Documentation principale complète (350 lignes)
- **INSTALLATION.md** : Guide d'installation détaillé (450 lignes)
- **QUICKSTART.md** : Guide de démarrage rapide (250 lignes)
- **PROJECT_SUMMARY.md** : Résumé exécutif du projet (600 lignes)
- **FILE_STRUCTURE.md** : Structure détaillée des fichiers (500 lignes)
- **TODO.md** : Liste complète des tâches futures (400 lignes)
- **CHANGELOG.md** : Ce fichier

#### Configuration
- **.gitignore** : Protection des données sensibles
  - Fichiers Xcode standards
  - Config.swift.local, APIKeys.plist
  - Variables d'environnement
  - Fichiers de build
  
- **Info.plist.example** : Template de configuration
  - Permissions caméra et microphone
  - URL schemes pour OAuth
  - Background modes

### 🔧 Modifié

- **LiveStageApp.swift** : Ajout de YouTubeStream au schema SwiftData
- **ContentView.swift** : Remplacement de la NavigationSplitView par TabView

### 🎯 Caractéristiques Actuelles

#### ✅ Fonctionnel
- Interface utilisateur complète et moderne
- SwiftData pour persistance locale
- Gestion de la caméra et aperçu
- Permissions iOS (caméra, microphone)
- Sécurité Keychain
- Configuration centralisée
- Tests unitaires de base

#### 🚧 En Développement / Stub
- Authentification OAuth 2.0 (URL générée, échange manuel)
- Streaming RTMP (interface présente, encodage à implémenter)
- API YouTube (appels préparés, nécessite config)

#### ❌ Non Implémenté
- ASWebAuthenticationSession pour OAuth complet
- Encodage vidéo H.264 / Audio AAC
- Connexion RTMP au serveur
- Statistiques en temps réel
- Chat en direct
- Miniatures personnalisées

### 📊 Statistiques

- **Fichiers créés** : 17
- **Fichiers modifiés** : 2
- **Lignes de code** : ~2,500
- **Lignes de documentation** : ~2,000
- **Tests unitaires** : 15
- **Couverture estimée** : 40%

### 🔐 Sécurité

- ✅ Stockage Keychain pour tokens OAuth
- ✅ .gitignore pour clés API
- ✅ Support variables d'environnement
- ✅ Pas de clés hardcodées
- ✅ Configuration externalisée

### 🛠️ Technologies

- Swift 5.9+
- SwiftUI
- SwiftData
- AVFoundation
- Security (Keychain)
- Swift Testing (tests)
- iOS 17.0+ (minimum)

### 📱 Compatibilité

- ✅ iPhone (iOS 17.0+)
- 🚧 iPad (UI de base fonctionne, optimisations à venir)
- ✅ Portrait et paysage
- ✅ Dark Mode support
- ✅ Dynamic Type support

### 🎨 Design

- Interface moderne avec SwiftUI
- SF Symbols pour icônes
- Animations fluides
- ContentUnavailableView pour états vides
- Indicateurs de statut colorés
- Boutons accessibles

### 📖 Documentation

- README complet avec exemples
- Guide d'installation pas à pas
- Quick Start pour démarrage rapide
- Résumé exécutif du projet
- Structure complète documentée
- TODO organisé par priorité
- Commentaires dans le code

### 🐛 Bugs Connus

- CameraPreviewView peut ne pas se redimensionner correctement à la rotation
- YouTubeAPIService n'a pas de gestion de refresh token automatique
- Pas de reconnexion automatique en cas d'erreur réseau

### ⚠️ Limitations

- Streaming RTMP nécessite HaishinKit (non inclus)
- OAuth nécessite configuration manuelle
- Tests uniquement sur iPhone physique pour la caméra
- Pas de support watchOS ou visionOS

### 🎓 Notes de Version

Cette première version pose les **fondations complètes** pour une application de streaming YouTube professionnelle. L'architecture est propre, modulaire et testable. Le code est documenté et sécurisé.

**Points forts** :
- ✨ Interface utilisateur complète et polie
- 🏗️ Architecture solide et extensible
- 📚 Documentation exhaustive
- 🔒 Sécurité prise en compte dès le début
- 🧪 Tests unitaires en place

**Prochaines priorités** :
1. Implémenter l'authentification OAuth complète
2. Ajouter le support HaishinKit pour streaming RTMP
3. Tester sur appareils physiques
4. Publier sur TestFlight

### 👥 Contributeurs

- Michael Chartier - Développeur initial

### 📄 License

[À définir]

---

## Format des Versions Futures

### [Version] - YYYY-MM-DD

#### Ajouté
- Nouvelles fonctionnalités

#### Modifié
- Changements dans les fonctionnalités existantes

#### Déprécié
- Fonctionnalités bientôt supprimées

#### Supprimé
- Fonctionnalités supprimées

#### Corrigé
- Corrections de bugs

#### Sécurité
- En cas de vulnérabilités

---

## Liens Utiles

- [Projet sur GitHub](à_définir)
- [Documentation](à_définir)
- [Issues](à_définir)
- [Releases](à_définir)

---

**Note** : Ce projet suit les principes du développement agile. Les versions sont publiées régulièrement avec des améliorations incrémentales.
