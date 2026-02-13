//
//  SecurityManager.swift
//  efb-212
//
//  Actor for Keychain storage and Secure Enclave key generation.
//  Provides secure storage for API tokens, encryption keys, and other
//  sensitive data. Uses the iOS Keychain Services API directly.
//
//  This is a nonisolated actor because the project uses
//  SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor. Without nonisolated,
//  this type would be implicitly @MainActor instead of actor-isolated.
//

import Foundation
import Security

nonisolated actor SecurityManager {
    private let keychainService = "com.openefb.app"
    private let encryptionKeyTag = "com.openefb.flight-encryption"

    // MARK: - Keychain CRUD

    /// Stores a value in the Keychain under the given key.
    ///
    /// - Parameters:
    ///   - key: The Keychain account identifier.
    ///   - value: The data to store.
    /// - Throws: If the Keychain operation fails.
    func store(key: String, value: Data) throws {
        // Delete any existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add the new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: value,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecurityError.keychainWriteFailed(status: status)
        }
    }

    /// Retrieves data from the Keychain for the given key.
    ///
    /// - Parameter key: The Keychain account identifier.
    /// - Returns: The stored data, or nil if not found.
    /// - Throws: If the Keychain operation fails (other than item-not-found).
    func retrieve(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw SecurityError.keychainReadFailed(status: status)
        }
    }

    /// Deletes a Keychain item for the given key.
    ///
    /// - Parameter key: The Keychain account identifier.
    /// - Throws: If the deletion fails (other than item-not-found).
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecurityError.keychainDeleteFailed(status: status)
        }
    }

    // MARK: - Encryption Key (Secure Enclave)

    /// Returns the existing encryption key or creates a new one using the Secure Enclave.
    /// Falls back to a standard Keychain-stored key on devices without a Secure Enclave
    /// (e.g., iOS Simulator).
    ///
    /// - Returns: An elliptic curve private key reference.
    /// - Throws: If key generation or retrieval fails.
    func getOrCreateEncryptionKey() throws -> SecKey {
        // Try to retrieve an existing key
        if let existingKey = try retrieveEncryptionKey() {
            return existingKey
        }

        // Create a new key
        return try generateEncryptionKey()
    }

    /// Attempts to retrieve the stored encryption key from the Keychain.
    private func retrieveEncryptionKey() throws -> SecKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: encryptionKeyTag.data(using: .utf8) as Any,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            // swiftlint:disable:next force_cast
            return (result as! SecKey)
        case errSecItemNotFound:
            return nil
        default:
            throw SecurityError.keyRetrievalFailed(status: status)
        }
    }

    /// Generates a new 256-bit elliptic curve key.
    /// Attempts Secure Enclave first, falls back to software-based key.
    private func generateEncryptionKey() throws -> SecKey {
        let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            .privateKeyUsage,
            nil
        )

        var attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: encryptionKeyTag.data(using: .utf8) as Any,
                kSecAttrAccessControl as String: access as Any,
            ] as [String: Any],
        ]

        // Try Secure Enclave first (not available on simulator)
        #if !targetEnvironment(simulator)
        attributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
        #endif

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            if let cfError = error?.takeRetainedValue() {
                throw SecurityError.keyGenerationFailed(underlying: cfError as Error)
            }
            throw SecurityError.keyGenerationFailed(underlying: nil)
        }

        return privateKey
    }

    // MARK: - Convenience

    /// Stores a string value in the Keychain.
    func storeString(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw SecurityError.encodingFailed
        }
        try store(key: key, value: data)
    }

    /// Retrieves a string value from the Keychain.
    func retrieveString(forKey key: String) throws -> String? {
        guard let data = try retrieve(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Removes all items stored by this app in the Keychain.
    /// Use with caution — this deletes API tokens, encryption keys, etc.
    func removeAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecurityError.keychainDeleteFailed(status: status)
        }
    }
}

// MARK: - Security Errors

/// Errors specific to SecurityManager operations.
/// These are internal to the security layer and do not surface
/// through EFBError (which handles user-facing errors).
enum SecurityError: LocalizedError {
    case keychainWriteFailed(status: OSStatus)
    case keychainReadFailed(status: OSStatus)
    case keychainDeleteFailed(status: OSStatus)
    case keyGenerationFailed(underlying: Error?)
    case keyRetrievalFailed(status: OSStatus)
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .keychainWriteFailed(let status):
            return "Failed to write to Keychain (status: \(status))."
        case .keychainReadFailed(let status):
            return "Failed to read from Keychain (status: \(status))."
        case .keychainDeleteFailed(let status):
            return "Failed to delete from Keychain (status: \(status))."
        case .keyGenerationFailed(let underlying):
            if let error = underlying {
                return "Failed to generate encryption key: \(error.localizedDescription)"
            }
            return "Failed to generate encryption key."
        case .keyRetrievalFailed(let status):
            return "Failed to retrieve encryption key (status: \(status))."
        case .encodingFailed:
            return "Failed to encode string data for Keychain storage."
        }
    }
}
