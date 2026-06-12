//
//  AppRootView.swift
//  OHeas
//
//  AppRootView.swift — OHeas UI component.
//  AppRootView.swift — OHeas UI 组件.
//  Three-state launch: splash → onboarding or main content.
//

import OHeasCore
import SwiftUI

struct AppRootView: View {
    @StateObject private var viewModel = OHeasViewModel()
    @AppStorage("oheas.aiEnabled") private var aiEnabled = true
    @AppStorage("oheas.remindersEnabled") private var remindersEnabled = false
    @AppStorage("oheas.language") private var languageRawValue = AppLanguage.chinese.rawValue
    @State private var language: AppLanguage = .chinese

    /// Whether the splash / loading view is still visible.
    @State private var showSplash = true
    /// Set to true once load() finishes.
    @State private var loadCompleted = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if showSplash {
                LaunchSplashView(language: language, reduceMotion: reduceMotion)
                    .transition(.opacity)
            } else if viewModel.onboardingState.hasCompletedOnboarding {
                RootTabView(viewModel: viewModel)
                    .transition(.opacity)
            } else {
                OnboardingView(viewModel: viewModel)
                    .transition(.opacity)
            }
        }
        .environment(\.appLanguage, language)
        .onAppear {
            language = AppLanguage(rawValue: languageRawValue) ?? .chinese
        }
        .onChange(of: languageRawValue) { newValue in
            language = AppLanguage(rawValue: newValue) ?? .chinese
        }
        .task {
            print("[AppRootView] load() called — should appear only once per launch")

            // Configure backend for Apple Sign In + cloud sync
            let backendConfig = BackendAppConfiguration.load()
            viewModel.configureBackend(baseURL: backendConfig.baseURL)
            viewModel.restoreAppleSession()

            // Run load() and the minimum splash duration in parallel.
            // The splash shows for at least 1.2 s so the ring animation lands.
            async let loadDone: () = viewModel.load(aiEnabled: aiEnabled, remindersEnabled: remindersEnabled)
            async let minSplash: () = Task.sleep(nanoseconds: 1_200_000_000) // 1.2 s

            _ = try? await (loadDone, minSplash)

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

            // Fade splash out, content in
            withAnimation(.easeInOut(duration: 0.4)) {
                showSplash = false
            }
        }
    }
}
