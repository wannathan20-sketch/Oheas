//
//  InsightsTabView.swift
//  OHeas
//
//  InsightsTabView.swift — OHeas UI component.
//  InsightsTabView.swift — OHeas UI 组件。
//


import OHeasCore
import SwiftUI

/// Insights tab that combines metrics comparison, effectiveness dashboard,
/// and agent context debug info into a single scrollable view.
struct InsightsTabView: View {
    @ObservedObject var viewModel: OHeasViewModel
    let language: AppLanguage
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.isLoading {
                        SkeletonSection(cardCount: 7, cardHeight: 60)
                        SkeletonSection(cardCount: 1, cardHeight: 200)
                    } else {
                        // Metrics comparison section
                        metricsSection

                        // Effectiveness dashboard section
                        effectivenessSection

                        // Agent context debug section
                        debugSection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(language.text(.insightsTab))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Metrics Section

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(language.text(.metricsTab))
                .font(.headline)

            if viewModel.comparisons.isEmpty {
                ContentUnavailableView(
                    language.text(.noMetrics),
                    systemImage: "chart.bar.xaxis",
                    description: Text(language.text(.emptyDescription))
                )
                .padding()
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach(viewModel.comparisons, id: \.metric) { comparison in
                    MetricComparisonRow(
                        comparison: comparison,
                        status: viewModel.todayMetrics?.perMetricStatus[comparison.metric] ?? .missing,
                        language: language
                    )
                }
            }

            if let workouts = viewModel.todayMetrics?.workouts, !workouts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(language.text(.workouts))
                        .font(.subheadline.weight(.semibold))
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
                .padding()
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Effectiveness Section

    private var effectivenessSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(language.text(.effectivenessTitle))
                .font(.headline)

            if let report = viewModel.effectivenessReport {
                Text(report.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    MetricTile(title: language.text(.metricAdherence), value: percent(report.recommendationAdherenceRate), icon: "checkmark.circle")
                    MetricTile(title: language.text(.metricPlanCompletion), value: percent(report.planCompletionRate), icon: "calendar.badge.checkmark")
                    MetricTile(title: language.text(.metricExperimentCompletion), value: percent(report.experimentCompletionRate), icon: "flask")
                    MetricTile(title: language.text(.metricLikelyHelped), value: percent(report.likelyHelpedRate), icon: "chart.line.uptrend.xyaxis")
                    MetricTile(title: language.text(.metricDataCoverage), value: percent(report.dataCoverageRate), icon: "applewatch")
                    MetricTile(title: language.text(.metricConfidence), value: percent(report.averageConfidence), icon: "gauge")
                }

                if !report.mostPromisingInterventions.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(language.text(.mostPromising))
                            .font(.subheadline.weight(.semibold))
                        ForEach(report.mostPromisingInterventions, id: \.self) { item in
                            Label(item, systemImage: "sparkle.magnifyingglass")
                                .font(.footnote)
                        }
                    }
                    .padding()
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if !report.weakestAreas.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(language.text(.weakestAreas))
                            .font(.subheadline.weight(.semibold))
                        ForEach(report.weakestAreas, id: \.self) { item in
                            Label(item, systemImage: "exclamationmark.triangle")
                                .font(.footnote)
                        }
                    }
                    .padding()
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            } else {
                ContentUnavailableView(language.text(.noEffectivenessReport), systemImage: "chart.bar.doc.horizontal", description: Text(language.text(.emptyDescription)))
            }
        }
    }

    // MARK: - Debug Section

    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(language.text(.debugSection))
                .font(.headline)

            NavigationLink {
                AgentContextView(viewModel: viewModel, language: language)
            } label: {
                Label(language.text(.agentTab), systemImage: "curlybraces.square")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))

#if DEBUG
            NavigationLink {
                EvaluationDebugView(viewModel: viewModel)
            } label: {
                Label(language.text(.evaluationLabel), systemImage: "checklist")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
#endif
        }
    }

    // MARK: - Helpers

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}

// MARK: - Sub-views

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
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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

private struct MetricTile: View {
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
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    let viewModel = OHeasViewModel()
    InsightsTabView(viewModel: viewModel, language: .chinese)
        .task { await viewModel.load() }
}
