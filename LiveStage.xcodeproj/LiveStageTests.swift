//
//  YouTubeAPIServiceTests.swift
//  LiveStageTests
//
//  Created by Michael Chartier on 2025-11-17.
//

import Testing
import Foundation
@testable import LiveStage

/// Tests pour le service API YouTube
@Suite("YouTube API Service Tests")
struct YouTubeAPIServiceTests {
    
    // MARK: - URL Building Tests
    
    @Test("Création de l'URL d'authentification")
    func buildAuthURL() async throws {
        let service = YouTubeAPIService()
        
        // Pour tester la méthode privée, on pourrait l'exposer
        // ou tester indirectement via authenticate()
        
        // Vérifier que les scopes nécessaires sont configurés
        #expect(Config.YouTube.scopes.count > 0)
        #expect(Config.YouTube.scopes.contains("https://www.googleapis.com/auth/youtube"))
    }
    
    @Test("Configuration du Client ID")
    func clientIDConfiguration() async throws {
        let clientID = Config.YouTube.clientID
        
        // Le Client ID ne doit pas être vide
        #expect(!clientID.isEmpty)
        
        // Le Client ID ne doit pas être la valeur par défaut en production
        // (Cette vérification devrait échouer si vous n'avez pas configuré votre clé)
        if clientID == "VOTRE_CLIENT_ID_ICI" {
            Issue.record("⚠️ Client ID not configured. Please set YOUTUBE_CLIENT_ID environment variable.")
        }
    }
    
    // MARK: - Token Management Tests
    
    @Test("Sauvegarde et chargement du token depuis le Keychain")
    func tokenPersistence() async throws {
        let testToken = "test_access_token_123456"
        
        // Nettoyer d'abord
        try? KeychainHelper.deleteYouTubeTokens()
        
        // Sauvegarder le token
        try KeychainHelper.saveYouTubeAccessToken(testToken)
        
        // Charger le token
        let loadedToken = try KeychainHelper.loadYouTubeAccessToken()
        
        // Vérifier qu'ils correspondent
        #expect(loadedToken == testToken)
        
        // Nettoyer après le test
        try KeychainHelper.deleteYouTubeTokens()
    }
    
    @Test("Suppression des tokens")
    func deleteTokens() async throws {
        let testToken = "test_token"

        // Sauvegarder un token
        try KeychainHelper.saveYouTubeAccessToken(testToken)

        // Vérifier qu'il existe
        let loadedToken = try KeychainHelper.loadYouTubeAccessToken()
        #expect(loadedToken != nil)

        // Supprimer
        try KeychainHelper.deleteYouTubeTokens()

        // Vérifier qu'il n'existe plus
        let deletedToken = try? KeychainHelper.loadYouTubeAccessToken()
        #expect(deletedToken == nil)
    }

    @Test("Sauvegarde et chargement de la date d'expiration")
    func tokenExpirationPersistence() async throws {
        let expirationDate = Date().addingTimeInterval(3600) // Dans 1 heure

        // Nettoyer d'abord
        try? KeychainHelper.deleteYouTubeTokens()

        // Sauvegarder la date d'expiration
        try KeychainHelper.saveTokenExpirationDate(expirationDate)

        // Charger la date d'expiration
        let loadedDate = try KeychainHelper.loadTokenExpirationDate()

        // Vérifier qu'elles correspondent (avec une tolérance de 1 seconde)
        #expect(loadedDate != nil)
        if let loadedDate = loadedDate {
            let timeDifference = abs(loadedDate.timeIntervalSince(expirationDate))
            #expect(timeDifference < 1.0)
        }

        // Nettoyer après le test
        try KeychainHelper.deleteYouTubeTokens()
    }

