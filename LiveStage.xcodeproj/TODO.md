# 📋 TODO - LiveStage

## 🎯 Prochaines Étapes

### 🔴 Priorité Haute (Critique)

- [ ] **Configuration API YouTube**
  - [ ] Créer projet Google Cloud
  - [ ] Activer YouTube Data API v3
  - [ ] Créer identifiants OAuth 2.0
  - [ ] Configurer Client ID dans Config.swift
  - [ ] Tester l'authentification

- [ ] **Permissions iOS**
  - [ ] Copier Info.plist.example vers Info.plist
  - [ ] Ajouter NSCameraUsageDescription
  - [ ] Ajouter NSMicrophoneUsageDescription
  - [ ] Configurer CFBundleURLTypes

- [ ] **Test sur Appareil**
  - [ ] Tester l'aperçu caméra
  - [ ] Vérifier les permissions
  - [ ] Tester le changement de caméra
  - [ ] Tester le mute/unmute micro

### 🟠 Priorité Moyenne (Important)

- [ ] **Streaming RTMP**
  - [ ] Ajouter HaishinKit via SPM
  - [ ] Décommenter RTMPStreamManager.swift
  - [ ] Intégrer dans StreamDetailView
  - [ ] Tester le streaming sur YouTube
  - [ ] Gérer les erreurs de connexion
  - [ ] Implémenter la reconnexion automatique

- [ ] **Authentification OAuth Complète**
  - [ ] Implémenter ASWebAuthenticationSession
  - [ ] Gérer le callback URL
  - [ ] Extraire le code d'autorisation
  - [ ] Implémenter le refresh token automatique
  - [ ] Gérer l'expiration du token
  - [ ] Ajouter un indicateur de chargement

- [ ] **Gestion d'Erreurs**
  - [ ] Ajouter des alertes pour les erreurs réseau
  - [ ] Gérer les erreurs API YouTube (quotas, etc.)
  - [ ] Ajouter des retry strategies
  - [ ] Logger les erreurs pour debug
  - [ ] Afficher des messages utilisateur clairs

### 🟡 Priorité Basse (Nice to Have)

- [ ] **Statistiques en Temps Réel**
  - [ ] Afficher le nombre de viewers
  - [ ] Afficher les likes/dislikes
  - [ ] Monitorer le bitrate actuel
  - [ ] Afficher la durée du stream
  - [ ] Graphiques de performance

- [ ] **Chat en Direct**
  - [ ] Intégrer YouTube Live Chat API
  - [ ] Afficher les messages en temps réel
  - [ ] Modération des messages
  - [ ] Répondre aux messages depuis l'app

