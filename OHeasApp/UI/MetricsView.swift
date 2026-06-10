//
//  MetricsView.swift
//  OHeas
//
//  MetricsView.swift — OHeas UI component.
//  MetricsView.swift — OHeas UI 组件。
//


import OHeasCore
import SwiftUI

struct MetricsView: View {
    @ObservedObject var viewModel: OHeasViewModel
    let language: AppLanguage

    var body: some View {
        NavigationStack {
            List {
                Section(language.text(.todayVsBaseline)) {
                    ForEach(viewModel.comparisons, id: \.metric) { comparison in
                        MetricComparisonRow(
                            comparison: comparison,
                            status: viewModel.todayMetrics?.perMetricStatus[comparison.metric] ?? .missing,
                            language: language
                        )
                    }
                }

                if let workouts = viewModel.todayMetrics?.workouts, !workouts.isEmpty {
                    Section(language.text(.workouts)) {
                        ForEach(workouts) { workout in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(workout.type)
                                    .font(.subheadline.weight(.semibold))
                                Text("\(workout.durationMinutes.formatted(.number.precision(.fractionLength(0)))) \(language.minuteUnit)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(language.text(.metricsTab))
        }
    }
}

private struct MetricComparisonRow: View {
    let comparison: MetricComparison
    let status: MetricStatus
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(language.status(status))
                    .font(.caption)
                    .foregroundStyle(statusColor)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(value(comparison.todayValue))
                    .font(.title3.weight(.semibold))
                Text(comparison.unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(language.text(.baseline)) \(value(comparison.baselineValue))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(deltaText)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(deltaColor)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var title: String {
        language.metric(comparison.metric)
    }

    private var icon: String {
        switch comparison.metric {
        case .sleepHours: "bed.double"
        case .hrv: "waveform.path.ecg"
        case .restingHeartRate: "heart"
        case .steps: "figure.walk"
        case .activeEnergyKcal: "flame"
        case .exerciseMinutes: "timer"
        case .workouts: "figure.run"
        }
    }

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

    private var statusColor: Color {
        status == .valid ? .secondary : .orange
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

    private func value(_ number: Double?) -> String {
        guard let number else { return language.missing }
        if comparison.metric == .steps {
            return number.formatted(.number.precision(.fractionLength(0)).grouping(.automatic))
        }
        return number.formatted(.number.precision(.fractionLength(1)))
    }
}

#Preview {
    let viewModel = OHeasViewModel()
    MetricsView(viewModel: viewModel, language: .chinese)
        .task { await viewModel.load() }
}
