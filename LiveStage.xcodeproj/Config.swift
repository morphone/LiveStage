//
//  Config.swift
//  LiveStage
//
//  Created by Michael Chartier on 2025-11-17.
//

import Foundation

/// Configuration globale de l'application
enum Config {
    
    // MARK: - YouTube API
    
    enum YouTube {
        /// URL de base pour l'API YouTube Data v3
        static let apiBaseURL = "https://www.googleapis.com/youtube/v3"
        
        /// URL d'authentification OAuth 2.0
        static let authURL = "https://accounts.google.com/o/oauth2/v2/auth"
        
        /// URL pour l'échange de tokens
        static let tokenURL = "https://oauth2.googleapis.com/token"
        
        /// Scopes nécessaires pour le streaming
        static let scopes = [
            "https://www.googleapis.com/auth/youtube",
            "https://www.googleapis.com/auth/youtube.force-ssl",
            "https://www.googleapis.com/auth/youtube.upload"
        ]
        
        /// Client ID (à configurer)
        /// ⚠️ Ne committez jamais cette valeur en production
        static var clientID: String {
            // Essayer de lire depuis les variables d'environnement
            if let envClientID = ProcessInfo.processInfo.environment["YOUTUBE_CLIENT_ID"] {
                return envClientID
            }
            
            // Sinon, utiliser une valeur par défaut (à remplacer)
            return "VOTRE_CLIENT_ID_ICI"
        }
        
        /// Client Secret (si applicable)
        static var clientSecret: String? {
            if let envSecret = ProcessInfo.processInfo.environment["YOUTUBE_CLIENT_SECRET"] {
                return envSecret
            }
            return nil
        }
        
        /// Redirect URI pour OAuth
        static var redirectURI: String {
            // Utiliser le Bundle ID de l'app
            if let bundleID = Bundle.main.bundleIdentifier {
                return "\(bundleID):/oauth2callback"
            }
            return "com.yourcompany.livestage:/oauth2callback"
        }
    }
    
    // MARK: - Streaming
    
    enum Streaming {
        /// Résolution vidéo par défaut
        enum VideoResolution {
            case sd480p
            case hd720p
            case hd1080p
            case uhd4k
            
            var width: Int {
                switch self {
                case .sd480p: return 854
                case .hd720p: return 1280
                case .hd1080p: return 1920
                case .uhd4k: return 3840
                }
            }
            
            var height: Int {
                switch self {
                case .sd480p: return 480
                case .hd720p: return 720
                case .hd1080p: return 1080
                case .uhd4k: return 2160
                }
            }
        }
        
        /// Résolution par défaut
        static let defaultResolution = VideoResolution.hd1080p
        
        /// Frame rate par défaut
        static let defaultFrameRate = 30
        
        /// Bitrate vidéo recommandé (en kbps)
        static func recommendedBitrate(for resolution: VideoResolution) -> Int {
            switch resolution {
            case .sd480p: return 1500
            case .hd720p: return 3000
            case .hd1080p: return 6000
            case .uhd4k: return 15000
            }
        }
        
        /// Bitrate audio (en kbps)
        static let audioBitrate = 128
        
        /// Sample rate audio
        static let audioSampleRate = 44100
    }
    
    // MARK: - App
    
    enum App {
        static let name = "LiveStage"
        static let version = "1.0.0"
        
        /// Délai avant la reconnexion automatique (en secondes)
        static let reconnectionDelay: TimeInterval = 3.0
        
        /// Nombre maximum de tentatives de reconnexion
        static let maxReconnectionAttempts = 5
    }
    
    // MARK: - Keychain
    
    enum Keychain {
        static let service = "com.yourcompany.livestage"
        static let accessTokenKey = "YouTubeAccessToken"
        static let refreshTokenKey = "YouTubeRefreshToken"
    }
}
