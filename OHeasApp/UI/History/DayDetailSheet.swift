//
//  DayDetailSheet.swift
//  OHeas
//
//  Full day detail modal sheet for a single historical day.
//  Shows score ring, contribution bars, all metrics, signals, and feedback.
//  展示某一天的完整详情 sheet。
//

import SwiftUI
import OHeasCore

// MARK: - DayDetailSheet

/// Modal sheet showing full detail for one historical day.
/// Reuses BodyBudgetRing, ContributionBar, MetricComparisonRow, SignalTags.
struct DayDetailSheet: View {
    let day: HistoricalDayDetail
    let language: AppLanguage

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header: date + category badge
                    headerSection

                    // Big score ring
                    BodyBudgetRing(
                        score: day.score,
                        language: language,
                        size: 100,
                        lineWidth: 14,
                        reduceMotion: reduceMotion
                    )
                    .frame(maxWidth: .infinity)

                    // Contribution breakdown
                    if let score = day.score, !score.factors.isEmpty {
                        ContributionBar(factors: score.factors, language: language)
                            .padding()
                            .background(OhColor.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
                    }

                    // All metrics
                    metricsSection

                    // Signals (if any)
                    if !day.signals.isEmpty {
                        signalsSection
                    }

                    // Feedback (if submitted that day)
                    feedbackSection
                }
                .padding()
            }
            .background(OhColor.groupedBg)
            .navigationTitle(language.formatDate(day.date, dateStyle: .medium, timeStyle: .none))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(language.text(.trendsDoneAction)) {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(language.text(.dayDetailScore))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let score = day.score {
                    Text("\(score.value)")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(scoreColor(score.value))
                    Text(language.budgetCategory(score.category))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(scoreColor(score.value).opacity(0.8))
                } else {
                    Text("--")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let score = day.score {
                ScoreCategoryBadge(category: score.category, language: language)
            }
        }
    }

    // MARK: - Metrics Section

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(language.text(.dayDetailMetrics), systemImage: "list.bullet.rectangle")
                .font(.subheadline.weight(.semibold))

            ForEach(day.comparisons, id: \.metric) { comparison in
                MetricComparisonRow(
                    comparison: comparison,
                    status: day.metrics.perMetricStatus[comparison.metric] ?? .valid,
                    language: language,
                    compactPadding: true,
                    cardStyle: true
                )
            }

            // Workouts (if any)
            if !day.metrics.workouts.isEmpty {
                workoutsView
            }
        }
    }

    private var workoutsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(language.metric(.workouts), systemImage: "figure.run")
                .font(.subheadline.weight(.semibold))
            ForEach(Array(day.metrics.workouts.enumerated()), id: \.offset) { _, workout in
                HStack {
                    Image(systemName: "figure.run")
                        .foregroundStyle(.pink)
                    VStack(alignment: .leading) {
                        Text(workout.type)
                            .font(.subheadline.weight(.medium))
                        Text("\(Int(workout.durationMinutes)) min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(10)
                .background(OhColor.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: Radius.small))
            }
        }
    }

    // MARK: - Signals Section

    private var signalsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(language.text(.dayDetailSignals), systemImage: "exclamationmark.triangle")
                .font(.subheadline.weight(.semibold))

            SignalTags(signals: day.signals, language: language, reduceMotion: reduceMotion)
        }
    }

    // MARK: - Feedback Section

    @ViewBuilder
    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(language.text(.dayDetailFeedback), systemImage: "hand.thumbsup")
                .font(.subheadline.weight(.semibold))

            if let fb = day.feedback {
                VStack(spacing: 8) {
                    feedbackBar(
                        label: language.text(.dayDetailEnergy),
                        value: fb.subjectiveEnergy,
                        maxValue: 10,
                        color: .yellow
                    )
                    feedbackBar(
                        label: language.text(.dayDetailSoreness),
                        value: fb.soreness,
                        maxValue: 10,
                        color: .orange,
                        inverted: true
                    )
                    feedbackBar(
                        label: language.text(.dayDetailStress),
                        value: fb.stress,
                        maxValue: 10,
                        color: .red,
                        inverted: true
                    )
                }
                .padding(12)
                .background(OhColor.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
            } else {
                Text(language.text(.dayDetailNoFeedback))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(OhColor.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
            }
        }
    }

    private func feedbackBar(label: String, value: Int?, maxValue: Int, color: Color, inverted: Bool = false) -> some View {
        let v = value ?? 0
        let fraction = CGFloat(v) / CGFloat(maxValue)
        let displayFraction = inverted ? (1.0 - fraction) : fraction

        return HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.12))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.6))
                        .frame(width: geo.size.width * displayFraction, height: 8)
                }
            }
            .frame(height: 8)

            Text("\(v)/\(maxValue)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(width: 30, alignment: .trailing)
        }
    }

    // MARK: - Helpers

    private func scoreColor(_ scoreValue: Int) -> Color {
        switch scoreValue {
        case 85...: return .green
        case 70..<85: return .mint
        case 55..<70: return .yellow
        case 35..<55: return .orange
        default: return .red
        }
    }
}
