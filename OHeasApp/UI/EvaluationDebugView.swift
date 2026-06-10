//
//  EvaluationDebugView.swift
//  OHeas
//
//  EvaluationDebugView.swift — OHeas UI component.
//  EvaluationDebugView.swift — OHeas UI 组件。
//


import OHeasCore
import SwiftUI

#if DEBUG
struct EvaluationDebugView: View {
    @ObservedObject var viewModel: OHeasViewModel

    @AppStorage("oheas.language") private var languageRawValue = AppLanguage.chinese.rawValue
    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .chinese
    }


    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        viewModel.runEvaluationSuite()
                    } label: {
                        Label(language.text(.evaluationLabel), systemImage: "checklist")
                    }
                }

                Section {
                    ForEach(viewModel.evaluationResults) { result in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(result.caseId)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(result.passed ? language.text(.passLabel) : language.text(.failLabel))
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(result.passed ? .green : .red)
                            }
                            Text("\(language.text(.scoreFormat)) \(Int((result.score * 100).rounded()))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ForEach(result.failures, id: \.self) { failure in
                                Text(failure)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                } header: {
                    Text(language.text(.evaluationResults))
                }

                Section {
                    ForEach(viewModel.regressionResults) { result in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(result.caseId)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(result.regressionDetected ? language.text(.regressionLabel) : (result.changed ? language.text(.changedLabel) : language.text(.stableLabel)))
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(result.regressionDetected ? .red : .secondary)
                            }
                            ForEach(result.differences, id: \.self) { difference in
                                Text(difference)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text(language.text(.promptRegression))
                }
            }
            .navigationTitle(language.text(.evaluationNavTitle))
        }
    }
}
#endif