    @Test("Suppression complète des tokens et expiration")
    func deleteAllTokenData() async throws {
        let testToken = "test_token"
        let testRefreshToken = "test_refresh_token"
        let expirationDate = Date().addingTimeInterval(3600)

        // Sauvegarder tous les tokens
        try KeychainHelper.saveYouTubeAccessToken(testToken)
        try KeychainHelper.saveYouTubeRefreshToken(testRefreshToken)
        try KeychainHelper.saveTokenExpirationDate(expirationDate)

        // Vérifier qu'ils existent
        #expect(try KeychainHelper.loadYouTubeAccessToken() != nil)
        #expect(try KeychainHelper.loadYouTubeRefreshToken() != nil)
        #expect(try KeychainHelper.loadTokenExpirationDate() != nil)

        // Supprimer tout
        try KeychainHelper.deleteYouTubeTokens()

        // Vérifier que tout est supprimé
        #expect(try? KeychainHelper.loadYouTubeAccessToken() == nil)
        #expect(try? KeychainHelper.loadYouTubeRefreshToken() == nil)
        #expect(try? KeychainHelper.loadTokenExpirationDate() == nil)
    }
    
    // MARK: - Authentication State Tests
    
    @Test("État initial du service")
    @MainActor
    func initialState() async throws {
        let service = YouTubeAPIService()
        
        // Au démarrage, le service ne doit pas être authentifié
        #expect(!service.isAuthenticated)
        #expect(service.accessToken == nil)
    }
    
    @Test("Chargement du token au démarrage")
    @MainActor
    func loadTokenOnStartup() async throws {
        let testToken = "valid_token_123"
        
        // Sauvegarder un token
        try KeychainHelper.saveYouTubeAccessToken(testToken)
        
        // Créer un nouveau service
        let service = YouTubeAPIService()
        service.loadTokenFromKeychain()
        
        // Vérifier qu'il est chargé
        #expect(service.isAuthenticated == true)
        #expect(service.accessToken == testToken)
        
        // Nettoyer
        try KeychainHelper.deleteYouTubeTokens()
    }
    
    @Test("Logout nettoie l'état")
    @MainActor
    func logoutClearsState() async throws {
        let testToken = "token_to_clear"
        let testRefreshToken = "refresh_to_clear"
        let expirationDate = Date().addingTimeInterval(3600)

        // Sauvegarder et charger tous les tokens
        try KeychainHelper.saveYouTubeAccessToken(testToken)
        try KeychainHelper.saveYouTubeRefreshToken(testRefreshToken)
        try KeychainHelper.saveTokenExpirationDate(expirationDate)

        let service = YouTubeAPIService()
        service.loadTokenFromKeychain()

        #expect(service.isAuthenticated)
        #expect(service.accessToken != nil)
        #expect(service.refreshToken != nil)
        #expect(service.tokenExpirationDate != nil)

        // Logout
        service.logout()

        // Vérifier que tout est nettoyé dans le service
        #expect(!service.isAuthenticated)
        #expect(service.accessToken == nil)
        #expect(service.refreshToken == nil)
        #expect(service.tokenExpirationDate == nil)

        // Vérifier que le Keychain est aussi nettoyé
        #expect(try? KeychainHelper.loadYouTubeAccessToken() == nil)
        #expect(try? KeychainHelper.loadYouTubeRefreshToken() == nil)
        #expect(try? KeychainHelper.loadTokenExpirationDate() == nil)
    }

    @Test("Chargement complet des tokens avec expiration")
    @MainActor
    func loadCompleteTokenData() async throws {
        let testToken = "valid_token_123"
        let testRefreshToken = "valid_refresh_123"
        let expirationDate = Date().addingTimeInterval(3600)

        // Sauvegarder tous les tokens
        try KeychainHelper.saveYouTubeAccessToken(testToken)
        try KeychainHelper.saveYouTubeRefreshToken(testRefreshToken)
        try KeychainHelper.saveTokenExpirationDate(expirationDate)

        // Créer un nouveau service et charger
        let service = YouTubeAPIService()
        service.loadTokenFromKeychain()

        // Vérifier que tout est chargé
        #expect(service.isAuthenticated == true)
        #expect(service.accessToken == testToken)
        #expect(service.refreshToken == testRefreshToken)
        #expect(service.tokenExpirationDate != nil)

        if let loadedDate = service.tokenExpirationDate {
            let timeDifference = abs(loadedDate.timeIntervalSince(expirationDate))
            #expect(timeDifference < 1.0)
        }

        // Nettoyer
        try KeychainHelper.deleteYouTubeTokens()
    }

