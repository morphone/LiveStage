//
//  RTMPConnection.swift
//  LiveStage
//
//  Created by Claude AI on 2025-11-18.
//  Structures et helpers pour les connexions RTMP
//

import Foundation

// MARK: - RTMP Protocol

/// Types de protocoles RTMP supportés
enum RTMPProtocol: String {
    case rtmp = "rtmp"
    case rtmps = "rtmps"
    case rtmpt = "rtmpt"

    var isSecure: Bool {
        return self == .rtmps
    }

    var defaultPort: Int {
        switch self {
        case .rtmp, .rtmpt:
            return 1935
        case .rtmps:
            return 443
        }
    }
}

// MARK: - Connection Details

/// Détails de connexion RTMP complets
struct RTMPConnectionDetails {
    let serverURL: String
    let streamKey: String

    /// Vérifie si les détails de connexion sont valides
    var isValid: Bool {
        return !serverURL.isEmpty &&
               !streamKey.isEmpty &&
               (serverURL.hasPrefix("rtmp://") || serverURL.hasPrefix("rtmps://"))
    }

    /// Détermine le protocole utilisé
    var protocol_: RTMPProtocol {
        if serverURL.hasPrefix("rtmps://") {
            return .rtmps
        } else if serverURL.hasPrefix("rtmpt://") {
            return .rtmpt
        } else {
            return .rtmp
        }
    }

    /// Construit l'URL complète pour la connexion
    var fullURL: String {
        let cleanURL = serverURL.hasSuffix("/") ? serverURL : "\(serverURL)/"
        return "\(cleanURL)\(streamKey)"
    }
}

// MARK: - Connection Info

/// Informations détaillées d'une connexion RTMP
struct RTMPConnectionInfo {
    let serverAddress: String
    let port: Int
    let application: String
    let streamKey: String
    let isSecure: Bool

    init?(fromURL url: String, streamKey: String) {
        // Parser l'URL RTMP
        guard let components = URLComponents(string: url) else {
            return nil
        }

        guard let host = components.host else {
            return nil
        }

        self.serverAddress = host
        self.streamKey = streamKey
        self.isSecure = url.hasPrefix("rtmps://")
        self.port = components.port ?? (isSecure ? 443 : 1935)

        // Extraire l'application (généralement le premier segment du path)
        let path = components.path
        let pathComponents = path.components(separatedBy: "/").filter { !$0.isEmpty }
        self.application = pathComponents.first ?? "live"
    }
}

// MARK: - Connection State

/// États possibles d'une connexion RTMP
enum RTMPConnectionState: Equatable {
    case idle
    case connecting
    case connected
    case reconnecting(attempt: Int)
    case disconnected
    case error(String)

    var description: String {
        switch self {
        case .idle:
            return "Non connecté"
        case .connecting:
            return "Connexion..."
        case .connected:
            return "Connecté"
        case .reconnecting(let attempt):
            return "Reconnexion (\(attempt)/5)..."
        case .disconnected:
            return "Déconnecté"
        case .error(let message):
            return "Erreur: \(message)"
        }
    }

    static func == (lhs: RTMPConnectionState, rhs: RTMPConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.connecting, .connecting),
             (.connected, .connected),
             (.disconnected, .disconnected):
            return true
        case (.reconnecting(let a), .reconnecting(let b)):
            return a == b
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Connection Metrics

/// Métriques de connexion RTMP en temps réel
struct RTMPConnectionMetrics {
    var framesVideoSent: Int = 0
    var framesVideoDropped: Int = 0
    var framesAudioSent: Int = 0
    var framesAudioDropped: Int = 0
    var bytesSent: Int64 = 0
    var averageUploadSpeed: Double = 0.0 // Mbps
    var connectionUptime: TimeInterval = 0.0

    /// Taux de réussite des packets vidéo (en pourcentage)
    var packetSuccessRate: Double {
        let total = framesVideoSent + framesVideoDropped
        guard total > 0 else { return 100.0 }
        return Double(framesVideoSent) / Double(total) * 100.0
    }

    /// Indicateur de santé basé sur le taux de réussite
    var healthIndicator: RTMPStreamManager.StreamHealth {
        let rate = packetSuccessRate
        if rate > 80 {
            return .excellent
        } else if rate > 60 {
            return .good
        } else if rate > 40 {
            return .fair
        } else {
            return .poor
        }
    }

