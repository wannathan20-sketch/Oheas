//
//  EffectivenessDashboardView.swift
//  OHeas
//
//  EffectivenessDashboardView.swift — OHeas UI component.
//  EffectivenessDashboardView.swift — OHeas UI 组件。
//


import OHeasCore
import SwiftUI

struct EffectivenessDashboardView: View {
    @ObservedObject var viewModel: OHeasViewModel

    @AppStorage("oheas.language") private var languageRawValue = AppLanguage.chinese.rawValue
    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .chinese
    }


    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
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

                        SectionCard(title: language.text(.mostPromising)) {
                            ForEach(report.mostPromisingInterventions, id: \.self) { item in
                                Label(item, systemImage: "sparkle.magnifyingglass")
                                    .font(.footnote)
                            }
                        }

                        SectionCard(title: language.text(.weakestAreas)) {
                            ForEach(report.weakestAreas, id: \.self) { item in
                                Label(item, systemImage: "exclamationmark.triangle")
                                    .font(.footnote)
                            }
                        }
                    } else {
                        ContentUnavailableView(language.text(.noEffectivenessReport), systemImage: "chart.bar.doc.horizontal", description: Text(language.text(.noEffectivenessDescription)))
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(language.text(.effectivenessTitle))
        }
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
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

private struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
