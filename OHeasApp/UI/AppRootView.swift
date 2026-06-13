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
    @Environment(\.scenePhase) private var scenePhase

    /// Whether to show the auth page instead of the main app.
    /// True after onboarding completes but before the user signs in or skips.
    private var shouldShowAuthPage: Bool {
        viewModel.onboardingState.hasCompletedOnboarding
            && !viewModel.onboardingState.hasCompletedAuth
            && viewModel.authState != .signedIn
    }

    var body: some View {
        ZStack {
            if showSplash {
                LaunchSplashView(language: language, reduceMotion: reduceMotion)
                    .transition(.opacity)
            } else if viewModel.onboardingState.hasCompletedOnboarding {
                if shouldShowAuthPage {
                    AuthPageView(viewModel: viewModel) {
                        // onDismiss — called after skip or sign-in
                    }
                    .transition(.opacity)
                } else {
                    RootTabView(viewModel: viewModel)
                        .transition(.opacity)
                }
            } else {
                OnboardingView(viewModel: viewModel)
                    .transition(.opacity)
            }
        }
        .environment(\.appLanguage, language)
        .onAppear {
            language = AppLanguage(rawValue: languageRawValue) ?? .chinese
        }
        .onChange(of: languageRawValue) {
            language = AppLanguage(rawValue: languageRawValue) ?? .chinese
        }
        .task {
            print("[AppRootView] load() called — should appear only once per launch")

            // Configure backend for Apple Sign In + cloud sync
            let backendConfig = BackendAppConfiguration.load()
            viewModel.configureBackend(baseURL: backendConfig.baseURL)
            viewModel.restoreAppleSession()

            // If no existing session and backend is configured, try anonymous device login.
            // This gives users AI access without Apple Sign In.
            if viewModel.authState == .localOnly, backendConfig.baseURL != nil {
                await viewModel.performDeviceAuth()
            }

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
        .onChange(of: scenePhase) { oldPhase, newPhase in
            guard oldPhase == .background, newPhase == .active else { return }
            // Refresh HealthKit data when returning from background.
            Task {
                if await viewModel.healthData.loadHealthData() != nil {
                    await MainActor.run {
                        viewModel.healthData.refreshDerivedMetrics()
                    }
                }
                // Refresh AI recommendation if enabled.
                if aiEnabled {
                    await viewModel.refreshRecommendation(aiEnabled: aiEnabled)
                }
            }
        }
    }
}