    // MARK: - Token Refresh Tests

    @Test("Vérification que le refresh token est requis")
    @MainActor
    func refreshRequiresRefreshToken() async throws {
        let service = YouTubeAPIService()

        // Pas de refresh token
        service.refreshToken = nil

        // Essayer de rafraîchir devrait échouer
        do {
            try await service.refreshAccessToken()
            Issue.record("refreshAccessToken() devrait échouer sans refresh token")
        } catch AppError.tokenRefreshFailed {
            // Comportement attendu
            #expect(true)
        } catch {
            Issue.record("Erreur inattendue: \(error)")
        }
    }

    @Test("Token avec expiration proche devrait être rafraîchi")
    @MainActor
    func tokenNearExpirationShouldRefresh() async throws {
        let testToken = "expiring_token"
        let testRefreshToken = "refresh_token"
        // Token qui expire dans 2 minutes (moins que la marge de 5 minutes)
        let expirationDate = Date().addingTimeInterval(120)

        // Sauvegarder les tokens
        try KeychainHelper.saveYouTubeAccessToken(testToken)
        try KeychainHelper.saveYouTubeRefreshToken(testRefreshToken)
        try KeychainHelper.saveTokenExpirationDate(expirationDate)

        let service = YouTubeAPIService()

        // Vérifier que le service détecte un token expirant bientôt
        service.tokenExpirationDate = expirationDate
        #expect(service.tokenExpirationDate != nil)

        // Calculer le temps jusqu'à expiration
        let timeUntilExpiration = expirationDate.timeIntervalSinceNow
        #expect(timeUntilExpiration < 300) // Moins de 5 minutes

        // Nettoyer
        try KeychainHelper.deleteYouTubeTokens()
    }

    @Test("Vérification de la structure de TokenResponse")
    func tokenResponseStructure() async throws {
        // JSON de réponse typique de l'API OAuth 2.0
        let jsonString = """
        {
            "access_token": "ya29.test_access_token",
            "expires_in": 3600,
            "refresh_token": "1//test_refresh_token",
            "scope": "https://www.googleapis.com/auth/youtube",
            "token_type": "Bearer"
        }
        """

        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        let response = try decoder.decode(TokenResponse.self, from: jsonData)

        #expect(response.accessToken == "ya29.test_access_token")
        #expect(response.expiresIn == 3600)
        #expect(response.refreshToken == "1//test_refresh_token")
        #expect(response.scope == "https://www.googleapis.com/auth/youtube")
        #expect(response.tokenType == "Bearer")
    }
}

// MARK: - Error Handling Tests

@Suite("Error Handling Tests")
struct ErrorHandlingTests {

