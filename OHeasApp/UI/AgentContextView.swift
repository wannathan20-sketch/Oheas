//
//  AgentContextView.swift
//  OHeas
//
//  AgentContextView.swift — OHeas UI component.
//  AgentContextView.swift — OHeas UI 组件。
//


import OHeasCore
import SwiftUI

struct AgentContextView: View {
    @ObservedObject var viewModel: OHeasViewModel
    let language: AppLanguage
    @State private var mode = AgentDebugMode.context

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker(language.text(.debugPicker), selection: $mode) {
                    ForEach(AgentDebugMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                ScrollView {
                    Text(debugText)
                        .font(.system(.footnote, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding()
                }
                .background(Color(.secondarySystemGroupedBackground))
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(language.text(.agentTab))
        }
    }

    private var debugText: String {
        switch mode {
        case .context:
            return viewModel.promptPayload?.userContextJSON ?? language.text(.contextNotReady)
        case .prompt:
            guard let payload = viewModel.promptPayload else { return language.text(.promptNotReady) }
            return """
            SYSTEM PROMPT
            \(payload.systemPrompt)

            USER CONTEXT
            \(payload.userContextJSON)
            """
        case .raw:
            return viewModel.recommendationResult?.rawResponse ?? viewModel.recommendationResult?.fallbackReason ?? "No raw LLM response."
        case .parsed:
            guard let recommendation = viewModel.recommendationResult?.recommendation else {
                return "Parsed recommendation is not ready."
            }
            let data = try? JSONEncoder.oheasPretty.encode(recommendation)
            return data.flatMap { String(data: $0, encoding: .utf8) } ?? "Parsed recommendation is not ready."
        case .fallback:
            return viewModel.recommendationResult?.fallbackReason ?? "No fallback was used."
        case .memory:
            let data = try? JSONEncoder.oheasPretty.encode(viewModel.userMemory)
            return data.flatMap { String(data: $0, encoding: .utf8) } ?? "Memory is not ready."
        case .patterns:
            let data = try? JSONEncoder.oheasPretty.encode(viewModel.patternCandidates)
            return data.flatMap { String(data: $0, encoding: .utf8) } ?? "Pattern candidates are not ready."
        case .experiment:
            let data = try? JSONEncoder.oheasPretty.encode(viewModel.activeExperiment ?? viewModel.proposedExperiment)
            return data.flatMap { String(data: $0, encoding: .utf8) } ?? "Experiment is not ready."
        case .experimentResult:
            let results = viewModel.experimentHistory.compactMap(\.result)
            let data = try? JSONEncoder.oheasPretty.encode(results)
            return data.flatMap { String(data: $0, encoding: .utf8) } ?? "Experiment results are not ready."
        case .goals:
            let data = try? JSONEncoder.oheasPretty.encode(viewModel.activeGoals)
            return data.flatMap { String(data: $0, encoding: .utf8) } ?? "Goals are not ready."
        case .plan:
            let data = try? JSONEncoder.oheasPretty.encode(viewModel.currentWeeklyPlan)
            return data.flatMap { String(data: $0, encoding: .utf8) } ?? "Weekly plan is not ready."
        case .todayPlan:
            let data = try? JSONEncoder.oheasPretty.encode(viewModel.todayDailyPlan)
            return data.flatMap { String(data: $0, encoding: .utf8) } ?? "Today plan is not ready."
        case .reminders:
            let data = try? JSONEncoder.oheasPretty.encode(viewModel.scheduledReminders)
            return data.flatMap { String(data: $0, encoding: .utf8) } ?? "Reminders are not ready."
        case .weeklyReview:
            let data = try? JSONEncoder.oheasPretty.encode(viewModel.weeklyReview)
            return data.flatMap { String(data: $0, encoding: .utf8) } ?? "Weekly review is not ready."
        case .privacy:
            return """
            SETTINGS
            \(encoded(viewModel.privacySettings))

            SANITIZED PAYLOAD PREVIEW
            \(viewModel.privacyPayloadPreview)
            """
        case .safety:
            return encoded(viewModel.safetyAssessments)
        case .evaluation:
            return encoded(viewModel.evaluationResults)
        case .regression:
            return encoded(viewModel.regressionResults)
        case .errors:
            return encoded(viewModel.recentErrors)
        case .sync:
            return encoded(viewModel.syncState)
        case .analytics:
            return encoded(viewModel.analyticsSummary)
        case .betaReadiness:
            guard let report = viewModel.betaReadinessReport else {
                return "Beta readiness report is not ready."
            }
            return encoded(report)
        }
    }

    private func encoded<T: Encodable>(_ value: T) -> String {
        let data = try? JSONEncoder.oheasPretty.encode(value)
        return data.flatMap { String(data: $0, encoding: .utf8) } ?? "Not ready."
    }
}

private enum AgentDebugMode: CaseIterable {
    case context
    case prompt
    case raw
    case parsed
    case fallback
    case memory
    case patterns
    case experiment
    case experimentResult
    case goals
    case plan
    case todayPlan
    case reminders
    case weeklyReview
    case privacy
    case safety
    case evaluation
    case regression
    case errors
    case sync
    case analytics
    case betaReadiness

    var title: String {
        switch self {
        case .context: "JSON"
        case .prompt: "Prompt"
        case .raw: "Raw"
        case .parsed: "Parsed"
        case .fallback: "Fallback"
        case .memory: "Memory"
        case .patterns: "Patterns"
        case .experiment: "Experiment"
        case .experimentResult: "Results"
        case .goals: "Goals"
        case .plan: "Plan"
        case .todayPlan: "Today Plan"
        case .reminders: "Reminders"
        case .weeklyReview: "Week Review"
        case .privacy: "Privacy"
        case .safety: "Safety"
        case .evaluation: "Eval"
        case .regression: "Regression"
        case .errors: "Errors"
        case .sync: "Sync"
        case .analytics: "Analytics"
        case .betaReadiness: "Beta Readiness"
        }
    }
}

#Preview {
    let viewModel = OHeasViewModel()
    AgentContextView(viewModel: viewModel, language: .chinese)
        .task { await viewModel.load() }
}
