//
//  KeychainHelper.swift
//  LiveStage
//
//  Created by Michael Chartier on 2025-11-17.
//

import Foundation
import Security

/// Helper pour stocker et récupérer des données sensibles dans le Keychain
enum KeychainHelper {
    
    /// Sauvegarde une valeur String dans le Keychain
    static func save(_ value: String, for key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Config.Keychain.service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // Supprimer l'ancienne valeur si elle existe
        SecItemDelete(query as CFDictionary)
        
        // Ajouter la nouvelle valeur
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    /// Récupère une valeur String depuis le Keychain
    static func load(for key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Config.Keychain.service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.loadFailed(status)
        }
        
        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodingFailed
        }
        
        return string
    }
    
    /// Supprime une valeur du Keychain
    static func delete(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Config.Keychain.service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    /// Supprime toutes les valeurs du Keychain pour cette app
    static func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Config.Keychain.service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

// MARK: - Keychain Error

enum KeychainError: LocalizedError {
    case encodingFailed
    case decodingFailed
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Échec de l'encodage des données pour le Keychain."
        case .decodingFailed:
            return "Échec du décodage des données depuis le Keychain."
        case .saveFailed(let status):
            return "Échec de la sauvegarde dans le Keychain (code: \(status))."
        case .loadFailed(let status):
            return "Échec du chargement depuis le Keychain (code: \(status))."
        case .deleteFailed(let status):
            return "Échec de la suppression depuis le Keychain (code: \(status))."
        }
    }
}

// MARK: - Convenience Extensions

extension KeychainHelper {
    /// Sauvegarde le token d'accès YouTube
    static func saveYouTubeAccessToken(_ token: String) throws {
        try save(token, for: Config.Keychain.accessTokenKey)
    }
    
    /// Charge le token d'accès YouTube
    static func loadYouTubeAccessToken() throws -> String? {
        try load(for: Config.Keychain.accessTokenKey)
    }
    
    /// Sauvegarde le refresh token YouTube
    static func saveYouTubeRefreshToken(_ token: String) throws {
        try save(token, for: Config.Keychain.refreshTokenKey)
    }
    
    /// Charge le refresh token YouTube
    static func loadYouTubeRefreshToken() throws -> String? {
        try load(for: Config.Keychain.refreshTokenKey)
    }
    
    /// Supprime tous les tokens YouTube
    static func deleteYouTubeTokens() throws {
        try delete(for: Config.Keychain.accessTokenKey)
        try delete(for: Config.Keychain.refreshTokenKey)
    }
}
