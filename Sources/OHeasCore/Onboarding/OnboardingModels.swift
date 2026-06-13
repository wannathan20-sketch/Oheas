//
//  OnboardingModels.swift
//  OHeas
//
//  Onboarding state machine models.
//  引导流程状态机模型。
//


import Foundation

public enum OnboardingStep: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case welcome
    case goalSetup = "goal_setup"
    case healthKitPermission = "healthkit_permission"
    case privacySettings = "privacy_settings"
    case aiConsent = "ai_consent"
    case baselineSetup = "baseline_setup"
    case firstRecommendation = "first_recommendation"

    public var id: String { rawValue }
}

public struct OnboardingState: Codable, Equatable, Sendable {
    public var hasCompletedOnboarding: Bool
    public var hasCompletedAuth: Bool
    public var completedSteps: [OnboardingStep]
    public var selectedGoals: [UserGoal]
    public var healthKitAuthorized: Bool
    public var privacyConfirmed: Bool
    public var aiConsentAccepted: Bool
    public var baselineInitialized: Bool
    public var limitedModeReason: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        hasCompletedOnboarding: Bool = false,
        hasCompletedAuth: Bool = false,
        completedSteps: [OnboardingStep] = [],
        selectedGoals: [UserGoal] = [],
        healthKitAuthorized: Bool = false,
        privacyConfirmed: Bool = false,
        aiConsentAccepted: Bool = false,
        baselineInitialized: Bool = false,
        limitedModeReason: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasCompletedAuth = hasCompletedAuth
        self.completedSteps = completedSteps
        self.selectedGoals = selectedGoals
        self.healthKitAuthorized = healthKitAuthorized
        self.privacyConfirmed = privacyConfirmed
        self.aiConsentAccepted = aiConsentAccepted
        self.baselineInitialized = baselineInitialized
        self.limitedModeReason = limitedModeReason
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct OnboardingStore: Sendable {
    private let store: SingleValueStore<OnboardingState>

    public init(fileURL: URL) {
        self.store = SingleValueStore(fileURL: fileURL, defaultValue: OnboardingState())
    }

    public func load() -> OnboardingState {
        (try? store.load()) ?? OnboardingState()
    }

    public func save(_ state: OnboardingState) throws {
        var copy = state
        copy.updatedAt = Date()
        try store.save(copy)
    }
}

public struct OnboardingFlow: Sendable {
    public init() {}

    public func complete(step: OnboardingStep, in state: OnboardingState) -> OnboardingState {
        var copy = state
        if !copy.completedSteps.contains(step) {
            copy.completedSteps.append(step)
        }
        copy.updatedAt = Date()
        copy.hasCompletedOnboarding = Set(copy.completedSteps) == Set(OnboardingStep.allCases)
        return copy
    }

    public func baselineMessage(metrics: [DailyHealthMetrics]) -> String {
        let recoveryDays = metrics.filter { $0.sleepHours != nil && $0.hrv != nil }.count
        if recoveryDays < 7 {
            return "Baseline is still limited. Wear Apple Watch overnight for a few more days to improve confidence."
        }
        return "Baseline initialized from recent aggregate metrics."
    }
}