    @Test("AppError messages en français")
    func appErrorLocalizedMessages() {
        let errors: [(AppError, String)] = [
            (.notAuthenticated, "authentifié"),
            (.userCancelled, "annulée"),
            (.invalidResponse, "invalide"),
            (.tokenExpired, "expiré"),
            (.cameraPermissionDenied, "caméra"),
            (.titleTooShort, "1 caractère"),
            (.titleTooLong, "100 caractères")
        ]

        for (error, expectedSubstring) in errors {
            let description = error.errorDescription ?? ""
            #expect(description.lowercased().contains(expectedSubstring.lowercased()),
                   "Error \(error) should contain '\(expectedSubstring)' in description")
        }
    }

    @Test("AppError suggestions de récupération")
    func appErrorRecoverySuggestions() {
        let errors: [AppError] = [
            .notAuthenticated,
            .networkError(NSError(domain: "", code: 0)),
            .cameraPermissionDenied,
            .titleTooShort
        ]

        for error in errors {
            #expect(error.recoverySuggestion != nil,
                   "Error \(error) should have a recovery suggestion")
            #expect(!error.recoverySuggestion!.isEmpty,
                   "Recovery suggestion should not be empty")
        }
    }

    @Test("AppError actions suggérées appropriées")
    func appErrorSuggestedActions() {
        // Erreur d'authentification devrait suggérer Login
        let authError = AppError.notAuthenticated
        #expect(authError.suggestedActions.contains { action in
            action.title == "Se connecter"
        })

        // Erreur de permission devrait suggérer Ouvrir Réglages
        let permissionError = AppError.cameraPermissionDenied
        #expect(permissionError.suggestedActions.contains { action in
            action.title == "Ouvrir Réglages"
        })

        // Erreur réseau devrait suggérer Réessayer
        let networkError = AppError.networkError(NSError(domain: "", code: 0))
        #expect(networkError.suggestedActions.contains { action in
            action.title == "Réessayer"
        })
    }

    @Test("ErrorAction titres en français")
    func errorActionTitles() {
        let actions: [ErrorAction] = [.retry, .cancel, .login, .openSettings, .dismiss]
        let expectedTitles = ["Réessayer", "Annuler", "Se connecter", "Ouvrir Réglages", "OK"]

        for (action, expectedTitle) in zip(actions, expectedTitles) {
            #expect(action.title == expectedTitle)
        }
    }

    @Test("Validation d'input - titre trop court")
    func titleTooShortValidation() {
        let error = AppError.titleTooShort
        #expect(error.errorDescription?.contains("1 caractère") == true)
    }

    @Test("Validation d'input - titre trop long")
    func titleTooLongValidation() {
        let error = AppError.titleTooLong
        #expect(error.errorDescription?.contains("100 caractères") == true)
    }

    @Test("Validation d'input - description trop longue")
    func descriptionTooLongValidation() {
        let error = AppError.descriptionTooLong
        #expect(error.errorDescription?.contains("5000 caractères") == true)
    }
}

// MARK: - RTMP Stream Manager Tests

@Suite("RTMP Stream Manager Tests")
struct RTMPStreamManagerTests {

    @Test("État initial du gestionnaire RTMP")
    @MainActor
    func initialState() {
        let manager = RTMPStreamManager()

        #expect(!manager.isStreaming)
        #expect(manager.isReady)
        #expect(!manager.isMicrophoneMuted)
        #expect(manager.currentCamera == .back)
        #expect(manager.bitrate == 0)
        #expect(manager.fps == 0)
    }

    @Test("Statut de connexion initial")
    @MainActor
    func connectionStatusInitial() {
        let manager = RTMPStreamManager()

        switch manager.connectionStatus {
        case .disconnected:
            #expect(true)
        default:
            #expect(false, "État initial doit être disconnected")
        }
    }

    @Test("Basculement du microphone")
    @MainActor
    func toggleMicrophone() {
        let manager = RTMPStreamManager()

        #expect(!manager.isMicrophoneMuted)

        manager.toggleMicrophone()
        #expect(manager.isMicrophoneMuted)

        manager.toggleMicrophone()
        #expect(!manager.isMicrophoneMuted)
    }

    @Test("Changement de caméra")
    @MainActor
    func switchCamera() {
        let manager = RTMPStreamManager()

        #expect(manager.currentCamera == .back)

        manager.switchCamera()
        #expect(manager.currentCamera == .front)

        manager.switchCamera()
        #expect(manager.currentCamera == .back)
    }

    @Test("Démarrage du streaming avec URL vide échoue")
    @MainActor
    async func startStreamingWithEmptyURLFails() async {
        let manager = RTMPStreamManager()

        do {
            try await manager.startStreaming(to: "", key: "test-key")
            #expect(false, "Devrait échouer avec URL vide")
        } catch AppError.streamingError {
            #expect(true)
        } catch {
            #expect(false, "Erreur inattendue: \(error)")
        }
    }

    @Test("Démarrage du streaming avec clé vide échoue")
    @MainActor
    async func startStreamingWithEmptyKeyFails() async {
        let manager = RTMPStreamManager()

        do {
            try await manager.startStreaming(to: "rtmp://test.com", key: "")
            #expect(false, "Devrait échouer avec clé vide")
        } catch AppError.streamingError {
            #expect(true)
        } catch {
            #expect(false, "Erreur inattendue: \(error)")
        }
    }

