//
//  KeychainStore.swift
//  topway
//
//  Secure storage for sensitive credentials (e.g. the Railway API token).
//  Backed by the macOS Keychain: encrypted at rest, ACL-gated to this app,
//  and excluded from unencrypted backups / iCloud sync.
//

import Foundation
import Security

/// Thin wrapper around the Keychain for storing small secret strings.
///
/// Items are scoped to this app via `service` and use
/// `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` so the secret never leaves
/// the device and is only readable while the system is unlocked.
enum KeychainStore {
    /// Service identifier shared by all of this app's Keychain items.
    private nonisolated static let service = Bundle.main.bundleIdentifier ?? "com.pulgueta.topway"

    /// Stores (or replaces) the secret for `account`. An empty string deletes it.
    ///
    /// Updates an existing item in place when present, otherwise inserts a new
    /// one — so there's never a window where the secret is missing from the
    /// Keychain (unlike delete-then-add).
    @discardableResult
    nonisolated static func save(_ value: String, for account: String) -> Bool {
        guard !value.isEmpty else { return delete(account) }
        guard let data = value.data(using: .utf8) else { return false }

        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        switch updateStatus {
        case errSecSuccess:
            return true
        case errSecItemNotFound:
            let addQuery = baseQuery.merging(attributes) { _, new in new }
            return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
        default:
            return false
        }
    }

    /// Returns the secret for `account`, or `nil` if absent.
    nonisolated static func read(_ account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8)
        else { return nil }
        return value
    }

    /// Deletes the secret for `account`. Succeeds even if nothing was stored.
    @discardableResult
    nonisolated static func delete(_ account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
