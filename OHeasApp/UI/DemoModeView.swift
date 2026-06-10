//
//  DemoModeView.swift
//  OHeas
//
//  DemoModeView.swift — OHeas UI component.
//  DemoModeView.swift — OHeas UI 组件。
//


import OHeasCore
import SwiftUI

#if DEBUG
struct DemoModeView: View {
    @ObservedObject var viewModel: OHeasViewModel

    @AppStorage("oheas.language") private var languageRawValue = AppLanguage.chinese.rawValue
    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .chinese
    }


    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(language.text(.scenario), selection: $viewModel.selectedDemoScenario) {
                        ForEach(DemoScenario.allCases) { scenario in
                            Text(scenario.title).tag(scenario)
                        }
                    }

                    Text(viewModel.selectedDemoScenario.summary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button {
                        viewModel.loadDemoScenario()
                    } label: {
                        Label(language.text(.loadDemoScenario), systemImage: "play.circle")
                    }
                    .buttonStyle(.borderedProminent)

                    Button(role: .destructive) {
                        viewModel.resetDemoData()
                    } label: {
                        Label(language.text(.resetDemoData), systemImage: "trash")
                    }
                } header: {
                    Text(language.text(.demoScenarioBuilder))
                } footer: {
                    Text(language.text(.demoDescription))
                }

                Section {
                    LabeledContent(language.text(.modeLabel), value: viewModel.isDemoMode ? language.text(.demoValue) : language.text(.liveMockValue))
                    if let summary = viewModel.demoScenarioSummary {
                        Text(summary)
                            .font(.subheadline)
                    }
                    LabeledContent(language.text(.metricDays), value: "\(viewModel.todayMetrics == nil ? 0 : 30)")
                    LabeledContent(language.text(.experimentsLabel), value: "\(viewModel.experimentHistory.count)")
                    LabeledContent(language.text(.planDays), value: "\(viewModel.currentWeeklyPlan?.days.count ?? 0)")
                } header: {
                    Text(language.text(.currentDemo))
                }
            }
            .navigationTitle(language.text(.demoNavTitle))
        }
    }
}
#endif