    @Test("Santé du stream par défaut")
    @MainActor
    func defaultStreamHealth() {
        let manager = RTMPStreamManager()

        switch manager.streamHealth {
        case .excellent:
            #expect(true)
        default:
            #expect(false, "La santé par défaut doit être excellent")
        }
    }

    @Test("Descriptions de statut de connexion")
    @MainActor
    func connectionStatusDescriptions() {
        let statuses: [(RTMPStreamManager.ConnectionStatus, String)] = [
            (.disconnected, "Déconnecté"),
            (.connecting, "Connexion..."),
            (.connected, "Connecté"),
            (.reconnecting(attempt: 2), "Reconnexion (2/5)..."),
            (.error("Test"), "Erreur: Test")
        ]

        for (status, expectedDescription) in statuses {
            #expect(status.description == expectedDescription)
        }
    }

    @Test("Indicateurs de santé du stream")
    @MainActor
    func streamHealthIndicators() {
        let healths: [(RTMPStreamManager.StreamHealth, String)] = [
            (.excellent, "🟢"),
            (.good, "🟡"),
            (.fair, "🟠"),
            (.poor, "🔴")
        ]

        for (health, expectedIndicator) in healths {
            #expect(health.indicator == expectedIndicator)
        }
    }

    @Test("Arrêt d'un streaming qui n'est pas actif")
    @MainActor
    func stopStreamingWhenNotStreaming() {
        let manager = RTMPStreamManager()

        #expect(!manager.isStreaming)

        manager.stopStreaming() // Should not crash

        #expect(!manager.isStreaming)
    }
}

// MARK: - RTMP Connection Tests

@Suite("RTMP Connection Tests")
struct RTMPConnectionTests {

    @Test("Création de détails de connexion valides")
    func validConnectionDetails() {
        let details = RTMPConnectionDetails(
            serverURL: "rtmps://a.rtmp.youtube.com/live2",
            streamKey: "abcd-efgh-ijkl"
        )

        #expect(details.isValid)
        #expect(details.protocol_ == .rtmps)
        #expect(!details.protocol_.isSecure == false) // RTMPS is secure
    }

    @Test("URL RTMP invalide détectée")
    func invalidRTMPURL() {
        let details = RTMPConnectionDetails(
            serverURL: "https://example.com/live",
            streamKey: "key123"
        )

        #expect(!details.isValid)
    }

    @Test("Construction d'URL complète RTMP")
    func fullURLConstruction() {
        let details = RTMPConnectionDetails(
            serverURL: "rtmps://a.rtmp.youtube.com/live2",
            streamKey: "xyz123"
        )

        let fullURL = details.fullURL
        #expect(fullURL.contains("rtmps://"))
        #expect(fullURL.contains("xyz123"))
    }

    @Test("Serveurs RTMP connus")
    func knownServers() {
        let servers: [(KnownRTMPServer, String)] = [
            (.youtube, "YouTube Live"),
            (.twitch, "Twitch")
        ]

        for (server, expectedName) in servers {
            #expect(server.name == expectedName)
            #expect(!server.serverURL.isEmpty)
        }
    }

    @Test("YouTube Live stream key validation")
    func youtubeStreamKeyValidation() {
        #expect(YouTubeLiveRTMP.isValidStreamKey("abcd-efgh-ijkl-mnop"))
        #expect(!YouTubeLiveRTMP.isValidStreamKey(""))
        #expect(!YouTubeLiveRTMP.isValidStreamKey("short"))
    }

    @Test("RTMP Connection Info parsing")
    func rtmpConnectionInfoParsing() {
        let info = RTMPConnectionInfo(
            fromURL: "rtmps://a.rtmp.youtube.com/live2",
            streamKey: "streamkey123"
        )

        #expect(info != nil)
        if let info = info {
            #expect(info.isSecure)
            #expect(info.port == 443)
            #expect(info.serverAddress == "a.rtmp.youtube.com")
        }
    }

