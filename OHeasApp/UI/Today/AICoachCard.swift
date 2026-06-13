//
//  AICoachCard.swift
//  OHeas
//
//  AICoachCard.swift — AI coach recommendation card (streaming, stable, fallback).
//

import OHeasCore
import SwiftUI

/// The AI Coach recommendation card with streaming, stable, and fallback variants.
struct AICoachCard: View {
    let recommendationResult: RecommendationResult?
    let dataQuality: DataQualityReport?
    let detectedSignals: [HealthSignal]
    let isStreaming: Bool
    let streamingDisplayText: String
    let language: AppLanguage

    var isRefreshingRecommendation: Bool
    var feedbackJustSaved: Bool
    var onRefresh: () -> Void
    var onShowMoreDetails: () -> Void
    var onSaveFeedback: () -> Void

    // Phase 19 — Follow-up chips
    var followUpChips: [CoachFollowUpChip] = []
    var inlineResponse: CoachInlineResponse?
    var isLoadingInlineResponse: Bool = false
    var onChipTap: (CoachFollowUpChip) -> Void = { _ in }
    var onDismissInlineResponse: () -> Void = {}

    var body: some View {
        Group {
            if let result = recommendationResult {
                if isStreaming {
                    streamingCard
                } else {
                    stableCard(result: result)
                }
            } else if let quality = dataQuality {
                fallbackCard(quality: quality)
            }
        }
    }

    // MARK: - Streaming Card

    private var streamingCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(OhColor.primary.opacity(0.4))
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: Radius.tiny))

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(language.text(.generatingRecommendation))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if !streamingDisplayText.isEmpty {
                    Text(streamingDisplayText)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    + Text("|").foregroundStyle(.indigo).font(.subheadline.weight(.bold))
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.indigo.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
    }

    // MARK: - Stable Card

    private func stableCard(result: RecommendationResult) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                Rectangle()
                    .fill(OhColor.primary)
                    .frame(width: 3)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.tiny))
                    .padding(.trailing, 12)

                VStack(alignment: .leading, spacing: 14) {
                    // Header
                    HStack {
                        Label(language.text(.smallAction), systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(OhColor.success)
                        Spacer()
                        ConfidenceBadge(level: result.recommendation.confidence, language: language)
                    }

                    // What to do — elevated with indigo tinted block (iOS Journal-app style)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(language.text(.actionWhatLabel))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.indigo.opacity(0.7))
                        Text(result.recommendation.recommendation)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.indigo)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .background(Color.indigo.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: Radius.small))

                    // Tonight action
                    VStack(alignment: .leading, spacing: 4) {
                        Text(language.text(.tonightAction))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(OhColor.primary)
                        Text(result.recommendation.tonightAction)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Why
                    VStack(alignment: .leading, spacing: 4) {
                        Text(language.text(.actionWhyLabel))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(result.recommendation.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Verify tomorrow
                    if !result.recommendation.tomorrowVerification.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(language.text(.actionVerifyLabel))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            ForEach(result.recommendation.tomorrowVerification.prefix(3)) { metric in
                                HStack(spacing: 4) {
                                    Image(systemName: "circlebadge.fill").font(.system(size: 8)).foregroundStyle(.secondary)
                                    Text("\(language.verificationMetric(metric.metric)): \(language.verificationDirection(metric.expectedDirection))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    if let fallback = result.fallbackReason {
                        Label(fallback, systemImage: "info.circle")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    if result.originalRecommendation != nil || result.safetyAssessment?.riskLevel != .safe {
                        Label(language.text(.safetyAdjustedLabel), systemImage: "shield.lefthalf.filled")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    actionButtons

                    // Follow-up chips + inline response
                    if !followUpChips.isEmpty {
                        CoachFollowUpChips(
                            chips: followUpChips,
                            language: language,
                            reduceMotion: false,
                            onChipTap: onChipTap
                        )
                        .padding(.top, 4)
                    }

                    if isLoadingInlineResponse {
                        InlineResponseCard(
                            response: nil,
                            isLoading: true,
                            language: language,
                            reduceMotion: false,
                            onDismiss: onDismissInlineResponse
                        )
                        .padding(.top, 4)
                    } else if let response = inlineResponse {
                        InlineResponseCard(
                            response: response,
                            isLoading: false,
                            language: language,
                            reduceMotion: false,
                            onDismiss: onDismissInlineResponse
                        )
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color.indigo.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
        .shadow(color: .indigo.opacity(OhShadow.accentGlow.opacity), radius: OhShadow.accentGlow.radius, y: OhShadow.accentGlow.y)
    }

    // MARK: - Fallback Card

    private func fallbackCard(quality: DataQualityReport) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(OhColor.primary.opacity(0.3))
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: Radius.tiny))

            VStack(alignment: .leading, spacing: 10) {
                Label(language.text(.smallAction), systemImage: "checkmark.circle")
                    .font(.headline)
                Text(language.recommendation(quality: quality, signals: detectedSignals))
                    .font(.subheadline)
                if let question = language.followupQuestion(for: quality) {
                    Text(question)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(OhColor.primary)
                }
                actionButtons

                // Follow-up chips + inline response
                if !followUpChips.isEmpty {
                    CoachFollowUpChips(
                        chips: followUpChips,
                        language: language,
                        reduceMotion: false,
                        onChipTap: onChipTap
                    )
                    .padding(.top, 4)
                }

                if isLoadingInlineResponse {
                    InlineResponseCard(
                        response: nil,
                        isLoading: true,
                        language: language,
                        reduceMotion: false,
                        onDismiss: onDismissInlineResponse
                    )
                    .padding(.top, 4)
                } else if let response = inlineResponse {
                    InlineResponseCard(
                        response: response,
                        isLoading: false,
                        language: language,
                        reduceMotion: false,
                        onDismiss: onDismissInlineResponse
                    )
                    .padding(.top, 4)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.indigo.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                onSaveFeedback()
            } label: {
                Label(
                    feedbackJustSaved
                    ? language.text(.feedbackSavedMessage)
                    : language.text(.saveFeedbackAction),
                    systemImage: feedbackJustSaved ? "checkmark" : "square.and.pencil"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .pressableScale()
            .tint(feedbackJustSaved ? .green : nil)
            .disabled(feedbackJustSaved)

            Button {
                onRefresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .pressableScale()
            .disabled(isRefreshingRecommendation || isStreaming)
        }
        .font(.caption)
    }
}
