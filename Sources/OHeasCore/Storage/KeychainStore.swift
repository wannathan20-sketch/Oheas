//
//  KeychainStore.swift
//  OHeas
//
//  Secure API key persistence via iOS Keychain.
//  通过 iOS Keychain 安全持久化 API Key。
//

import Foundation
import Security

/// Minimal Keychain wrapper for storing small secrets (API keys).
/// Uses kSecClassGenericPassword with service = "com.oheas.mvp".
public struct KeychainStore: Sendable {

    // MARK: - Public API

    /// Save a value to the Keychain. Returns true on success.
    @discardableResult
    public static func save(key: String, value: String) -> Bool {
        delete(key: key) // Remove existing item first to avoid duplicate

        guard let data = value.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("[KeychainStore] Save failed for key '\(key)': \(status)")
        }
        return status == errSecSuccess
    }

    /// Load a value from the Keychain. Returns nil if not found.
    public static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    /// Delete a value from the Keychain.
    @discardableResult
    public static func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Private

    private static let service = "com.oheas.mvp"
}