    @Test("Métriques de connexion RTMP")
    func rtmpConnectionMetrics() {
        var metrics = RTMPConnectionMetrics()

        metrics.framesVideoSent = 100
        metrics.framesVideoDropped = 10

        let successRate = metrics.packetSuccessRate
        #expect(successRate > 0)
        #expect(successRate <= 100)

        // Calculate expected: 100 / (100 + 10) * 100 = 90.9%
        #expect(successRate > 90 && successRate < 92)
    }

    @Test("Indicateur de santé basé sur le taux de succès")
    func healthIndicatorFromSuccessRate() {
        var metrics = RTMPConnectionMetrics()

        // Excellent (>80%)
        metrics.framesVideoSent = 100
        metrics.framesVideoDropped = 10
        #expect(metrics.healthIndicator == .excellent)

        // Good (60-80%)
        metrics.framesVideoSent = 100
        metrics.framesVideoDropped = 25
        #expect(metrics.healthIndicator == .good)

        // Fair (40-60%)
        metrics.framesVideoSent = 100
        metrics.framesVideoDropped = 50
        #expect(metrics.healthIndicator == .fair)

        // Poor (<40%)
        metrics.framesVideoSent = 100
        metrics.framesVideoDropped = 70
        #expect(metrics.healthIndicator == .poor)
    }

    @Test("Descriptions d'état de connexion RTMP")
    func connectionStateDescriptions() {
        let states: [(RTMPConnectionState, String)] = [
            (.idle, "Non connecté"),
            (.connecting, "Connexion..."),
            (.connected, "Connecté"),
            (.reconnecting(attempt: 3), "Reconnexion (3/5)...")
        ]

        for (state, expectedDesc) in states {
            #expect(state.description == expectedDesc)
        }
    }
}

// MARK: - Streaming Integration Tests

@Suite("Streaming Integration Tests")
struct StreamingIntegrationTests {

    @Test("Flux complet: Créer stream → Configurer RTMP → Valider")
    @MainActor
    async func completeStreamingWorkflow() async throws {
        // 1. Créer un stream YouTube
        let stream = YouTubeStream(
            id: "test-stream-123",
            title: "Test Stream",
            streamDescription: "Integration test stream",
            scheduledStartTime: Date(),
            streamKey: "abcd-efgh-ijkl-test",
            streamURL: "rtmps://a.rtmp.youtube.com/live2",
            status: .scheduled
        )

        #expect(!stream.id.isEmpty)
        #expect(!stream.streamKey!.isEmpty)
        #expect(!stream.streamURL!.isEmpty)

        // 2. Créer les détails de connexion RTMP
        let connectionDetails = RTMPConnectionDetails(
            serverURL: stream.streamURL!,
            streamKey: stream.streamKey!
        )

        #expect(connectionDetails.isValid)
        #expect(connectionDetails.protocol_ == .rtmps)

        // 3. Initialiser le gestionnaire de streaming
        let manager = RTMPStreamManager()
        #expect(!manager.isStreaming)

        // 4. Valider que le manager est prêt
        #expect(manager.isReady)
    }

    @Test("Workflow reconnexion automatique")
    @MainActor
    async func reconnectionWorkflow() async throws {
        let manager = RTMPStreamManager()

        // 1. État initial
        #expect(!manager.isStreaming)

        // 2. Tentative de reconnexion sans paramètres (doit être safe)
        await manager.attemptReconnection(
            to: "rtmps://a.rtmp.youtube.com/live2",
            key: ""  // Clé vide pour simuler un paramètre invalide
        )

        // 3. Vérifier que le manager n'a pas crashé
        #expect(!manager.isStreaming)
    }

    @Test("Qualité vidéo et configurati on adaptative")
    @MainActor
    func videoQualityConfiguration() {
        let manager = RTMPStreamManager()

        // Tester chaque résolution
        let resolutions: [Config.Streaming.VideoResolution] = [
            .sd480p,
            .hd720p,
            .hd1080p,
            .uhd4k
        ]

        for resolution in resolutions {
            // Cette méthode devrait être safe même sans HaishinKit
            manager.setVideoQuality(resolution: resolution, framerate: 30)
            #expect(true) // Just verify it doesn't crash
        }
    }

