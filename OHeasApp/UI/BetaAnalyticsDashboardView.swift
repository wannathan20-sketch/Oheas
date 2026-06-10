//
//  BetaAnalyticsDashboardView.swift
//  OHeas
//
//  BetaAnalyticsDashboardView.swift — OHeas UI component.
//  BetaAnalyticsDashboardView.swift — OHeas UI 组件。
//


import SwiftUI

struct BetaAnalyticsDashboardView: View {
    @ObservedObject var viewModel: OHeasViewModel

    @AppStorage("oheas.language") private var languageRawValue = AppLanguage.chinese.rawValue
    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .chinese
    }


    var body: some View {
        Form {
            Section {
                Button {
                    viewModel.refreshAnalyticsSummary()
                } label: {
                    Label(language.text(.refresh), systemImage: "arrow.clockwise")
                }
            }

            Section {
                LabeledContent(language.text(.appOpens), value: "\(viewModel.analyticsSummary.appOpenCount)")
                LabeledContent(language.text(.recommendationsLabel), value: "\(viewModel.analyticsSummary.recommendationGeneratedCount)")
                LabeledContent(language.text(.feedbackRate), value: percent(viewModel.analyticsSummary.feedbackRate))
                LabeledContent(language.text(.experimentCheckins), value: "\(viewModel.analyticsSummary.experimentCheckinCount)")
                LabeledContent(language.text(.safetyFlags), value: "\(viewModel.analyticsSummary.safetyFlagCount)")
                LabeledContent(language.text(.fallbacksLabel), value: "\(viewModel.analyticsSummary.fallbackCount)")
                LabeledContent(language.text(.syncFailures), value: "\(viewModel.analyticsSummary.syncFailureCount)")
            } header: {
                Text(language.text(.localBetaAnalytics))
            } footer: {
                Text(language.text(.analyticsDescription))
            }
        }
        .navigationTitle(language.text(.betaAnalyticsNavTitle))
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}
