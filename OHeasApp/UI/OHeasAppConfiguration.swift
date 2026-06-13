//
//  OHeasAppConfiguration.swift
//  OHeas
//
//  OHeasAppConfiguration.swift — OHeas UI component.
//  OHeasAppConfiguration.swift — OHeas UI 组件。
//


import Foundation
import OHeasCore

struct OpenAIAppConfiguration {
    var apiKey: String?
    var model: String
    var provider: LLMProvider

    enum LLMProvider {
        case openAI
        case deepSeek
        case custom(baseURL: String)
    }

    /// Load configuration with the following priority chain:
    /// 1. Xcode scheme environment variables (DEV only)
    /// 2. Bundle Info.plist (rare, discouraged for secrets)
    /// 3. iOS Keychain (persisted from a prior Xcode launch — enables home-screen launches)
    ///
    /// PLACEHOLDER values are treated as missing (graceful fallback).
    static func load() -> OpenAIAppConfiguration {
        let environment = ProcessInfo.processInfo.environment
        let bundle = Bundle.main

        // ── DeepSeek ──
        let deepSeekKey = environment["DEEPSEEK_API_KEY"]
            ?? bundle.object(forInfoDictionaryKey: "DEEPSEEK_API_KEY") as? String
            ?? KeychainStore.load(key: "DEEPSEEK_API_KEY")

        if let key = deepSeekKey, !key.isEmpty, key != "DEEPSEEK_API_KEY_PLACEHOLDER" {
            // Persist to Keychain so home-screen launches work without backend.
            if KeychainStore.load(key: "DEEPSEEK_API_KEY") != key {
                _ = KeychainStore.save(key: "DEEPSEEK_API_KEY", value: key)
            }
            let model = environment["DEEPSEEK_MODEL"]
                ?? bundle.object(forInfoDictionaryKey: "DEEPSEEK_MODEL") as? String
                ?? "deepseek-chat"
            return OpenAIAppConfiguration(apiKey: key, model: model, provider: .deepSeek)
        }

        // ── Custom OpenAI-compatible endpoint ──
        let customKey = environment["LLM_API_KEY"]
            ?? bundle.object(forInfoDictionaryKey: "LLM_API_KEY") as? String
            ?? KeychainStore.load(key: "LLM_API_KEY")

        let customBaseURL = environment["LLM_BASE_URL"]
            ?? bundle.object(forInfoDictionaryKey: "LLM_BASE_URL") as? String
            ?? KeychainStore.load(key: "LLM_BASE_URL")

        if let key = customKey, !key.isEmpty,
           let baseURL = customBaseURL, !baseURL.isEmpty {
            let model = environment["LLM_MODEL"]
                ?? bundle.object(forInfoDictionaryKey: "LLM_MODEL") as? String
                ?? "default"
            return OpenAIAppConfiguration(apiKey: key, model: model, provider: .custom(baseURL: baseURL))
        }

        // ── OpenAI (default) ──
        let openAIKey = environment["OPENAI_API_KEY"]
            ?? bundle.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String
            ?? KeychainStore.load(key: "OPENAI_API_KEY")

        let model = environment["OPENAI_MODEL"]
            ?? bundle.object(forInfoDictionaryKey: "OPENAI_MODEL") as? String
            ?? "gpt-5.4-mini"

        return OpenAIAppConfiguration(
            apiKey: openAIKey?.isEmpty == false ? openAIKey : nil,
            model: model,
            provider: .openAI
        )
    }

    func makeClient() -> LLMClientProtocol? {
        // Tier 1: Backend proxy (server-side API key, JWT authenticated — preferred)
        if let backendClient = _makeBackendLLMClient() {
            return backendClient
        }

        // Tier 2: Local API key (direct call, for dev/testing without backend)
        guard let apiKey else { return nil }

        switch provider {
        case .deepSeek:
            return ChatCompletionsClient(
                apiKey: apiKey,
                model: model,
                endpoint: URL(string: "https://api.deepseek.com/v1/chat/completions")!,
                name: "deepseek"
            )
        case .custom(let baseURL):
            let endpoint = URL(string: baseURL.hasSuffix("/chat/completions")
                ? baseURL
                : "\(baseURL)/v1/chat/completions")!
            return ChatCompletionsClient(
                apiKey: apiKey,
                model: model,
                endpoint: endpoint,
                name: "custom"
            )
        case .openAI:
            return OpenAIClient(apiKey: apiKey, model: model)
        }
    }

    /// Attempt to create a BackendLLMClient when the backend is configured
    /// (user signed in with Apple, JWT token available).
    private func _makeBackendLLMClient() -> LLMClientProtocol? {
        let cfg = BackendConfigStore.latestConfig
        guard cfg.isConfigured,
              let baseURL = cfg.baseURL,
              let token = cfg.bearerToken,
              !token.isEmpty
        else { return nil }

        return BackendLLMClient(baseURL: baseURL, bearerToken: token)
    }
}
