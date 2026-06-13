//
//  OnboardingView.swift
//  OHeas
//
//  OnboardingView.swift — OHeas UI component.
//  Branded 4‑step onboarding: Goal → Data → Privacy → Ready.
//  OnboardingView.swift — OHeas UI 组件。品牌化 4 步欢迎流程。
//

import OHeasCore
import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: OHeasViewModel
    /// Read language directly from UserDefaults — see RootTabView for rationale.
    private var language: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: "oheas.language") ?? AppLanguage.chinese.rawValue) ?? .chinese
    }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var currentStep: Int = 0
    @State private var selectedGoal: UserGoalType = .buildConsistency
    @State private var frequency: Double = 4
    @State private var useLLM = false
    @State private var cloudSync = false
    @State private var betaAnalytics = false

    private let totalSteps = 4

    // Step-pill metadata: (icon, label key)
    private let stepPills: [(icon: String, key: TextKey)] = [
        ("target",           .goalLabel),
        ("heart.text.square", .stepPillData),
        ("lock.shield",       .privacyLabel),
        ("checkmark.circle",  .stepPillReady),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: CardStyle.gap) {
                welcomeHero

                // Single-step card — only the current step is visible
                Group {
                    switch currentStep {
                    case 0: goalCard
                    case 1: healthKitStep
                    case 2: privacyStep
                    case 3: readyStep
                    default: EmptyView()
                    }
                }
                .id(currentStep)
                .transition(.asymmetric(
                    insertion: reduceMotion
                        ? .opacity
                        : .move(edge: .trailing).combined(with: .opacity),
                    removal: reduceMotion
                        ? .opacity
                        : .move(edge: .leading).combined(with: .opacity)
                ))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .animation(.spring(response: 0.44, dampingFraction: 0.86), value: currentStep)
    }

    // MARK: - Welcome Hero

    private var welcomeHero: some View {
        VStack(spacing: 16) {
            // Brand gradient — shared aesthetic with LaunchSplashView
            VStack(spacing: 12) {
                OHeasLogo(size: 64, showBackground: true)

                VStack(spacing: 4) {
                    Text("OHeas")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.teal, Color.indigo],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text(language.text(.splashTagline))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(
                LinearGradient(
                    colors: [Color.mint.opacity(0.35), Color.teal.opacity(0.18), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.large))

            // Step pills — named indicators instead of anonymous dots
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    HStack(spacing: 4) {
                        Image(systemName: stepPills[i].icon)
                            .font(.caption2)
                        Text(language.text(stepPills[i].key))
                            .font(.caption2)
                    }
                    .foregroundStyle(i <= currentStep ? .white : .secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(i <= currentStep ? Color.indigo : Color(.systemGray5))
                    )
                    .scaleEffect(i == currentStep && !reduceMotion ? 1.08 : 1)
                    .animation(.spring(response: 0.36, dampingFraction: 0.72), value: currentStep)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 4)

            // Medical disclaimer
            Text(language.text(.appDisclaimer))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Goal Card (Step 0)

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: CardStyle.innerSpacing) {
            Label(language.text(.goalSetup), systemImage: "target")
                .font(.headline)
            Picker(language.text(.goalLabel), selection: $selectedGoal) {
                ForEach(UserGoalType.allCases, id: \.self) { type in
                    Text(language.goalType(type)).tag(type)
                }
            }
            Stepper("\(language.text(.weeklyFrequency)): \(Int(frequency))", value: $frequency, in: 1...7, step: 1)

            nextStepButton(from: 0)
        }
        .cardBackground()
    }

    // MARK: - HealthKit Step (Step 1)

    private var healthKitStep: some View {
        VStack(alignment: .leading, spacing: CardStyle.gap) {
            VStack(alignment: .leading, spacing: CardStyle.innerSpacing) {
                Label(language.text(.healthKitPermission), systemImage: "heart.text.square")
                    .font(.headline)
                Text(language.text(.permissionWhyDescription))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .cardBackground()
            nextStepButton(from: 1)
        }
    }

    // MARK: - Privacy Step (Step 2)

    private var privacyStep: some View {
        VStack(alignment: .leading, spacing: CardStyle.gap) {
            VStack(alignment: .leading, spacing: CardStyle.innerSpacing) {
                Label(language.text(.privacyLabel), systemImage: "lock.shield")
                    .font(.headline)
                Toggle(language.text(.useLLMToggle), isOn: $useLLM)
                Toggle(language.text(.enableCloudSyncToggle), isOn: $cloudSync)
                Toggle(language.text(.shareBetaAnalyticsToggle), isOn: $betaAnalytics)
                Text(language.text(.onboardingRawSamplesNote))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .cardBackground()

            VStack(alignment: .leading, spacing: CardStyle.innerSpacing) {
                Label(language.text(.aiConsentLabel), systemImage: "brain")
                    .font(.headline)
                Text(language.text(.onboardingAINote))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .cardBackground()

            nextStepButton(from: 2)
        }
    }

    // MARK: - Ready Step (Step 3)

    private var readyStep: some View {
        VStack(alignment: .leading, spacing: CardStyle.gap) {
            VStack(alignment: .leading, spacing: CardStyle.innerSpacing) {
                Label(language.text(.baselineLabel), systemImage: "chart.bar")
                    .font(.headline)
                Text(baselineMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .cardBackground()

            VStack(alignment: .leading, spacing: CardStyle.innerSpacing) {
                Label(language.text(.firstRecommendationLabel), systemImage: "sparkles")
                    .font(.headline)
                Text(firstRecommendationText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .cardBackground()

            Button {
                applyChoices()
                viewModel.completeOnboarding()
            } label: {
                Label(language.text(.startButton), systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .pressableScale()
            .padding(.top, Spacing.sm)
        }
    }

    // MARK: - Next Step Button

    private func nextStepButton(from fromStep: Int) -> some View {
        let isLastAction = fromStep == totalSteps - 2
        return Button {
            withAnimation(.spring(response: 0.44, dampingFraction: 0.86)) {
                currentStep = fromStep + 1
            }
        } label: {
            Label(
                language.text(isLastAction ? .readyButton : .continueButton),
                systemImage: "arrow.right"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .pressableScale()
    }

    /// Localized baseline status.
    private var baselineMessage: String {
        let metrics = viewModel.todayMetrics.map { [$0] } ?? []
        let recoveryDays = metrics.filter { $0.sleepHours != nil && $0.hrv != nil }.count
        return language.text(recoveryDays < 7 ? .baselineLimited : .baselineReady)
    }

    /// Show the LLM recommendation, but fall back to the localized placeholder
    /// when the LLM returns English despite a Chinese-language preference.
    private var firstRecommendationText: String {
        guard let text = viewModel.recommendationResult?.recommendation.recommendation,
              !text.isEmpty
        else { return language.text(.firstRecommendationFallback) }

        if language == .chinese, text.unicodeScalars.filter({ $0.value > 127 }).count < 5 {
            return language.text(.firstRecommendationFallback)
        }

        return text
    }

    // MARK: - Apply

    private func applyChoices() {
        viewModel.updatePrivacySettings(PrivacySettings(useLLM: useLLM))
        viewModel.recordConsent(.aiLifestyleAdvice, accepted: useLLM)
        viewModel.recordConsent(.cloudSync, accepted: cloudSync)
        viewModel.recordConsent(.betaAnalytics, accepted: betaAnalytics)
        viewModel.recordConsent(.healthKitRead, accepted: viewModel.dataSource == .appleHealth)
        viewModel.newGoalType = selectedGoal
        viewModel.newGoalTitle = language.goalType(selectedGoal)
        viewModel.newGoalDescription = language == .chinese ? "在初始设置中配置。" : "Configured during onboarding."
        viewModel.newGoalFrequency = frequency
        viewModel.addGoal()
    }
}
