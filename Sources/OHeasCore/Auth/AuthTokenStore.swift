//
//  AuthTokenStore.swift
//  OHeas
//
//  Secure JWT storage via Keychain.
//  通过 Keychain 安全存储 JWT。
//

import Foundation

/// Persists OHeas auth tokens in the iOS Keychain.
public struct AuthTokenStore: Sendable {

    // MARK: - Public API

    public static func saveTokens(_ pair: AuthTokenPair) {
        KeychainStore.save(key: Keys.accessToken, value: pair.accessToken)
        KeychainStore.save(key: Keys.refreshToken, value: pair.refreshToken)
        KeychainStore.save(key: Keys.userId, value: pair.userId.uuidString)
    }

    public static func loadTokens() -> AuthTokenPair? {
        guard
            let access = KeychainStore.load(key: Keys.accessToken),
            let refresh = KeychainStore.load(key: Keys.refreshToken),
            let userIdStr = KeychainStore.load(key: Keys.userId),
            let userId = UUID(uuidString: userIdStr)
        else {
            return nil
        }
        return AuthTokenPair(
            accessToken: access,
            refreshToken: refresh,
            tokenType: "bearer",
            userId: userId
        )
    }

    public static func loadBearerToken() -> String? {
        KeychainStore.load(key: Keys.accessToken)
    }

    public static func clearTokens() {
        KeychainStore.delete(key: Keys.accessToken)
        KeychainStore.delete(key: Keys.refreshToken)
        KeychainStore.delete(key: Keys.userId)
    }

    public static var hasTokens: Bool {
        KeychainStore.load(key: Keys.accessToken) != nil
    }

    // MARK: - Private

    private enum Keys {
        static let accessToken = "com.oheas.mvp.access-token"
        static let refreshToken = "com.oheas.mvp.refresh-token"
        static let userId = "com.oheas.mvp.user-id"
    }
}
