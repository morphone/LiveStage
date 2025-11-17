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
    
    // MARK: - Authentification
    
    /// Démarre le processus d'authentification OAuth 2.0
    func authenticate() async throws {
        let authURL = buildAuthURL()
        
        // Utiliser ASWebAuthenticationSession pour l'authentification
        // Note: L'implémentation complète nécessite un callback handler
        print("URL d'authentification: \(authURL)")
        
        // TODO: Implémenter ASWebAuthenticationSession
        // Cette partie nécessite une configuration du callback dans Info.plist
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
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        self.accessToken = response.accessToken
        self.refreshToken = response.refreshToken
        self.isAuthenticated = true
        
        // Sauvegarder les tokens de manière sécurisée dans le Keychain
        try? KeychainHelper.saveYouTubeAccessToken(response.accessToken)
        if let refreshToken = response.refreshToken {
            try? KeychainHelper.saveYouTubeRefreshToken(refreshToken)
        }
    }
    
    // MARK: - Création de flux en direct
    
    /// Crée un nouveau flux de diffusion YouTube
    func createLiveStream(title: String, description: String, scheduledStartTime: Date) async throws -> LiveStreamResponse {
        guard let token = accessToken else {
            throw YouTubeAPIError.notAuthenticated
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
            throw YouTubeAPIError.invalidResponse
        }
        
        return try JSONDecoder().decode(LiveStreamResponse.self, from: data)
    }
    
    /// Crée un stream (flux vidéo technique)
    func createStream(title: String) async throws -> StreamResponse {
        guard let token = accessToken else {
            throw YouTubeAPIError.notAuthenticated
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
            throw YouTubeAPIError.invalidResponse
        }
        
        return try JSONDecoder().decode(StreamResponse.self, from: data)
    }
    
    /// Lie un broadcast à un stream
    func bindBroadcastToStream(broadcastId: String, streamId: String) async throws {
        guard let token = accessToken else {
            throw YouTubeAPIError.notAuthenticated
        }
        
        let url = URL(string: "https://www.googleapis.com/youtube/v3/liveBroadcasts/bind?id=\(broadcastId)&streamId=\(streamId)&part=id,contentDetails")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw YouTubeAPIError.invalidResponse
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
    }
    
    func logout() {
        try? KeychainHelper.deleteYouTubeTokens()
        self.accessToken = nil
        self.refreshToken = nil
        self.isAuthenticated = false
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

enum YouTubeAPIError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Non authentifié. Veuillez vous connecter à YouTube."
        case .invalidResponse:
            return "Réponse invalide du serveur YouTube."
        case .networkError:
            return "Erreur réseau lors de la communication avec YouTube."
        }
    }
}