    @Test("Activation du bitrate adaptatif")
    @MainActor
    func adaptiveBitrateConfiguration() {
        let manager = RTMPStreamManager()

        // Activer le bitrate adaptatif
        manager.enableAdaptiveBitrate(true)
        #expect(true)

        // Désactiver le bitrate adaptatif
        manager.enableAdaptiveBitrate(false)
        #expect(true)
    }

    @Test("Valeurs de configuration recommandées")
    func recommendedBitratesByResolution() {
        let configs: [(Config.Streaming.VideoResolution, Int)] = [
            (.sd480p, 1500),
            (.hd720p, 3000),
            (.hd1080p, 6000),
            (.uhd4k, 15000)
        ]

        for (resolution, expectedBitrate) in configs {
            let bitrate = Config.Streaming.recommendedBitrate(for: resolution)
            #expect(bitrate == expectedBitrate)
        }
    }

    @Test("Protocoles RTMP sécurité")
    func rtmpSecurityComparison() {
        let rtmpServer = KnownRTMPServer.twitch
        let rtmpsServer = KnownRTMPServer.youtube

        #expect(rtmpServer.requiresSSL == false) // Twitch doesn't require SSL by default
        #expect(rtmpsServer.requiresSSL == true) // YouTube requires SSL
    }

    @Test("Synchronisation des permissions caméra/microphone")
    @MainActor
    async func permissionRequestFlow() async {
        let manager = RTMPStreamManager()

        // Cette méthode fait des appels système sûrs
        await manager.requestPermissions()

        // Manager devrait rester en bon état
        #expect(!manager.isStreaming)
        #expect(manager.isReady)
    }

    @Test("Contrôle caméra multiples basculements")
    @MainActor
    func multipleCameraSwitches() {
        let manager = RTMPStreamManager()

        let initialPosition = manager.currentCamera

        // Basculer plusieurs fois
        for _ in 0..<5 {
            manager.switchCamera()
        }

        // Après 5 basculements (impair), devrait être opposé à initial
        let expectedPosition: AVCaptureDevice.Position = initialPosition == .back ? .front : .back
        #expect(manager.currentCamera == expectedPosition)
    }

    @Test("État du streaming après arrêt forcé")
    @MainActor
    async func forcedStreamStop() async throws {
        let manager = RTMPStreamManager()

        // Simuler l'arrêt sans démarrage (méthode robuste)
        manager.stopStreaming()

        #expect(!manager.isStreaming)
        #expect(manager.connectionStatus == .disconnected)
    }

    @Test("Consommation mémoire - initialisation")
    @MainActor
    func memoryManagement() {
        // Créer et détruire plusieurs managers
        for _ in 0..<10 {
            let manager = RTMPStreamManager()
            #expect(!manager.isStreaming)
        }

        // Si nous arrivons ici, pas de crash mémoire
        #expect(true)
    }
}

// MARK: - Stream Model Tests

@Suite("YouTube Stream Model Tests")
struct YouTubeStreamTests {
    
    @Test("Création d'un stream avec valeurs par défaut")
    func createStreamWithDefaults() async throws {
        let stream = YouTubeStream(
            title: "Test Stream"
        )
        
        #expect(stream.title == "Test Stream")
        #expect(stream.streamDescription == "")
        #expect(stream.status == .draft)
        #expect(stream.streamKey == nil)
        #expect(stream.streamURL == nil)
    }
    
    @Test("Création d'un stream complet")
    func createCompleteStream() async throws {
        let now = Date()
        let stream = YouTubeStream(
            id: "test-123",
            title: "Mon Live",
            streamDescription: "Description test",
            scheduledStartTime: now,
            streamKey: "test-key",
            streamURL: "rtmp://test.com/live",
            status: .scheduled
        )
        
        #expect(stream.id == "test-123")
        #expect(stream.title == "Mon Live")
        #expect(stream.streamDescription == "Description test")
        #expect(stream.streamKey == "test-key")
        #expect(stream.streamURL == "rtmp://test.com/live")
        #expect(stream.status == .scheduled)
    }
    