- [ ] **Fonctionnalités Avancées**
  - [ ] Miniatures personnalisées
  - [ ] Filtres et effets vidéo
  - [ ] Overlays texte
  - [ ] Mode paysage optimisé
  - [ ] Support multi-caméra (si l'appareil supporte)
  - [ ] Enregistrement local pendant le streaming

- [ ] **UI/UX Améliorations**
  - [ ] Thème sombre/clair
  - [ ] Animations supplémentaires
  - [ ] Haptic feedback
  - [ ] Accessibilité VoiceOver
  - [ ] Support Dynamic Type
  - [ ] Widgets pour les prochains streams

- [ ] **Support iPad**
  - [ ] Interface adaptée pour iPad
  - [ ] Split View support
  - [ ] Drag & Drop
  - [ ] Keyboard shortcuts

---

## 🐛 Bugs Connus & À Corriger

- [ ] **CameraPreviewView**
  - [ ] Le preview layer ne se redimensionne pas toujours correctement
  - [ ] Rotation de l'appareil à gérer

- [ ] **YouTubeAPIService**
  - [ ] Pas de gestion de l'expiration du token
  - [ ] Pas de retry sur les erreurs réseau temporaires

- [ ] **StreamDetailView**
  - [ ] Le bouton "Démarrer" ne désactive pas vraiment si pas de streamURL

---

## ✅ Tâches Techniques

### Code Quality

- [ ] **Tests**
  - [ ] Augmenter la couverture de tests (objectif 80%)
  - [ ] Ajouter tests UI avec Swift Testing
  - [ ] Tests d'intégration pour l'API
  - [ ] Tests de performance

- [ ] **Documentation**
  - [ ] Ajouter des docstrings à toutes les méthodes publiques
  - [ ] Générer la documentation avec DocC
  - [ ] Ajouter des diagrammes de flux
  - [ ] Créer des tutoriels vidéo

- [ ] **Refactoring**
  - [ ] Extraire la logique de networking dans un service séparé
  - [ ] Créer des ViewModels pour les vues complexes
  - [ ] Utiliser des protocols pour l'injection de dépendances
  - [ ] Optimiser les performances de la caméra

### Sécurité

- [ ] **Hardening**
  - [ ] Valider toutes les entrées utilisateur
  - [ ] Sanitizer les URLs
  - [ ] Ajouter du rate limiting
  - [ ] Implémenter certificate pinning
  - [ ] Obfuscation du code sensible

- [ ] **Privacy**
  - [ ] Ajouter une politique de confidentialité
  - [ ] Clarifier l'utilisation des données
  - [ ] Permettre l'export des données utilisateur
  - [ ] Ajouter l'option de suppression de compte

### Performance

- [ ] **Optimisations**
  - [ ] Profiler avec Instruments
  - [ ] Optimiser l'utilisation mémoire
  - [ ] Réduire la consommation batterie
  - [ ] Optimiser la taille de l'app
  - [ ] Lazy loading des images

---

## 🚀 Roadmap Future

### Version 1.0 (MVP)
**Date cible** : 2 semaines

- [x] Interface de base
- [x] Connexion YouTube
- [ ] Streaming RTMP fonctionnel
- [ ] Tests sur TestFlight
- [ ] App Store submission

### Version 1.1
**Date cible** : 1 mois

- [ ] Statistiques en temps réel
- [ ] Chat en direct
- [ ] Notifications push
- [ ] Support iPad

### Version 1.2
**Date cible** : 2 mois

- [ ] Filtres vidéo
- [ ] Enregistrement local
- [ ] Miniatures personnalisées
- [ ] Planification avancée

### Version 2.0
**Date cible** : 3-6 mois

- [ ] Streaming multi-plateforme (Twitch, Facebook)
- [ ] Mode multi-caméra
- [ ] Studio virtuel
- [ ] Intégrations tierces (OBS, etc.)

---

## 📝 Notes de Développement

### Décisions à Prendre

- [ ] **Architecture RTMP**
  - Option A : HaishinKit (simple, bien maintenu)
  - Option B : Implémentation personnalisée (contrôle total)
  - Option C : Service cloud (VideoStream.io, etc.)

- [ ] **Monétisation**
  - [ ] Gratuit avec publicités ?
  - [ ] Freemium (fonctionnalités premium) ?
  - [ ] Abonnement mensuel ?
  - [ ] Achat unique ?

- [ ] **Backend**
  - [ ] Besoin d'un backend pour analytics ?
  - [ ] Stockage cloud pour les enregistrements ?
  - [ ] API propre pour les intégrations ?

### Questions à Résoudre

- [ ] Comment gérer les streams très longs (>4h) ?
- [ ] Que faire en cas de changement de réseau (WiFi → 4G) ?
- [ ] Comment optimiser pour la batterie ?
- [ ] Support des formats vidéo alternatifs ?

---

## 🎨 Design Tasks

- [ ] **Assets**
  - [ ] Créer l'icône de l'app
  - [ ] Design des écrans de lancement
  - [ ] Images pour l'App Store
  - [ ] Screenshots pour les différentes tailles

- [ ] **Branding**
  - [ ] Logo LiveStage
  - [ ] Palette de couleurs
  - [ ] Typography guidelines
  - [ ] Style guide complet

---

## 📱 Compatibilité

### Tester sur :

- [ ] iPhone SE (2ème/3ème gen) - Petit écran
- [ ] iPhone 14/15 - Standard
- [ ] iPhone 14/15 Pro Max - Grand écran
- [ ] iPad Air - Tablette
- [ ] iPad Pro - Grande tablette

### iOS Versions :

- [ ] iOS 17.0 (minimum requis)
- [ ] iOS 17.4 (actuel)
- [ ] iOS 18 beta (prochaine version)

---

## 🌐 Internationalisation

- [ ] **Langues à Supporter**
  - [x] Français (actuel)
  - [ ] Anglais
  - [ ] Espagnol
  - [ ] Allemand
  - [ ] Japonais

- [ ] **Tâches i18n**
  - [ ] Extraire tous les strings
  - [ ] Créer les fichiers .strings
  - [ ] Traduire l'interface
  - [ ] Traduire la documentation
  - [ ] Tester les formats de date/heure

---

## 📊 Analytics & Monitoring

- [ ] **Implémenter**
  - [ ] Analytics (Firebase, Mixpanel, ou custom)
  - [ ] Crash reporting (Crashlytics)
  - [ ] Performance monitoring
  - [ ] User feedback système

- [ ] **Métriques à Suivre**
  - [ ] Nombre de streams créés
  - [ ] Durée moyenne des streams
  - [ ] Taux de réussite du streaming
  - [ ] Erreurs fréquentes
  - [ ] Rétention utilisateur

---

## 🎓 Formation & Documentation

- [ ] **Créer**
  - [ ] Guide utilisateur en français
  - [ ] Guide utilisateur en anglais
  - [ ] Tutoriels vidéo
  - [ ] FAQ
  - [ ] Blog posts techniques

- [ ] **Developer Docs**
  - [ ] Architecture decision records (ADR)
  - [ ] API documentation
  - [ ] Contribution guidelines
  - [ ] Code of conduct

---

## 🔧 DevOps

- [ ] **CI/CD**
  - [ ] Setup Xcode Cloud / GitHub Actions
  - [ ] Tests automatiques
  - [ ] Build automatique
  - [ ] Déploiement TestFlight automatique

- [ ] **Monitoring Production**
  - [ ] Alertes pour crashes
  - [ ] Monitoring du backend (si applicable)
  - [ ] Status page

---

## 📋 Checklist Avant Release

### Code

- [ ] Tous les TODO dans le code sont résolus
- [ ] Pas de warnings Xcode
- [ ] Pas de console logs en production
- [ ] Code review complet
- [ ] Tests passent à 100%

### Sécurité

- [ ] Pas de clés API hardcodées
- [ ] Validation de toutes les entrées
- [ ] HTTPS partout
- [ ] Tokens dans Keychain
- [ ] Obfuscation activée

### Performance

- [ ] App < 50 MB
- [ ] Temps de lancement < 2s
- [ ] Pas de memory leaks
- [ ] Batterie optimisée
- [ ] Réseau optimisé

### Design

- [ ] Supporte Dark Mode
- [ ] Supporte Dynamic Type
- [ ] Accessible (VoiceOver)
- [ ] Toutes les tailles d'écran
- [ ] Toutes les orientations

### Documentation

- [ ] README à jour
- [ ] CHANGELOG créé
- [ ] License ajoutée
- [ ] Privacy policy
- [ ] Terms of service

### App Store

- [ ] Icône finalisée
- [ ] Screenshots créés
- [ ] Description App Store
- [ ] Keywords optimisés
- [ ] Age rating correct
- [ ] Metadata localisés

---

## 💭 Idées pour Plus Tard

- [ ] Mode hors ligne pour éditer les paramètres
- [ ] Templates de diffusion
- [ ] Planification récurrente (hebdomadaire, etc.)
- [ ] Collaboration (co-streaming)
- [ ] Overlay personnalisés avancés
- [ ] Green screen / chroma key
- [ ] Audio mixing avancé
- [ ] Support pour hardware externe (microphones, caméras)
- [ ] API publique pour développeurs tiers
- [ ] Plugins système

---

## 📞 Contacts & Resources

### Support Technique

- Google Cloud Console : https://console.cloud.google.com
- YouTube API : https://developers.google.com/youtube
- HaishinKit : https://github.com/shogo4405/HaishinKit.swift
- Apple Developer : https://developer.apple.com

### Communauté

- Stack Overflow : [swift] [youtube-api]
- Reddit : r/iOSProgramming
- Discord : [Créer un serveur pour les utilisateurs ?]

---

**Dernière mise à jour** : 17 novembre 2025

**Maintenu par** : Michael Chartier

---

## 🎯 Focus Cette Semaine

1. ⭐ **Configurer l'API YouTube** (2h)
2. ⭐ **Tester sur appareil réel** (1h)
3. ⭐ **Ajouter HaishinKit** (3h)
4. ⭐ **Premier stream de test** (1h)

**Objectif** : Avoir un stream YouTube fonctionnel d'ici vendredi ! 🚀
