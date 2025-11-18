//
//  RTMPConnection.swift
//  LiveStage
//
//  Created by Claude AI on 2025-11-18.
//  Gestion des détails de connexion RTMP

import Foundation

/// Détails d'une connexion RTMP
struct RTMPConnectionDetails {

    // MARK: - Properties

    /// URL du serveur RTMP (ex: rtmps://a.rtmp.youtube.com/live2)
    let serverURL: String

    /// Clé de stream / Stream key
    let streamKey: String

    /// URL complète (serverURL + streamKey)
    var fullURL: String {
        let url = serverURL.hasSuffix("/") ? serverURL : serverURL + "/"
        return url + streamKey
    }

    /// Timeout de connexion (secondes)
    var connectionTimeout: TimeInterval = 10

    /// Timeout de données (secondes)
    var dataTimeout: TimeInterval = 30

    /// Nombre maximum de tentatives de reconnexion
    var maxReconnectionAttempts: Int = 5

    /// Délai initial de reconnexion (secondes)
    var initialReconnectionDelay: TimeInterval = 1

    // MARK: - Validation

    /// Vérifie que les paramètres sont valides
    var isValid: Bool {
        !serverURL.isEmpty && !streamKey.isEmpty && isValidURL
    }

    /// Vérifie que l'URL RTMP est valide
    private var isValidURL: Bool {
        let isRTMP = serverURL.lowercased().hasPrefix("rtmp://")
        let isRTMPS = serverURL.lowercased().hasPrefix("rtmps://")
        return isRTMP || isRTMPS
    }

    /// Type de protocole utilisé
    var protocol_: RTMPProtocol {
        if serverURL.lowercased().hasPrefix("rtmps://") {
            return .rtmps
        }
        return .rtmp
    }

    // MARK: - Initialization

    init(serverURL: String, streamKey: String) {
        self.serverURL = serverURL
        self.streamKey = streamKey
    }
}

// MARK: - RTMP Protocol

enum RTMPProtocol: String {
    case rtmp  = "rtmp"
    case rtmps = "rtmps"

    var description: String {
        switch self {
        case .rtmp:
            return "RTMP (non-sécurisé)"
        case .rtmps:
            return "RTMPS (sécurisé, chiffré)"
        }
    }

    var isSecure: Bool {
        self == .rtmps
    }
}

// MARK: - Known RTMP Servers

enum KnownRTMPServer {

    case youtube
    case facebook
    case twitch
    case custom(String)

    var serverURL: String {
        switch self {
        case .youtube:
            return "rtmps://a.rtmp.youtube.com/live2"
        case .facebook:
            return "rtmps://live-api-s.facebook.com:443/rtmp"
        case .twitch:
            return "rtmp://live-lhr.twitch.tv/live"
        case .custom(let url):
            return url
        }
    }

    var name: String {
        switch self {
        case .youtube:
            return "YouTube Live"
        case .facebook:
            return "Facebook Live"
        case .twitch:
            return "Twitch"
        case .custom:
            return "Custom RTMP Server"
        }
    }

    var requiresSSL: Bool {
        switch self {
        case .youtube, .facebook:
            return true
        case .twitch:
            return false
        case .custom(let url):
            return url.lowercased().hasPrefix("rtmps://")
        }
    }
}

// MARK: - YouTube Live Specific

struct YouTubeLiveRTMP {

    /// URL de base YouTube Live
    static let serverURL = "rtmps://a.rtmp.youtube.com/live2"

    /// Obtient l'URL complète pour YouTube Live
    static func url(withStreamKey streamKey: String) -> String {
        return serverURL + "/" + streamKey
    }

    /// Valide qu'une clé de stream YouTube est au bon format
    static func isValidStreamKey(_ key: String) -> Bool {
        // YouTube stream keys sont généralement longues et alphanumériques
        return !key.isEmpty && key.count > 10 && key.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" })
    }
}

// MARK: - RTMP Connection Info

struct RTMPConnectionInfo {

    /// Adresse du serveur (sans protocole)
    let serverAddress: String

    /// Port (1935 par défaut pour RTMP, 443 pour RTMPS)
    let port: Int

    /// Est-ce une connexion sécurisée (RTMPS)
    let isSecure: Bool

    /// Chemin dans le serveur RTMP
    let applicationPath: String

    /// Clé de stream
    let streamKey: String

    // MARK: - Initialization from URL

    /// Parse une URL RTMP pour extraire les informations
    init?(fromURL url: String, streamKey: String) {
        guard let urlComponents = URLComponents(string: url) else {
            return nil
        }

        guard let scheme = urlComponents.scheme?.lowercased() else {
            return nil
        }

        let isSecure = scheme == "rtmps"

        guard let host = urlComponents.host else {
            return nil
        }

        let port = urlComponents.port ?? (isSecure ? 443 : 1935)
        let path = urlComponents.path

        self.serverAddress = host
        self.port = port
        self.isSecure = isSecure
        self.applicationPath = path
        self.streamKey = streamKey
    }

    /// Reconstruit l'URL complète
    func buildFullURL() -> String {
        let scheme = isSecure ? "rtmps" : "rtmp"
        let portStr = (isSecure && port == 443) || (!isSecure && port == 1935) ? "" : ":\(port)"
        return "\(scheme)://\(serverAddress)\(portStr)\(applicationPath)/\(streamKey)"
    }
}

// MARK: - Connection Metrics

struct RTMPConnectionMetrics {

    /// Nombre d'octets envoyés
    var bytesSent: UInt64 = 0

    /// Nombre de frames vidéo envoyées
    var framesVideoSent: UInt64 = 0

    /// Nombre de frames vidéo droppées
    var framesVideoDropped: UInt64 = 0

    /// Nombre de samples audio envoyés
    var audioSamplesSent: UInt64 = 0

    /// Latence de la connexion (en ms)
    var latency: UInt32 = 0

    /// Framerate actuel
    var currentFPS: Float = 0

    /// Bitrate actuel (en bits par seconde)
    var currentBitrate: UInt32 = 0

    /// Taux de succès des packets
    var packetSuccessRate: Float {
        guard framesVideoSent > 0 else { return 100 }
        let sent = Float(framesVideoSent)
        let dropped = Float(framesVideoDropped)
        return (sent / (sent + dropped)) * 100
    }

    /// Santé basée sur le taux de succès des packets
    var healthIndicator: RTMPStreamManager.StreamHealth {
        let rate = packetSuccessRate
        switch rate {
        case 80...:
            return .excellent
        case 60..<80:
            return .good
        case 40..<60:
            return .fair
        default:
            return .poor
        }
    }
}

// MARK: - Connection State

enum RTMPConnectionState {

    /// Pas connecté
    case idle

    /// En cours de connexion
    case connecting

    /// Connecté et authentifié
    case connected

    /// En cours de reconnexion (avec numéro de tentative)
    case reconnecting(attempt: Int)

    /// Erreur de connexion
    case error(Error)

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
        case .error(let error):
            return "Erreur: \(error.localizedDescription)"
        }
    }
}