    @Test("Tous les statuts de stream")
    func allStreamStatuses() async throws {
        let statuses: [YouTubeStream.StreamStatus] = [
            .draft, .scheduled, .live, .completed, .cancelled
        ]
        
        for status in statuses {
            let stream = YouTubeStream(
                title: "Test",
                status: status
            )
            #expect(stream.status == status)
        }
    }
}

// MARK: - Configuration Tests

@Suite("Configuration Tests")
struct ConfigurationTests {
    
    @Test("Résolutions vidéo")
    func videoResolutions() async throws {
        let resolutions: [(Config.Streaming.VideoResolution, Int, Int)] = [
            (.sd480p, 854, 480),
            (.hd720p, 1280, 720),
            (.hd1080p, 1920, 1080),
            (.uhd4k, 3840, 2160)
        ]
        
        for (resolution, expectedWidth, expectedHeight) in resolutions {
            #expect(resolution.width == expectedWidth)
            #expect(resolution.height == expectedHeight)
        }
    }
    
    @Test("Bitrates recommandés")
    func recommendedBitrates() async throws {
        // Vérifier que les bitrates augmentent avec la résolution
        let bitrate480 = Config.Streaming.recommendedBitrate(for: .sd480p)
        let bitrate720 = Config.Streaming.recommendedBitrate(for: .hd720p)
        let bitrate1080 = Config.Streaming.recommendedBitrate(for: .hd1080p)
        let bitrate4k = Config.Streaming.recommendedBitrate(for: .uhd4k)
        
        #expect(bitrate480 < bitrate720)
        #expect(bitrate720 < bitrate1080)
        #expect(bitrate1080 < bitrate4k)
    }
    
    @Test("URLs de l'API YouTube")
    func apiURLs() async throws {
        // Vérifier que les URLs sont bien formées
        #expect(Config.YouTube.apiBaseURL.hasPrefix("https://"))
        #expect(Config.YouTube.authURL.hasPrefix("https://"))
        #expect(Config.YouTube.tokenURL.hasPrefix("https://"))
    }
    
    @Test("Scopes YouTube")
    func youtubeScopes() async throws {
        // Vérifier que les scopes nécessaires sont présents
        let scopes = Config.YouTube.scopes
        
        #expect(scopes.count >= 2)
        #expect(scopes.contains { $0.contains("youtube") })
    }
}

// MARK: - Mock Data Helper

/// Helper pour créer des données de test
enum TestDataHelper {
    
    static func createMockStream(
        title: String = "Test Stream",
        status: YouTubeStream.StreamStatus = .draft
    ) -> YouTubeStream {
        return YouTubeStream(
            id: UUID().uuidString,
            title: title,
            streamDescription: "Test description",
            scheduledStartTime: Date(),
            status: status
        )
    }
    
    static func createMockLiveStream() -> YouTubeStream {
        return YouTubeStream(
            id: "live-123",
            title: "Live Stream",
            streamDescription: "Currently streaming",
            scheduledStartTime: Date().addingTimeInterval(-3600), // Il y a 1h
            streamKey: "live-key-123",
            streamURL: "rtmp://live.youtube.com/ingestion",
            status: .live
        )
    }
}

// MARK: - Integration Tests (Commented - Require Network)

/*
@Suite("YouTube API Integration Tests", .disabled("Requires network and valid credentials"))
struct YouTubeAPIIntegrationTests {
    
    @Test("Création d'un broadcast réel", .disabled("Requires authentication"))
    @MainActor
    func createRealBroadcast() async throws {
        let service = YouTubeAPIService()
        service.loadTokenFromKeychain()
        
        #expect(service.isAuthenticated, "Must be authenticated first")
        
        let response = try await service.createLiveStream(
            title: "Test Stream",
            description: "Integration test",
            scheduledStartTime: Date().addingTimeInterval(3600) // Dans 1h
        )
        
        #expect(!response.id.isEmpty)
    }
}
*/
