//
//  OnboardingViewModel.swift
//  OHeas
//
//  Onboarding state machine — gates, HealthKit, consent.
//  引导状态机 — 门控、HealthKit、同意。
//


import Foundation
import OHeasCore

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var onboardingState: OnboardingState = OnboardingState()

    private let onboardingStore = OnboardingStore(fileURL: OHeasStorageURLs.onboarding)
    private let consentManager: ConsentManager
    private let errorReporter: ErrorReporter
    private var analyticsService: BetaAnalyticsService?

    init(consentManager: ConsentManager, errorReporter: ErrorReporter) {
        self.consentManager = consentManager
        self.errorReporter = errorReporter
    }

    func configure(analyticsService: BetaAnalyticsService) {
        self.analyticsService = analyticsService
    }

    func loadOnboardingState() {
        onboardingState = onboardingStore.load()
    }

    func saveOnboardingState() {
        do {
            try onboardingStore.save(onboardingState)
        } catch {
            errorReporter.record(category: .storage, message: "Failed to save onboarding state: \(error.localizedDescription)")
        }
    }

    func completeOnboarding(
        dataSource: HealthDataSource,
        activeGoals: [UserGoal],
        baselineSampleCount: Int
    ) {
        var state = onboardingState
        for step in OnboardingStep.allCases {
            state = OnboardingFlow().complete(step: step, in: state)
        }
        state.selectedGoals = activeGoals
        state.healthKitAuthorized = dataSource == .appleHealth
        state.privacyConfirmed = true
        state.aiConsentAccepted = consentManager.hasConsent(.aiLifestyleAdvice)
        state.baselineInitialized = baselineSampleCount > 0
        onboardingState = state
        saveOnboardingState()
        analyticsService.map { _ = try? $0.record(eventType: .onboardingCompleted, userId: "local") }
    }

    func skipHealthKitDuringOnboarding() {
        onboardingState = OnboardingFlow().healthKitRejected(onboardingState)
        saveOnboardingState()
    }

    var hasCompletedOnboarding: Bool {
        onboardingState.hasCompletedOnboarding
    }
}
