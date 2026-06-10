//
//  OnboardingView.swift
//  OHeas
//
//  OnboardingView.swift — OHeas UI component.
//  OnboardingView.swift — OHeas UI 组件。
//


import OHeasCore
import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: OHeasViewModel
    @AppStorage("oheas.language") private var languageRawValue = AppLanguage.chinese.rawValue
    @State private var selectedGoal: UserGoalType = .buildConsistency

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .chinese
    }
    @State private var frequency: Double = 4
    @State private var useLLM = false
    @State private var cloudSync = false
    @State private var betaAnalytics = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    goalCard
                    healthKitCard
                    privacyCard
                    aiConsentCard
                    baselineCard
                    firstRecommendationCard

                    Button {
                        applyChoices()
                        viewModel.completeOnboarding()
                    } label: {
                        Label(language.text(.startButton), systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(language.text(.welcomeTitle))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(language.text(.appSubtitle))
                .font(.title.weight(.semibold))
            Text(language.text(.appDisclaimer))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(language.text(.goalSetup), systemImage: "target")
                .font(.headline)
            Picker(language.text(.goalLabel), selection: $selectedGoal) {
                ForEach(UserGoalType.allCases, id: \.self) { type in
                    Text(language.goalType(type)).tag(type)
                }
            }
            Stepper("\(language.text(.weeklyFrequency)): \(Int(frequency))", value: $frequency, in: 1...7, step: 1)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var healthKitCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(language.text(.healthKitPermission), systemImage: "heart.text.square")
                .font(.headline)
            Text(language.text(.permissionWhyDescription))
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button {
                viewModel.skipHealthKitDuringOnboarding()
            } label: {
                Label(language.text(.continueLimitedMode), systemImage: "applewatch.slash")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(language.text(.privacyLabel), systemImage: "lock.shield")
                .font(.headline)
            Toggle(language.text(.useLLMToggle), isOn: $useLLM)
            Toggle(language.text(.enableCloudSyncToggle), isOn: $cloudSync)
            Toggle(language.text(.shareBetaAnalyticsToggle), isOn: $betaAnalytics)
            Text(language.text(.onboardingRawSamplesNote))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var aiConsentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(language.text(.aiConsentLabel), systemImage: "brain")
                .font(.headline)
            Text(language.text(.onboardingAINote))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var baselineCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(language.text(.baselineLabel), systemImage: "chart.bar")
                .font(.headline)
            Text(OnboardingFlow().baselineMessage(metrics: viewModel.todayMetrics.map { [$0] } ?? []))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var firstRecommendationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(language.text(.firstRecommendationLabel), systemImage: "sparkles")
                .font(.headline)
            Text(viewModel.recommendationResult?.recommendation.recommendation ?? language.text(.firstRecommendationFallback))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func applyChoices() {
        viewModel.updatePrivacySettings(PrivacySettings(useLLM: useLLM))
        viewModel.recordConsent(.aiLifestyleAdvice, accepted: useLLM)
        viewModel.recordConsent(.cloudSync, accepted: cloudSync)
        viewModel.recordConsent(.betaAnalytics, accepted: betaAnalytics)
        viewModel.recordConsent(.healthKitRead, accepted: viewModel.dataSource == .appleHealth)
        viewModel.newGoalType = selectedGoal
        viewModel.newGoalTitle = selectedGoal.rawValue
        viewModel.newGoalDescription = "Configured during onboarding."
        viewModel.newGoalFrequency = frequency
        viewModel.addGoal()
    }
}
