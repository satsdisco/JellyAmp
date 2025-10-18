//
//  KeychainService.swift
//  JellyAmp
//
//  Secure storage service for Jellyfin access tokens using iOS Keychain
//  Ensures sensitive authentication data is encrypted at rest
//

import Foundation
import Security

/// Service for secure storage of authentication tokens in iOS Keychain
/// Provides thread-safe access to encrypted credential storage
class KeychainService {
    static let shared = KeychainService()

    private let serviceName = "com.jellyamp.jellyfin"
    private let accountName = "jellyfinAccessToken"

    private init() {}

    // MARK: - Public Methods

    /// Saves access token to Keychain
    /// - Parameter token: The Jellyfin access token to store securely
    func saveAccessToken(_ token: String) {
        let data = Data(token.utf8)

        // Create query for adding item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock // Available after first unlock for background playback
        ]

        // Delete any existing item first
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            print("Failed to save access token to Keychain: \(status)")
        }
    }

    /// Retrieves access token from Keychain
    /// - Returns: The stored Jellyfin access token, or nil if not found
    func getAccessToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess,
           let data = dataTypeRef as? Data,
           let token = String(data: data, encoding: .utf8) {
            return token
        }

        return nil
    }

    /// Deletes access token from Keychain
    /// Used during sign out to ensure complete credential removal
    func deleteAccessToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            print("Failed to delete access token from Keychain: \(status)")
        }
    }

    // MARK: - Additional Secure Storage

    /// Generic method to store any sensitive string data
    /// - Parameters:
    ///   - value: The string value to store
    ///   - key: The unique key for this value
    func store(_ value: String, for key: String) {
        let data = Data(value.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    /// Generic method to retrieve any stored string data
    /// - Parameter key: The unique key for the value
    /// - Returns: The stored string value, or nil if not found
    func retrieve(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess,
           let data = dataTypeRef as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        }

        return nil
    }

    /// Removes a stored value
    /// - Parameter key: The unique key for the value to remove
    func remove(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }

    /// Clears all stored credentials
    /// Use with caution - this will remove all app keychain data
    func clearAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]

        SecItemDelete(query as CFDictionary)
    }
}
