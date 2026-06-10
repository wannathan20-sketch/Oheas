//
//  ExperimentsView.swift
//  OHeas
//
//  ExperimentsView.swift — OHeas UI component.
//  ExperimentsView.swift — OHeas UI 组件。
//


import OHeasCore
import SwiftUI

struct ExperimentsView: View {
    @ObservedObject var viewModel: OHeasViewModel
    let language: AppLanguage

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let active = viewModel.activeExperiment {
                        activeExperimentCard(active)
                    }

                    if let proposed = viewModel.proposedExperiment, viewModel.activeExperiment == nil {
                        proposedExperimentCard(proposed)
                    }

                    historySection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(language.text(.experimentsTab))
        }
    }

    private func activeExperimentCard(_ experiment: PersonalExperiment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(language.text(.activeExperiment))
                .font(.headline)
            experimentSummary(experiment)

            ProgressView(value: progress(experiment))
            Text("\(experiment.dailyCheckins.count)/\(experiment.durationDays)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Toggle(language.text(.completedToday), isOn: $viewModel.experimentCheckinCompleted)
            ScoreSlider(title: language.text(.energy), value: $viewModel.experimentCheckinEnergy)
            TextField(language.text(.note), text: $viewModel.experimentCheckinNote, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)

            Button {
                viewModel.saveExperimentCheckin()
            } label: {
                Label(language.text(.saveCheckin), systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            HStack {
                Button(language.text(.pauseExperiment)) {
                    viewModel.pauseActiveExperiment()
                }
                .buttonStyle(.bordered)

                Button(language.text(.completeExperiment)) {
                    viewModel.completeActiveExperiment()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func proposedExperimentCard(_ experiment: PersonalExperiment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(language.text(.proposedExperiment))
                .font(.headline)
            experimentSummary(experiment)
            Button {
                viewModel.startProposedExperiment()
            } label: {
                Label(language.text(.startExperiment), systemImage: "play.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func experimentSummary(_ experiment: PersonalExperiment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(experiment.title)
                .font(.subheadline.weight(.semibold))
            labeled(language.text(.hypothesis), experiment.hypothesis)
            labeled(language.text(.intervention), experiment.intervention)
            labeled(language.text(.whyExperiment), experiment.whyThisExperiment)
            labeled(language.text(.targetMetrics), experiment.targetMetrics.joined(separator: ", "))
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(language.text(.experimentHistory))
                .font(.headline)

            let completed = viewModel.experimentHistory.filter { $0.status == .completed }
            if completed.isEmpty {
                Text(language.text(.noExperiments))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(completed) { experiment in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(experiment.title)
                            .font(.subheadline.weight(.semibold))
                        if let result = experiment.result {
                            Text(language.verificationOutcome(result.outcome))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                            Text(result.summary)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func labeled(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.footnote)
        }
    }

    private func progress(_ experiment: PersonalExperiment) -> Double {
        guard experiment.durationDays > 0 else { return 0 }
        return min(1, Double(experiment.dailyCheckins.count) / Double(experiment.durationDays))
    }
}

#Preview {
    let viewModel = OHeasViewModel()
    ExperimentsView(viewModel: viewModel, language: .chinese)
        .task { await viewModel.load() }
}
