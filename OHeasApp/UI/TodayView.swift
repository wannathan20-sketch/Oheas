//
//  TodayView.swift
//  OHeas
//
//  TodayView.swift — main Today tab, Phase 18 restructured for score-first progressive disclosure.
//
//  Scroll order: Header (score + insight) → Coach → Feedback → Metrics → Plan → Details.
//  All content directly visible — no DisclosureGroup nesting.
//

import OHeasCore
import SwiftUI

// MARK: - TodayView

struct TodayView: View {
    @ObservedObject var viewModel: OHeasViewModel
    let language: AppLanguage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isRefreshingRecommendation = false
    @State private var feedbackJustSaved = false
    @AppStorage("oheas.aiEnabled") private var aiEnabled = true
    /// When set, navigates to Chat tab with a pre-filled prompt.
    var onNavigateToChat: ((String) -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // 0. Mock-mode diagnostic banner (only when HealthKit failed)
                    if viewModel.dataSource != .appleHealth, let error = viewModel.healthKitError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(language.text(.mockFallback))
                                    .font(.caption.weight(.semibold))
                                Text(error)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }

                    // 1. Score-first header — big ring + insight
                    if let today = viewModel.todayMetrics, let quality = viewModel.dataQuality {
                        TodaySummaryHeader(
                            score: viewModel.bodyBudgetScore,
                            today: today,
                            quality: quality,
                            detectedSignals: viewModel.detectedSignals,
                            dataSource: viewModel.dataSource,
                            language: language,
                            reduceMotion: reduceMotion,
                            checkInStreak: viewModel.gamificationSnapshot?.streaks[.checkIn]?.currentStreak ?? 0
                        )
                    } else if viewModel.isLoading {
                        SkeletonLoadingView(sections: [(1, 200)])
                    } else {
                        ContentUnavailableView(
                            language.text(.emptyTitle),
                            systemImage: "heart.text.square",
                            description: Text(language.text(.emptyDescription))
                        )
                        .padding(.vertical, 48)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        if let today = viewModel.todayMetrics, let quality = viewModel.dataQuality {
                            // 2. AI Coach recommendation
                            AICoachCard(
                                recommendationResult: viewModel.recommendationResult,
                                dataQuality: viewModel.dataQuality,
                                detectedSignals: viewModel.detectedSignals,
                                isStreaming: viewModel.isStreaming,
                                streamingDisplayText: viewModel.streamingDisplayText,
                                language: language,
                                isRefreshingRecommendation: isRefreshingRecommendation,
                                feedbackJustSaved: feedbackJustSaved,
                                onRefresh: refreshRecommendation,
                                onShowMoreDetails: { /* No-op: content is directly visible below */ },
                                onSaveFeedback: saveFeedback,
                                followUpChips: viewModel.followUpChips,
                                inlineResponse: viewModel.inlineResponse,
                                isLoadingInlineResponse: viewModel.isLoadingInlineResponse,
                                onChipTap: { chip in
                                    switch chip.action {
                                    case .askQuestion:
                                        viewModel.handleChipTap(chip, aiEnabled: aiEnabled)
                                    case .navigateToChat:
                                        onNavigateToChat?(chip.action.promptText)
                                    }
                                },
                                onDismissInlineResponse: { viewModel.dismissInlineResponse() }
                            )
                            .softAppear(true, delay: 0.04, reduceMotion: reduceMotion)

                            // 3. Quick feedback + yesterday — directly visible
                            TodayFeedbackPanel(
                                yesterdayRecommendation: viewModel.yesterdayRecommendation,
                                yesterdayFeedback: viewModel.yesterdayFeedback,
                                verificationReport: viewModel.verificationReport,
                                language: language,
                                feedbackJustSaved: feedbackJustSaved,
                                feedbackAdherence: $viewModel.feedbackAdherence,
                                feedbackEnergy: $viewModel.feedbackEnergy,
                                feedbackSoreness: $viewModel.feedbackSoreness,
                                feedbackStress: $viewModel.feedbackStress,
                                feedbackNote: $viewModel.feedbackNote,
                                onSaveFeedback: { viewModel.saveFeedback() }
                            )
                            .softAppear(true, delay: 0.08, reduceMotion: reduceMotion)

                            // 4. Recovery metrics + contribution breakdown
                            BodyBudgetGauge(
                                score: viewModel.bodyBudgetScore,
                                today: today,
                                quality: quality,
                                detectedSignals: viewModel.detectedSignals,
                                recentDailyMetrics: viewModel.recentDailyMetrics,
                                language: language
                            )
                            .softAppear(true, delay: 0.12, reduceMotion: reduceMotion)

                            // 5. Weekly plan strip
                            WeeklyPlanStrip(
                                currentWeeklyPlan: viewModel.currentWeeklyPlan,
                                todayDailyPlan: viewModel.todayDailyPlan,
                                language: language
                            )
                            .softAppear(true, delay: 0.16, reduceMotion: reduceMotion)

                            // 6. Metrics grid
                            if !viewModel.comparisons.isEmpty {
                                TodayMetricsGrid(
                                    comparisons: viewModel.comparisons,
                                    todayMetrics: viewModel.todayMetrics,
                                    recentDailyMetrics: viewModel.recentDailyMetrics,
                                    language: language
                                )
                                .softAppear(true, delay: 0.20, reduceMotion: reduceMotion)
                            }

                            // 7. Signal tags — directly visible when present
                            if !viewModel.detectedSignals.isEmpty {
                                SignalTags(
                                    signals: viewModel.detectedSignals,
                                    language: language,
                                    reduceMotion: reduceMotion
                                )
                                .softAppear(true, delay: 0.24, reduceMotion: reduceMotion)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .background(OhColor.groupedBg)
            .navigationTitle("OHeas")
            .navigationBarTitleDisplayMode(.inline)
            .animation(OhAnimation.appear(), value: viewModel.isLoading)
            .animation(OhAnimation.appear(), value: viewModel.detectedSignals.count)
            .overlay {
                if viewModel.showCelebration {
                    CelebrationEffect(
                        show: $viewModel.showCelebration,
                        badgeName: viewModel.celebrationBadgeName,
                        language: language
                    )
                    .zIndex(100)
                }
            }
        }
    }

    // MARK: - Actions

    private func refreshRecommendation() {
        guard !isRefreshingRecommendation else { return }
        isRefreshingRecommendation = true
        Task {
            await viewModel.refreshRecommendation(aiEnabled: aiEnabled)
            await MainActor.run {
                withAnimation(OhAnimation.stagger()) { isRefreshingRecommendation = false }
            }
        }
    }

    private func saveFeedback() {
        viewModel.saveFeedback()
        feedbackJustSaved = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation(OhAnimation.tab()) { feedbackJustSaved = false }
            }
        }
    }
}

// MARK: - Score Slider

struct ScoreSlider: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.subheadline)
                Spacer()
                Text("\(Int(value.rounded()))/10")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: 1...10, step: 1)
        }
    }
}

#Preview {
    let vm = OHeasViewModel()
    TodayView(viewModel: vm, language: .chinese, onNavigateToChat: { _ in })
        .task { await vm.load() }
}
