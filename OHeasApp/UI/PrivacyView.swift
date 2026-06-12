//
//  PrivacyView.swift
//  OHeas
//
//  PrivacyView.swift — OHeas UI component.
//  PrivacyView.swift — OHeas UI 组件。
//


import OHeasCore
import SwiftUI

struct PrivacyView: View {
    @ObservedObject var viewModel: OHeasViewModel

    @AppStorage("oheas.language") private var languageRawValue = AppLanguage.chinese.rawValue
    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .chinese
    }

    @State private var draft: PrivacySettings = .defaults

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(language.text(.useLLMToggle), isOn: $draft.useLLM)
                    Toggle(language.text(.shareAggregatedMetricsToggle), isOn: $draft.shareAggregatedMetricsWithLLM)
                    Toggle(language.text(.shareMemorySummaryToggle), isOn: $draft.shareMemorySummaryWithLLM)
                    Toggle(language.text(.shareExperimentSummaryToggle), isOn: $draft.shareExperimentSummaryWithLLM)
                    Toggle(language.text(.sharePlanSummaryToggle), isOn: $draft.sharePlanSummaryWithLLM)
                    Toggle(language.text(.shareFeedbackSummaryToggle), isOn: $draft.shareFeedbackWithLLM)
                    Toggle(language.text(.allowRawHealthSamplesToggle), isOn: $draft.allowRawHealthSamples)
                } header: {
                    Text(language.text(.llmDataControls))
                } footer: {
                    Text(language.text(.privacyLLMDescription))
                }

                Section {
                    Button {
                        viewModel.updatePrivacySettings(draft)
                    } label: {
                        Label(language.text(.savePrivacySettings), systemImage: "lock.shield")
                    }

                    Button(role: .destructive) {
                        viewModel.resetPrivacySettings()
                        draft = viewModel.privacySettings
                    } label: {
                        Label(language.text(.resetDefaults), systemImage: "arrow.counterclockwise")
                    }
                }

                Section {
                    Text(language.text(.privacyPolicyDescription))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text(language.text(.policyLabel))
                }
            }
            .navigationTitle(language.text(.privacyNavTitle))
            .onAppear {
                draft = viewModel.privacySettings
            }
        }
    }
}
