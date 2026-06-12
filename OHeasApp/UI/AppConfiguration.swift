//
//  AppConfiguration.swift
//  OHeas
//
//  AppConfiguration.swift — OHeas UI component.
//  AppConfiguration.swift — OHeas UI 组件。
//


import Foundation
import OHeasCore

// MARK: - Storage URLs

enum OHeasStorageURLs {
    static var baseDirectory: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return directory.appendingPathComponent("OHeas", isDirectory: true)
    }

    static var recommendations: URL {
        baseDirectory.appendingPathComponent("recommendations.json")
    }

    static var feedback: URL {
        baseDirectory.appendingPathComponent("feedback.json")
    }

    static var verificationReports: URL {
        baseDirectory.appendingPathComponent("verification_reports.json")
    }

    static var memory: URL {
        baseDirectory.appendingPathComponent("memory.json")
    }

    static var experiments: URL {
        baseDirectory.appendingPathComponent("experiments.json")
    }

    static var goals: URL {
        baseDirectory.appendingPathComponent("goals.json")
    }

    static var weeklyPlans: URL {
        baseDirectory.appendingPathComponent("weekly_plans.json")
    }

    static var weeklyReviews: URL {
        baseDirectory.appendingPathComponent("weekly_reviews.json")
    }

    static var privacySettings: URL {
        baseDirectory.appendingPathComponent("privacy_settings.json")
    }

    static var promptSnapshots: URL {
        baseDirectory.appendingPathComponent("prompt_snapshots.json")
    }

    static var consents: URL {
        baseDirectory.appendingPathComponent("consents.json")
    }

    static var syncQueue: URL {
        baseDirectory.appendingPathComponent("sync_queue.json")
    }

    static var syncState: URL {
        baseDirectory.appendingPathComponent("sync_state.json")
    }

    static var analyticsEvents: URL {
        baseDirectory.appendingPathComponent("analytics_events.json")
    }

    static var onboarding: URL {
        baseDirectory.appendingPathComponent("onboarding.json")
    }

    static var errors: URL {
        baseDirectory.appendingPathComponent("errors.json")
    }

    static var chatMessages: URL {
        baseDirectory.appendingPathComponent("chat_messages.json")
    }

    static var badges: URL {
        baseDirectory.appendingPathComponent("badges.json")
    }

    static var streaks: URL {
        baseDirectory.appendingPathComponent("streaks.json")
    }
}

// MARK: - Backend Configuration

/// Runtime-mutable backend configuration singleton.
/// Updated on Apple Sign In / sign out to keep the sync client in sync.
actor BackendConfigStore {
    static let shared = BackendConfigStore()

    private var _baseURL: URL?
    private var _bearerToken: String?

    private init() {}

    func configure(baseURL: URL?, bearerToken: String?) {
        _baseURL = baseURL
        _bearerToken = bearerToken
    }

    func currentConfig() -> BackendConfiguration {
        BackendConfiguration(baseURL: _baseURL, bearerToken: _bearerToken)
    }
}

struct BackendAppConfiguration {
    var baseURL: URL?
    var bearerToken: String?

    static func load() -> BackendAppConfiguration {
        let environment = ProcessInfo.processInfo.environment
        let bundle = Bundle.main

        let urlString = environment["OHEAS_BACKEND_URL"]
            ?? bundle.object(forInfoDictionaryKey: "OHEAS_BACKEND_URL") as? String

        // Priority: env → Info.plist → Keychain (set by Apple Sign In)
        let token = environment["OHEAS_BACKEND_TOKEN"]
            ?? bundle.object(forInfoDictionaryKey: "OHEAS_BACKEND_TOKEN") as? String
            ?? AuthTokenStore.loadBearerToken()

        return BackendAppConfiguration(
            baseURL: urlString.flatMap(URL.init(string:)),
            bearerToken: token?.isEmpty == false ? token : nil
        )
    }

    /// Update the bearer token after Apple Sign In.
    static func updateBearerToken(_ token: String) {
        Task {
            await BackendConfigStore.shared.configure(
                baseURL: load().baseURL,
                bearerToken: token
            )
        }
    }

    /// Clear the bearer token after sign out.
    static func clearBearerToken() {
        Task {
            await BackendConfigStore.shared.configure(
                baseURL: load().baseURL,
                bearerToken: nil
            )
        }
    }

    func makeConfiguration() -> BackendConfiguration {
        BackendConfiguration(baseURL: baseURL, bearerToken: bearerToken)
    }

    func makeClient() -> BackendAPIClientProtocol {
        let configuration = makeConfiguration()
        guard configuration.isConfigured else {
            return LocalBackendAPIClient()
        }
        return HTTPBackendAPIClient(configuration: configuration)
    }
}
