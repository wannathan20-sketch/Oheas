//
//  MetricComponents.swift
//  OHeas
//
//  MetricComponents.swift — shared metric display components.
//  Extracted from duplicated private definitions in:
//    - EffectivenessDashboardView.swift (MetricTile)
//    - InsightsTabView.swift (MetricTile, MetricComparisonRow)
//    - SettingsView.swift (EffectivenessMetricTile)
//    - MetricsView.swift (MetricComparisonRow)
//

import OHeasCore
import SwiftUI

// MARK: - Metric Icons & Colors

/// SF Symbol name for a health metric.
func metricIcon(_ metric: HealthMetric, filled: Bool = true) -> String {
    switch metric {
    case .sleepHours: filled ? "bed.double.fill" : "bed.double"
    case .hrv: "waveform.path.ecg"
    case .restingHeartRate: filled ? "heart.fill" : "heart"
    case .steps: "figure.walk"
    case .activeEnergyKcal: filled ? "flame.fill" : "flame"
    case .exerciseMinutes: "timer"
    case .workouts: "figure.run"
    }
}

/// Semantic color for a health metric category.
func metricColor(_ metric: HealthMetric) -> Color {
    switch metric {
    case .sleepHours: OhColor.sleep
    case .hrv: OhColor.hrv
    case .restingHeartRate: OhColor.restingHR
    case .steps: OhColor.steps
    case .activeEnergyKcal: OhColor.activeEnergy
    case .exerciseMinutes: OhColor.exercise
    case .workouts: OhColor.workouts
    }
}

// MARK: - Metric Tile

/// A simple metric card showing a label, icon, and value.
/// Used in effectiveness dashboards and insights.
struct MetricTile: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: Radius.small))
    }
}

// MARK: - Metric Comparison Row

/// A detailed row comparing today's metric value against baseline.
/// Used in metrics views and insights.
struct MetricComparisonRow: View {
    let comparison: MetricComparison
    let status: MetricStatus
    let language: AppLanguage
    var compactPadding: Bool = false
    var cardStyle: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: metricIcon(comparison.metric, filled: false))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(language.status(status))
                    .font(.caption)
                    .foregroundStyle(statusColor)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(valueString(comparison.todayValue))
                    .font(.title3.weight(.semibold))
                Text(comparison.unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(language.text(.baseline)) \(valueString(comparison.baselineValue))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(deltaText)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(deltaColor)
                }
            }
        }
        .modifier(ConditionalPadding(compact: compactPadding))
        .if(cardStyle) {
            $0.background(.background)
              .clipShape(RoundedRectangle(cornerRadius: Radius.small))
        }
    }

    // MARK: - Helpers

    private var title: String { language.metric(comparison.metric) }

    private var statusColor: Color { status == .valid ? .secondary : .orange }

    private var deltaText: String {
        guard let absolute = comparison.absoluteDelta else { return language.text(.deltaUnavailable) }
        if comparison.metric == .restingHeartRate {
            return "\(absolute >= 0 ? "+" : "")\(absolute.formatted(.number.precision(.fractionLength(1)))) bpm"
        }
        guard let percent = comparison.percentageDelta else {
            return "\(absolute >= 0 ? "+" : "")\(absolute.formatted(.number.precision(.fractionLength(1))))"
        }
        return "\(percent >= 0 ? "+" : "")\(percent.formatted(.number.precision(.fractionLength(0))))%"
    }

    private var deltaColor: Color {
        guard let delta = comparison.absoluteDelta else { return .secondary }
        switch comparison.metric {
        case .sleepHours, .hrv, .steps, .activeEnergyKcal, .exerciseMinutes:
            return delta < 0 ? .orange : .green
        case .restingHeartRate:
            return delta > 0 ? .orange : .green
        case .workouts:
            return .secondary
        }
    }

    private func valueString(_ number: Double?) -> String {
        guard let number else { return language.missing }
        if comparison.metric == .steps {
            return number.formatted(.number.precision(.fractionLength(0)).grouping(.automatic))
        }
        return number.formatted(.number.precision(.fractionLength(1)))
    }
}

// MARK: - Helpers

private struct ConditionalPadding: ViewModifier {
    let compact: Bool
    func body(content: Content) -> some View {
        if compact {
            content.padding(.vertical, 4)
        } else {
            content.padding()
        }
    }
}

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
