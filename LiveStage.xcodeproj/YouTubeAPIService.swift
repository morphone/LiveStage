//
//  YouTubeAPIService.swift
//  LiveStage
//
//  Created by Michael Chartier on 2025-11-17.
//

import Foundation
import AuthenticationServices

/// Service pour interagir avec l'API YouTube Data v3
@MainActor
class YouTubeAPIService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var accessToken: String?
    @Published var refreshToken: String?
    @Published var tokenExpirationDate: Date?

    // Timer pour le rafraîchissement automatique du token
    private var refreshTimer: Timer?

    // Marge de sécurité avant expiration (5 minutes)
    private let tokenRefreshMargin: TimeInterval = 300 // 5 minutes en secondes
    
    // MARK: - Authentification

    /// Démarre le processus d'authentification OAuth 2.0
    func authenticate() async throws {
        AppLogger.logUserAction("Démarrage de l'authentification OAuth")
        let authURL = buildAuthURL()

        // Créer une continuation pour gérer l'authentification asynchrone
        return try await withCheckedThrowingContinuation { continuation in
            // Créer la session d'authentification web
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "com.livestage"
            ) { callbackURL, error in
                // Gestion des erreurs
                if let error = error {
                    // Vérifier si l'utilisateur a annulé
                    if case ASWebAuthenticationSessionError.canceledLogin = error {
                        AppLogger.logAuthenticationFailure(reason: "Utilisateur a annulé")
                        continuation.resume(throwing: AppError.userCancelled)
                    } else {
                        AppLogger.logAuthenticationFailure(reason: error.localizedDescription)
                        continuation.resume(throwing: AppError.authenticationFailed(error))
                    }
                    return
                }

                // Extraire le code d'autorisation de l'URL de callback
                guard let url = callbackURL,
                      let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                      let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: AppError.invalidCallback)
                    return
                }

                // Échanger le code contre un token
                Task {
                    do {
                        try await self.exchangeCodeForToken(code: code)
                        AppLogger.logAuthenticationSuccess()
                        continuation.resume()
                    } catch {
                        AppLogger.logAuthenticationFailure(reason: error.localizedDescription)
                        continuation.resume(throwing: error)
                    }
                }
            }

            // Permettre l'authentification via une fenêtre éphémère
            session.prefersEphemeralWebBrowserSession = false

            // Démarrer la session
            session.start()
        }
    }
    
    private func buildAuthURL() -> URL {
        var components = URLComponents(string: Config.YouTube.authURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Config.YouTube.clientID),
            URLQueryItem(name: "redirect_uri", value: Config.YouTube.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: Config.YouTube.scopes.joined(separator: " ")),
            URLQueryItem(name: "access_type", value: "offline")
        ]
        return components.url!
    }
    
    /// Échange le code d'autorisation contre un access token
    func exchangeCodeForToken(code: String) async throws {
        let tokenURL = URL(string: Config.YouTube.tokenURL)!

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var parameters: [String: String] = [
            "code": code,
            "client_id": Config.YouTube.clientID,
            "redirect_uri": Config.YouTube.redirectURI,
            "grant_type": "authorization_code"
        ]

        if let clientSecret = Config.YouTube.clientSecret {
            parameters["client_secret"] = clientSecret
        }

        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        // Vérifier la réponse HTTP
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppError.invalidResponse
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        // Calculer la date d'expiration (expires_in est en secondes)
        let expirationDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))

        self.accessToken = tokenResponse.accessToken
        self.refreshToken = tokenResponse.refreshToken
        self.tokenExpirationDate = expirationDate
        self.isAuthenticated = true

        // Sauvegarder les tokens de manière sécurisée dans le Keychain
        try? KeychainHelper.saveYouTubeAccessToken(tokenResponse.accessToken)
        if let refreshToken = tokenResponse.refreshToken {
            try? KeychainHelper.saveYouTubeRefreshToken(refreshToken)
        }
        // Sauvegarder la date d'expiration
        try? KeychainHelper.saveTokenExpirationDate(expirationDate)

        // Programmer le rafraîchissement automatique du token
        scheduleTokenRefresh()
    }
    
    // MARK: - Création de flux en direct
    
    /// Crée un nouveau flux de diffusion YouTube
    func createLiveStream(title: String, description: String, scheduledStartTime: Date) async throws -> LiveStreamResponse {
        guard let token = accessToken else {
            throw AppError.notAuthenticated
        }
        
        let url = URL(string: "https://www.googleapis.com/youtube/v3/liveBroadcasts?part=snippet,contentDetails,status")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "snippet": [
                "title": title,
                "description": description,
                "scheduledStartTime": ISO8601DateFormatter().string(from: scheduledStartTime)
            ],
            "status": [
                "privacyStatus": "public",
                "selfDeclaredMadeForKids": false
            ],
            "contentDetails": [
                "enableAutoStart": true,
                "enableAutoStop": true
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.invalidResponse
        }
        
        return try JSONDecoder().decode(LiveStreamResponse.self, from: data)
    }
    
    /// Crée un stream (flux vidéo technique)
    func createStream(title: String) async throws -> StreamResponse {
        guard let token = accessToken else {
            throw AppError.notAuthenticated
        }
        
        let url = URL(string: "https://www.googleapis.com/youtube/v3/liveStreams?part=snippet,cdn,contentDetails,status")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "snippet": [
                "title": title
            ],
            "cdn": [
                "frameRate": "variable",
                "ingestionType": "rtmp",
                "resolution": "variable"
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.invalidResponse
        }
        
        return try JSONDecoder().decode(StreamResponse.self, from: data)
    }
    
    /// Lie un broadcast à un stream
    func bindBroadcastToStream(broadcastId: String, streamId: String) async throws {
        guard let token = accessToken else {
            throw AppError.notAuthenticated
        }
        
        let url = URL(string: "https://www.googleapis.com/youtube/v3/liveBroadcasts/bind?id=\(broadcastId)&streamId=\(streamId)&part=id,contentDetails")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.invalidResponse
        }
    }
    
    // MARK: - Helpers
    
    func loadTokenFromKeychain() {
        if let token = try? KeychainHelper.loadYouTubeAccessToken() {
            self.accessToken = token
            self.isAuthenticated = true
        }

        if let refreshToken = try? KeychainHelper.loadYouTubeRefreshToken() {
            self.refreshToken = refreshToken
        }

        if let expirationDate = try? KeychainHelper.loadTokenExpirationDate() {
            self.tokenExpirationDate = expirationDate
        }

        // Programmer le rafraîchissement automatique si on a les tokens
        if isAuthenticated {
            scheduleTokenRefresh()
        }
    }

    func logout() {
        // Annuler le timer de refresh
        refreshTimer?.invalidate()
        refreshTimer = nil

        try? KeychainHelper.deleteYouTubeTokens()
        self.accessToken = nil
        self.refreshToken = nil
        self.tokenExpirationDate = nil
        self.isAuthenticated = false
    }

    // MARK: - Token Refresh

    /// Programme le rafraîchissement automatique du token
    private func scheduleTokenRefresh() {
        // Annuler le timer existant
        refreshTimer?.invalidate()

        guard let expirationDate = tokenExpirationDate else {
            return
        }

        // Calculer le délai avant le refresh (5 minutes avant expiration)
        let refreshDate = expirationDate.addingTimeInterval(-tokenRefreshMargin)
        let timeUntilRefresh = refreshDate.timeIntervalSinceNow

        // Si le token expire dans moins de 5 minutes, rafraîchir immédiatement
        if timeUntilRefresh <= 0 {
            Task {
                try? await refreshAccessToken()
            }
            return
        }

        // Programmer le refresh
        refreshTimer = Timer.scheduledTimer(withTimeInterval: timeUntilRefresh, repeats: false) { [weak self] _ in
            Task { @MainActor in
                try? await self?.refreshAccessToken()
            }
        }
    }

    /// Rafraîchit l'access token en utilisant le refresh token
    func refreshAccessToken() async throws {
        guard let currentRefreshToken = refreshToken else {
            AppLogger.logTokenRefresh(success: false)
            throw AppError.tokenRefreshFailed
        }

        AppLogger.auth.info("🔄 Début du rafraîchissement du token")
        let tokenURL = URL(string: Config.YouTube.tokenURL)!

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var parameters: [String: String] = [
            "refresh_token": currentRefreshToken,
            "client_id": Config.YouTube.clientID,
            "grant_type": "refresh_token"
        ]

        if let clientSecret = Config.YouTube.clientSecret {
            parameters["client_secret"] = clientSecret
        }

        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        // Vérifier la réponse HTTP
        guard let httpResponse = response as? HTTPURLResponse else {
            AppLogger.logTokenRefresh(success: false)
            throw AppError.invalidResponse
        }

        // Gérer le cas où le refresh token est invalide
        if httpResponse.statusCode == 400 {
            // Le refresh token est probablement expiré ou révoqué
            AppLogger.auth.error("❌ Refresh token invalide - Déconnexion forcée")
            // Forcer l'utilisateur à se reconnecter
            await MainActor.run {
                self.logout()
            }
            throw AppError.tokenRefreshFailed
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            AppLogger.logTokenRefresh(success: false)
            throw AppError.invalidResponse
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        // Calculer la nouvelle date d'expiration
        let expirationDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))

        self.accessToken = tokenResponse.accessToken
        // Le refresh token peut être le même ou un nouveau
        if let newRefreshToken = tokenResponse.refreshToken {
            self.refreshToken = newRefreshToken
        }
        self.tokenExpirationDate = expirationDate

        // Sauvegarder les nouveaux tokens dans le Keychain
        try? KeychainHelper.saveYouTubeAccessToken(tokenResponse.accessToken)
        if let newRefreshToken = tokenResponse.refreshToken {
            try? KeychainHelper.saveYouTubeRefreshToken(newRefreshToken)
        }
        try? KeychainHelper.saveTokenExpirationDate(expirationDate)

        AppLogger.logTokenRefresh(success: true)

        // Re-programmer le prochain refresh
        scheduleTokenRefresh()
    }
}

// MARK: - Models

struct TokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
    let refreshToken: String?
    let scope: String
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
        case tokenType = "token_type"
    }
}

struct LiveStreamResponse: Codable {
    let id: String
    let snippet: Snippet
    
    struct Snippet: Codable {
        let title: String
        let description: String
        let scheduledStartTime: String
    }
}

struct StreamResponse: Codable {
    let id: String
    let cdn: CDN
    
    struct CDN: Codable {
        let ingestionInfo: IngestionInfo
        
        struct IngestionInfo: Codable {
            let streamName: String
            let ingestionAddress: String
        }
    }
}