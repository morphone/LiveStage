//
//  AppError.swift
//  LiveStage
//
//  Created by Claude AI on 2025-11-18.
//

import Foundation

/// Énumération complète des erreurs de l'application
enum AppError: LocalizedError {

    // MARK: - Erreurs Réseau

    case networkError(Error)
    case noInternetConnection
    case requestTimeout
    case serverError(statusCode: Int)

    // MARK: - Erreurs Authentification

    case notAuthenticated
    case authenticationFailed(Error)
    case userCancelled
    case invalidCallback
    case tokenExpired
    case tokenRefreshFailed

    // MARK: - Erreurs API

    case invalidResponse
    case invalidData
    case apiError(statusCode: Int, message: String?)
    case rateLimitExceeded
    case quotaExceeded

    // MARK: - Erreurs Streaming

    case streamingError(String)
    case rtmpConnectionFailed
    case cameraPermissionDenied
    case microphonePermissionDenied
    case cameraNotAvailable
    case encodingError(String)

    // MARK: - Erreurs Validation

    case invalidInput(field: String, reason: String)
    case titleTooShort
    case titleTooLong
    case descriptionTooLong
    case invalidScheduleDate

    // MARK: - Erreurs Système

    case unknownError
    case keychainError(String)

    // MARK: - LocalizedError Implementation

    var errorDescription: String? {
        switch self {
        // Erreurs Réseau
        case .networkError(let error):
            return "Erreur réseau : \(error.localizedDescription)"
        case .noInternetConnection:
            return "Aucune connexion Internet. Veuillez vérifier votre connexion."
        case .requestTimeout:
            return "La requête a expiré. Veuillez réessayer."
        case .serverError(let code):
            return "Erreur serveur (code \(code)). Veuillez réessayer plus tard."

        // Erreurs Authentification
        case .notAuthenticated:
            return "Non authentifié. Veuillez vous connecter à YouTube."
        case .authenticationFailed(let error):
            return "Échec de l'authentification : \(error.localizedDescription)"
        case .userCancelled:
            return "Authentification annulée."
        case .invalidCallback:
            return "Erreur lors de l'authentification. Veuillez réessayer."
        case .tokenExpired:
            return "Votre session a expiré. Veuillez vous reconnecter."
        case .tokenRefreshFailed:
            return "Impossible de rafraîchir votre session. Veuillez vous reconnecter."

        // Erreurs API
        case .invalidResponse:
            return "Réponse invalide du serveur."
        case .invalidData:
            return "Données reçues invalides."
        case .apiError(let code, let message):
            if let message = message {
                return "Erreur API (\(code)): \(message)"
            }
            return "Erreur API (code \(code))."
        case .rateLimitExceeded:
            return "Trop de requêtes. Veuillez patienter quelques instants."
        case .quotaExceeded:
            return "Quota API dépassé. Veuillez réessayer demain."

        // Erreurs Streaming
        case .streamingError(let message):
            return "Erreur de streaming : \(message)"
        case .rtmpConnectionFailed:
            return "Impossible de se connecter au serveur de streaming."
        case .cameraPermissionDenied:
            return "Accès à la caméra refusé. Veuillez autoriser l'accès dans les Réglages."
        case .microphonePermissionDenied:
            return "Accès au microphone refusé. Veuillez autoriser l'accès dans les Réglages."
        case .cameraNotAvailable:
            return "Caméra non disponible."
        case .encodingError(let message):
            return "Erreur d'encodage : \(message)"

        // Erreurs Validation
        case .invalidInput(let field, let reason):
            return "\(field) : \(reason)"
        case .titleTooShort:
            return "Le titre doit contenir au moins 1 caractère."
        case .titleTooLong:
            return "Le titre ne peut pas dépasser 100 caractères."
        case .descriptionTooLong:
            return "La description ne peut pas dépasser 5000 caractères."
        case .invalidScheduleDate:
            return "La date de diffusion doit être dans le futur."

        // Erreurs Système
        case .unknownError:
            return "Une erreur inconnue s'est produite."
        case .keychainError(let message):
            return "Erreur de sécurité : \(message)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        // Erreurs Réseau
        case .networkError, .noInternetConnection:
            return "Vérifiez votre connexion Internet et réessayez."
        case .requestTimeout:
            return "Réessayez dans quelques instants."
        case .serverError:
            return "Le serveur rencontre des problèmes. Veuillez réessayer plus tard."

        // Erreurs Authentification
        case .notAuthenticated, .tokenExpired, .tokenRefreshFailed:
            return "Connectez-vous à nouveau pour continuer."
        case .authenticationFailed:
            return "Vérifiez vos identifiants et réessayez."
        case .userCancelled:
            return "Appuyez sur Se connecter pour vous authentifier."
        case .invalidCallback:
            return "Réessayez de vous connecter."

        // Erreurs API
        case .invalidResponse, .invalidData:
            return "Réessayez ou contactez le support si le problème persiste."
        case .apiError:
            return "Réessayez dans quelques instants."
        case .rateLimitExceeded:
            return "Attendez quelques minutes avant de réessayer."
        case .quotaExceeded:
            return "Le quota API de l'application est atteint. Réessayez demain."

        // Erreurs Streaming
        case .streamingError, .rtmpConnectionFailed:
            return "Vérifiez votre connexion et réessayez."
        case .cameraPermissionDenied, .microphonePermissionDenied:
            return "Allez dans Réglages > LiveStage pour autoriser l'accès."
        case .cameraNotAvailable:
            return "Vérifiez qu'aucune autre application n'utilise la caméra."
        case .encodingError:
            return "Réessayez avec des paramètres de qualité inférieurs."

        // Erreurs Validation
        case .invalidInput, .titleTooShort, .titleTooLong, .descriptionTooLong:
            return "Corrigez les champs en erreur et réessayez."
        case .invalidScheduleDate:
            return "Choisissez une date future."

        // Erreurs Système
        case .unknownError:
            return "Redémarrez l'application ou contactez le support."
        case .keychainError:
            return "Réinstallez l'application si le problème persiste."
        }
    }

    /// Actions suggérées pour l'utilisateur
    var suggestedActions: [ErrorAction] {
        switch self {
        case .networkError, .noInternetConnection, .requestTimeout:
            return [.retry, .cancel]
        case .serverError, .apiError, .rateLimitExceeded:
            return [.retry, .cancel]
        case .notAuthenticated, .tokenExpired, .tokenRefreshFailed:
            return [.login, .cancel]
        case .authenticationFailed, .invalidCallback:
            return [.retry, .cancel]
        case .userCancelled:
            return [.login, .cancel]
        case .cameraPermissionDenied, .microphonePermissionDenied:
            return [.openSettings, .cancel]
        case .streamingError, .rtmpConnectionFailed, .cameraNotAvailable:
            return [.retry, .cancel]
        case .invalidInput, .titleTooShort, .titleTooLong, .descriptionTooLong, .invalidScheduleDate:
            return [.dismiss]
        case .quotaExceeded:
            return [.cancel]
        default:
            return [.retry, .cancel]
        }
    }
}

// MARK: - Error Actions

/// Actions possibles pour résoudre une erreur
enum ErrorAction {
    case retry
    case cancel
    case login
    case openSettings
    case dismiss

    var title: String {
        switch self {
        case .retry:
            return "Réessayer"
        case .cancel:
            return "Annuler"
        case .login:
            return "Se connecter"
        case .openSettings:
            return "Ouvrir Réglages"
        case .dismiss:
            return "OK"
        }
    }
}
