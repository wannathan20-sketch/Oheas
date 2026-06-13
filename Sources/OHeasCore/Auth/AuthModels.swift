//
//  AuthModels.swift
//  OHeas
//
//  Auth data models — token pairs, sign-in results.
//  认证数据模型 — token 对、登录结果。
//

import Foundation

// MARK: - Token response from backend

public struct AuthTokenPair: Codable, Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let tokenType: String
    public let userId: UUID
    public let nickname: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case userId = "user_id"
        case nickname
    }

    public init(accessToken: String, refreshToken: String, tokenType: String, userId: UUID, nickname: String? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.userId = userId
        self.nickname = nickname
    }
}

// MARK: - Device anonymous login request body

struct DeviceLoginRequest: Codable, Sendable {
    let deviceId: String
    let deviceName: String?

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case deviceName = "device_name"
    }
}

// MARK: - Apple Sign In request body

struct AppleSignInRequest: Codable, Sendable {
    let identityToken: String
    let fullName: String?

    enum CodingKeys: String, CodingKey {
        case identityToken = "identity_token"
        case fullName = "full_name"
    }
}

// MARK: - Token refresh request body

struct TokenRefreshRequest: Codable, Sendable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

// MARK: - Email login request body

public struct EmailLoginRequest: Codable, Sendable {
    public let email: String
    public let password: String

    enum CodingKeys: String, CodingKey {
        case email
        case password
    }

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

// MARK: - Email register request body

public struct EmailRegisterRequest: Codable, Sendable {
    public let email: String
    public let password: String
    public let nickname: String?

    enum CodingKeys: String, CodingKey {
        case email
        case password
        case nickname
    }

    public init(email: String, password: String, nickname: String? = nil) {
        self.email = email
        self.password = password
        self.nickname = nickname
    }
}

// MARK: - Email bind request body

public struct EmailBindRequest: Codable, Sendable {
    public let email: String
    public let password: String

    enum CodingKeys: String, CodingKey {
        case email
        case password
    }

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

// MARK: - Nickname request body

public struct SetNicknameRequest: Codable, Sendable {
    public let nickname: String

    enum CodingKeys: String, CodingKey {
        case nickname
    }

    public init(nickname: String) {
        self.nickname = nickname
    }
}

// MARK: - Auth error

public enum AuthError: Error, LocalizedError {
    case notConfigured
    case appleSignInFailed(String)
    case networkError(String)
    case invalidResponse
    case tokenExpired

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            "Backend URL is not configured. Set OHEAS_BACKEND_URL to enable cloud features."
        case .appleSignInFailed(let detail):
            "Apple Sign In failed: \(detail)"
        case .networkError(let detail):
            "Network error: \(detail)"
        case .invalidResponse:
            "Backend returned an invalid response."
        case .tokenExpired:
            "Session expired. Please sign in again."
        }
    }
}
