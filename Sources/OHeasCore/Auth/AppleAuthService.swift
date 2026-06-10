//
//  AppleAuthService.swift
//  OHeas
//
//  Sign in with Apple → backend JWT exchange.
//  Apple 登录 → 后端 JWT 交换。
//

import Foundation
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

/// Handles the full Sign in with Apple → OHeas backend auth flow.
///
/// Usage:
///   let service = AppleAuthService(backendURL: URL(string: "...")!)
///   let result = try await service.signIn()  // presents ASAuthorizationController
@MainActor
public final class AppleAuthService: NSObject, Sendable {

    private let backendBaseURL: URL

    public init(backendBaseURL: URL) {
        self.backendBaseURL = backendBaseURL
    }

    // MARK: - Public API

    /// Begin Sign in with Apple. Returns a token pair on success.
    /// On iOS this presents the system Sign in with Apple UI.
    public func signIn() async throws -> AuthTokenPair {
        #if canImport(AuthenticationServices) && os(iOS)
        let credential = try await performAppleSignIn()
        let identityToken = try extractIdentityToken(from: credential)
        let fullName = formatFullName(credential.fullName)
        return try await exchangeWithBackend(identityToken: identityToken, fullName: fullName)
        #else
        throw AuthError.appleSignInFailed("Sign in with Apple requires iOS.")
        #endif
    }

    /// Exchange a stored Apple identity token with the backend (e.g. after app relaunch).
    public func exchange(identityToken: String, fullName: String? = nil) async throws -> AuthTokenPair {
        try await exchangeWithBackend(identityToken: identityToken, fullName: fullName)
    }

    /// Refresh an expired access token.
    public func refreshAccessToken(refreshToken: String) async throws -> AuthTokenPair {
        let url = backendBaseURL.appendingPathComponent("/v1/auth/refresh")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = TokenRefreshRequest(refreshToken: refreshToken)
        request.httpBody = try JSONEncoder.oheasPretty.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AuthError.networkError("Invalid response type")
        }
        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 401 {
                throw AuthError.tokenExpired
            }
            throw AuthError.networkError("HTTP \(http.statusCode)")
        }

        return try JSONDecoder.oheas.decode(AuthTokenPair.self, from: data)
    }

    // MARK: - Private

    #if canImport(AuthenticationServices) && os(iOS)
    private func performAppleSignIn() async throws -> ASAuthorizationAppleIDCredential {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        let delegate = AppleSignInDelegate()
        authorizationController.delegate = delegate
        authorizationController.presentationContextProvider = delegate
        authorizationController.performRequests()

        return try await withCheckedThrowingContinuation { continuation in
            delegate.completion = { result in
                switch result {
                case .success(let credential):
                    continuation.resume(returning: credential)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func extractIdentityToken(from credential: ASAuthorizationAppleIDCredential) throws -> String {
        guard let identityTokenData = credential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            throw AuthError.appleSignInFailed("No identity token returned by Apple")
        }
        return identityToken
    }
    #endif

    private func formatFullName(_ name: PersonNameComponents?) -> String? {
        guard let name else { return nil }
        let formatter = PersonNameComponentsFormatter()
        return formatter.string(from: name)
    }

    private func exchangeWithBackend(identityToken: String, fullName: String?) async throws -> AuthTokenPair {
        let url = backendBaseURL.appendingPathComponent("/v1/auth/apple")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = AppleSignInRequest(identityToken: identityToken, fullName: fullName)
        request.httpBody = try JSONEncoder.oheasPretty.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AuthError.networkError("Invalid response type")
        }
        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 401 {
                throw AuthError.appleSignInFailed("Backend rejected Apple identity token")
            }
            throw AuthError.networkError("Backend returned HTTP \(http.statusCode)")
        }

        do {
            return try JSONDecoder.oheas.decode(AuthTokenPair.self, from: data)
        } catch {
            throw AuthError.invalidResponse
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

#if canImport(AuthenticationServices) && os(iOS)
private final class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    var completion: ((Result<ASAuthorizationAppleIDCredential, Error>) -> Void)?

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            completion?(.failure(AuthError.appleSignInFailed("Unexpected credential type")))
            return
        }
        completion?(.success(credential))
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        completion?(.failure(AuthError.appleSignInFailed(error.localizedDescription)))
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return UIWindow()
        }
        return window
    }
}
#endif
