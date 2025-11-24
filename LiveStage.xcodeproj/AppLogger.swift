//
//  AppLogger.swift
//  LiveStage
//
//  Created by Claude AI on 2025-11-18.
//

import Foundation
import OSLog

/// Système de logging centralisé utilisant OSLog
enum AppLogger {

    // MARK: - Logger Categories

    /// Logger pour les opérations API
    static let api = Logger(subsystem: subsystem, category: "API")

    /// Logger pour l'authentification
    static let auth = Logger(subsystem: subsystem, category: "Auth")

    /// Logger pour le streaming
    static let stream = Logger(subsystem: subsystem, category: "Stream")

    /// Logger pour la caméra
    static let camera = Logger(subsystem: subsystem, category: "Camera")

    /// Logger pour l'interface utilisateur
    static let ui = Logger(subsystem: subsystem, category: "UI")

    /// Logger général
    static let general = Logger(subsystem: subsystem, category: "General")

    // MARK: - Configuration

    private static let subsystem = "com.livestage"

    // MARK: - Convenience Methods

    /// Log une requête API (sans données sensibles)
    static func logAPIRequest(url: String, method: String) {
        api.info("[\(method)] \(url)")
    }

    /// Log une réponse API
    static func logAPIResponse(url: String, statusCode: Int, duration: TimeInterval) {
        let emoji = statusCode >= 200 && statusCode < 300 ? "✅" : "❌"
        api.info("\(emoji) [\(statusCode)] \(url) - \(String(format: "%.2f", duration))s")
    }

    /// Log une erreur API (sans token ni données sensibles)
    static func logAPIError(url: String, error: Error) {
        api.error("❌ API Error - \(url): \(error.localizedDescription)")
    }

    /// Log une authentification réussie
    static func logAuthenticationSuccess() {
        auth.info("✅ Authentification réussie")
    }

    /// Log un échec d'authentification (sans détails sensibles)
    static func logAuthenticationFailure(reason: String) {
        auth.error("❌ Échec authentification: \(reason)")
    }

    /// Log un rafraîchissement de token
    static func logTokenRefresh(success: Bool) {
        if success {
            auth.info("🔄 Token rafraîchi avec succès")
        } else {
            auth.error("🔄 Échec du rafraîchissement du token")
        }
    }

    /// Log le démarrage d'un stream
    static func logStreamStart(streamId: String) {
        stream.info("▶️  Démarrage du stream: \(streamId)")
    }

    /// Log l'arrêt d'un stream
    static func logStreamStop(streamId: String, duration: TimeInterval?) {
        if let duration = duration {
            stream.info("⏹️ Arrêt du stream: \(streamId) - Durée: \(String(format: "%.1f", duration))s")
        } else {
            stream.info("⏹️ Arrêt du stream: \(streamId)")
        }
    }

    /// Log une erreur de streaming
    static func logStreamError(error: String) {
        stream.error("❌ Erreur de streaming: \(error)")
    }

    /// Log une connexion RTMP
    static func logRTMPConnection(url: String, success: Bool) {
        if success {
            // Ne pas logger l'URL complète pour éviter de révéler le stream key
            stream.info("🔌 Connexion RTMP réussie")
        } else {
            stream.error("🔌 Échec de connexion RTMP")
        }
    }

    /// Log les permissions de la caméra
    static func logCameraPermission(granted: Bool) {
        if granted {
            camera.info("📷 Permission caméra accordée")
        } else {
            camera.warning("📷 Permission caméra refusée")
        }
    }

    /// Log les permissions du microphone
    static func logMicrophonePermission(granted: Bool) {
        if granted {
            camera.info("🎤 Permission microphone accordée")
        } else {
            camera.warning("🎤 Permission microphone refusée")
        }
    }

    /// Log une erreur générale
    static func logError(_ error: Error, context: String = "") {
        let message = context.isEmpty ? error.localizedDescription : "\(context): \(error.localizedDescription)"
        general.error("❌ \(message)")
    }

    /// Log une action utilisateur
    static func logUserAction(_ action: String) {
        ui.debug("👤 \(action)")
    }

    /// Log une navigation
    static func logNavigation(to destination: String) {
        ui.debug("🧭 Navigation vers: \(destination)")
    }
}

// MARK: - Performance Logging

/// Helper pour mesurer les performances
struct PerformanceLogger {
    private let startTime: CFAbsoluteTime
    private let operation: String
    private let logger: Logger

    init(operation: String, logger: Logger = AppLogger.general) {
        self.operation = operation
        self.logger = logger
        self.startTime = CFAbsoluteTimeGetCurrent()
        logger.debug("⏱️ Début: \(operation)")
    }

    func end() {
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        logger.debug("⏱️ Fin: \(operation) - \(String(format: "%.2f", duration))s")
    }
}

// MARK: - Sensitive Data Filtering

extension AppLogger {

    /// Filtre les données sensibles d'une chaîne (tokens, mots de passe, etc.)
    static func filterSensitiveData(_ string: String) -> String {
        var filtered = string

        // Filtrer les tokens (patterns communs)
        filtered = filtered.replacingOccurrences(
            of: "(?i)(token|key|secret|password)=[^&\\s]+",
            with: "$1=***",
            options: .regularExpression
        )

        // Filtrer les tokens Bearer
        filtered = filtered.replacingOccurrences(
            of: "Bearer [A-Za-z0-9_-]+",
            with: "Bearer ***",
            options: .regularExpression
        )

        return filtered
    }

    /// Log une URL en filtrant les paramètres sensibles
    static func logURLSafely(_ url: String, method: String = "GET") {
        let safeURL = filterSensitiveData(url)
        api.info("[\(method)] \(safeURL)")
    }
}
