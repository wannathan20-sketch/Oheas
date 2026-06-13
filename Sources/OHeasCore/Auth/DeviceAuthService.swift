//
//  DeviceAuthService.swift
//  OHeas
//
//  Device-based anonymous login — no Apple ID required.
//  设备匿名登录 — 无需 Apple ID。
//
//  On first launch, generates a UUID stored in Keychain.
//  Calls POST /v1/auth/device to exchange the device ID for a JWT pair.
//  Subsequent launches reuse the stored device ID and refresh the token.
//

import Foundation

/// Handles device-based anonymous authentication with the OHeas backend.
///
/// This is the primary auth path for users without an Apple Developer account.
/// The device ID is a random UUID generated once and stored in Keychain.
public struct DeviceAuthService: Sendable {

    public init() {}

    // MARK: - Public API

    /// Perform device login. Returns a JWT pair from the backend.
    ///
    /// - If a device ID already exists in Keychain, it is reused.
    /// - Otherwise a new UUID is generated and saved.
    /// - The backend creates or looks up the user by device ID.
    ///
    /// - Parameter backendBaseURL: The OHeas backend base URL.
    /// - Returns: AuthTokenPair (access token + refresh token + user ID).
    public func login(backendBaseURL: URL) async throws -> AuthTokenPair {
        let deviceId = getOrCreateDeviceId()

        let url = backendBaseURL.appendingPathComponent("v1/auth/device")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = DeviceLoginRequest(deviceId: deviceId, deviceName: nil)
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AuthError.networkError("Invalid response type")
        }
        guard (200..<300).contains(http.statusCode) else {
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            throw AuthError.networkError("Device login failed: HTTP \(http.statusCode) \(bodyStr)")
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(AuthTokenPair.self, from: data)
        } catch {
            throw AuthError.invalidResponse
        }
    }

    /// The current device ID, or nil if not yet generated.
    public var deviceId: String? {
        KeychainStore.load(key: Keys.deviceId)
    }

    /// Check if a device ID has been generated on this device.
    public var hasDeviceId: Bool {
        deviceId != nil
    }

    // MARK: - Private

    private func getOrCreateDeviceId() -> String {
        if let existing = KeychainStore.load(key: Keys.deviceId), !existing.isEmpty {
            return existing
        }
        let newId = UUID().uuidString
        KeychainStore.save(key: Keys.deviceId, value: newId)
        return newId
    }

    private enum Keys {
        static let deviceId = "com.oheas.mvp.device-id"
    }
}
