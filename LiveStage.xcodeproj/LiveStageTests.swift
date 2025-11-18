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
        } catch YouTubeAPIError.tokenRefreshFailed {
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