    /// Reset toutes les métriques
    mutating func reset() {
        framesVideoSent = 0
        framesVideoDropped = 0
        framesAudioSent = 0
        framesAudioDropped = 0
        bytesSent = 0
        averageUploadSpeed = 0.0
        connectionUptime = 0.0
    }
}

// MARK: - Known RTMP Servers

/// Serveurs RTMP connus et leurs configurations
enum KnownRTMPServer {
    case youtube
    case twitch
    case facebook
    case custom(name: String, url: String)

    var name: String {
        switch self {
        case .youtube:
            return "YouTube Live"
        case .twitch:
            return "Twitch"
        case .facebook:
            return "Facebook Live"
        case .custom(let name, _):
            return name
        }
    }

    var serverURL: String {
        switch self {
        case .youtube:
            return "rtmps://a.rtmp.youtube.com/live2"
        case .twitch:
            return "rtmp://live.twitch.tv/app"
        case .facebook:
            return "rtmps://live-api-s.facebook.com:443/rtmp"
        case .custom(_, let url):
            return url
        }
    }

    var requiresSSL: Bool {
        switch self {
        case .youtube, .facebook:
            return true
        case .twitch:
            return false
        case .custom(_, let url):
            return url.hasPrefix("rtmps://")
        }
    }

    var ingestEndpoints: [String] {
        switch self {
        case .youtube:
            return [
                "rtmps://a.rtmp.youtube.com/live2",
                "rtmps://b.rtmp.youtube.com/live2",
                "rtmps://c.rtmp.youtube.com/live2",
                "rtmps://d.rtmp.youtube.com/live2"
            ]
        case .twitch:
            return [
                "rtmp://live.twitch.tv/app",
                "rtmp://live-prg.twitch.tv/app",
                "rtmp://live-fra.twitch.tv/app"
            ]
        case .facebook:
            return ["rtmps://live-api-s.facebook.com:443/rtmp"]
        case .custom:
            return [serverURL]
        }
    }
}

// MARK: - YouTube Live RTMP Helper

/// Helper spécifique pour YouTube Live RTMP
enum YouTubeLiveRTMP {

    /// Valide un stream key YouTube
    /// Format typique: xxxx-xxxx-xxxx-xxxx (16 caractères avec tirets)
    static func isValidStreamKey(_ key: String) -> Bool {
        guard !key.isEmpty else { return false }

        // YouTube stream keys sont typiquement 16+ caractères
        if key.count < 10 {
            return false
        }

        // Vérifier qu'il contient uniquement des caractères alphanumériques et tirets
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        return key.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
    }

    /// Serveurs d'ingestion YouTube par région
    static let ingestServers = [
        "primary": "rtmps://a.rtmp.youtube.com/live2",
        "backup1": "rtmps://b.rtmp.youtube.com/live2",
        "backup2": "rtmps://c.rtmp.youtube.com/live2",
        "backup3": "rtmps://d.rtmp.youtube.com/live2"
    ]

    /// Paramètres recommandés pour YouTube Live
    static let recommendedSettings = [
        "maxBitrate": 6000,
        "minBitrate": 1500,
        "keyframeInterval": 2,
        "audioCodec": "AAC",
        "videoCodec": "H.264"
    ]
}

// MARK: - RTMP URL Builder

/// Constructeur d'URL RTMP sécurisé
struct RTMPURLBuilder {
    private let baseURL: String
    private let streamKey: String
    private let useSSL: Bool

    init(baseURL: String, streamKey: String, useSSL: Bool = true) {
        self.baseURL = baseURL
        self.streamKey = streamKey
        self.useSSL = useSSL
    }

    /// Construit l'URL complète en filtrant les données sensibles des logs
    func build() -> String {
        var url = baseURL

        // S'assurer que l'URL a le bon protocole
        if useSSL && url.hasPrefix("rtmp://") {
            url = url.replacingOccurrences(of: "rtmp://", with: "rtmps://")
        }

        // Ajouter le stream key
        let separator = url.hasSuffix("/") ? "" : "/"
        return "\(url)\(separator)\(streamKey)"
    }

    /// URL pour les logs (sans le stream key)
    var safeURLForLogging: String {
        var url = baseURL
        if useSSL && url.hasPrefix("rtmp://") {
            url = url.replacingOccurrences(of: "rtmp://", with: "rtmps://")
        }
        return "\(url)/***"
    }
}
