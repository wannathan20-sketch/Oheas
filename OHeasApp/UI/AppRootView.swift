//
//  AppRootView.swift
//  OHeas
//
//  AppRootView.swift — OHeas UI component.
//  AppRootView.swift — OHeas UI 组件.
//

import OHeasCore
import SwiftUI

struct AppRootView: View {
    @StateObject private var viewModel = OHeasViewModel()
    @AppStorage("oheas.aiEnabled") private var aiEnabled = true
    @AppStorage("oheas.remindersEnabled") private var remindersEnabled = false

    var body: some View {
        Group {
            if viewModel.onboardingState.hasCompletedOnboarding {
                RootTabView(viewModel: viewModel)
            } else {
                OnboardingView(viewModel: viewModel)
            }
        }
        .task {
            print("[AppRootView] load() called — should appear only once per launch")

            // Configure backend for Apple Sign In + cloud sync
            let backendConfig = BackendAppConfiguration.load()
            viewModel.configureBackend(baseURL: backendConfig.baseURL)
            viewModel.restoreAppleSession()

            await viewModel.load(aiEnabled: aiEnabled, remindersEnabled: remindersEnabled)

            // Persist API key to Keychain so home-screen launches work
            let config = OpenAIAppConfiguration.load()
            if let key = config.apiKey, !key.isEmpty, key != "DEEPSEEK_API_KEY_PLACEHOLDER" {
                let keychainKey: String
                switch config.provider {
                case .deepSeek:
                    keychainKey = "DEEPSEEK_API_KEY"
                case .openAI:
                    keychainKey = "OPENAI_API_KEY"
                case .custom:
                    keychainKey = "LLM_API_KEY"
                }
                KeychainStore.save(key: keychainKey, value: key)
            }
        }
    }
}
