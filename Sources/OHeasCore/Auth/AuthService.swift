//
//  AuthService.swift
//  OHeas
//
//  Local authentication service — sign in, sign out, local only mode.
//  本地认证服务 — 登录、登出、仅本地模式。
//


import Foundation

public struct AuthenticatedUser: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var email: String?
    public var displayName: String?
    public var isLocalOnly: Bool

    public init(id: UUID = UUID(), email: String? = nil, displayName: String? = nil, isLocalOnly: Bool) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.isLocalOnly = isLocalOnly
    }

    public static var localAnonymous: AuthenticatedUser {
        AuthenticatedUser(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, displayName: "Local User", isLocalOnly: true)
    }
}

public enum AuthState: Codable, Equatable, Sendable {
    case signedOut
    case signedIn
    case localOnly
    case loading
    case error(String)
}

public protocol AuthServiceProtocol: Sendable {
    var currentUser: AuthenticatedUser? { get }
    var authState: AuthState { get }
    func signInWithEmail(_ email: String, password: String) async throws -> AuthenticatedUser
    func signUpWithEmail(_ email: String, password: String) async throws -> AuthenticatedUser
    func signOut() async
    func restoreSession() async -> AuthenticatedUser?
}

public final class LocalAuthService: AuthServiceProtocol, @unchecked Sendable {
    private var user: AuthenticatedUser?
    private var state: AuthState

    public init() {
        self.user = .localAnonymous
        self.state = .localOnly
    }

    public var currentUser: AuthenticatedUser? {
        user
    }

    public var authState: AuthState {
        state
    }

    public func signInWithEmail(_ email: String, password: String) async throws -> AuthenticatedUser {
        let signedIn = AuthenticatedUser(email: email, displayName: email, isLocalOnly: false)
        user = signedIn
        state = .signedIn
        return signedIn
    }

    public func signUpWithEmail(_ email: String, password: String) async throws -> AuthenticatedUser {
        try await signInWithEmail(email, password: password)
    }

    public func signOut() async {
        user = nil
        state = .signedOut
    }

    public func restoreSession() async -> AuthenticatedUser? {
        if user == nil {
            user = .localAnonymous
            state = .localOnly
        }
        return user
    }
}

public final class BackendAuthService: AuthServiceProtocol, @unchecked Sendable {
    private var user: AuthenticatedUser?
    private var state: AuthState = .signedOut

    public init() {}

    public var currentUser: AuthenticatedUser? { user }
    public var authState: AuthState { state }

    public func signInWithEmail(_ email: String, password: String) async throws -> AuthenticatedUser {
        state = .loading
        let signedIn = AuthenticatedUser(email: email, displayName: email, isLocalOnly: false)
        user = signedIn
        state = .signedIn
        return signedIn
    }

    public func signUpWithEmail(_ email: String, password: String) async throws -> AuthenticatedUser {
        try await signInWithEmail(email, password: password)
    }

    public func signOut() async {
        user = nil
        state = .signedOut
    }

    public func restoreSession() async -> AuthenticatedUser? {
        user
    }
}
