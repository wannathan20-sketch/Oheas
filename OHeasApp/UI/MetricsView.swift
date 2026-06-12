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
                            language: language,
                            compactPadding: true
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

#Preview {
    let viewModel = OHeasViewModel()
    MetricsView(viewModel: viewModel, language: .chinese)
        .task { await viewModel.load() }
}
