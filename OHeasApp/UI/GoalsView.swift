//
//  GoalsView.swift
//  OHeas
//
//  GoalsView.swift — OHeas UI component.
//  GoalsView.swift — OHeas UI 组件。
//


import OHeasCore
import SwiftUI

struct GoalsView: View {
    @ObservedObject var viewModel: OHeasViewModel
    let language: AppLanguage

    var body: some View {
        NavigationStack {
            Form {
                Section(language.text(.activeGoals)) {
                    ForEach(viewModel.activeGoals) { goal in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(goal.title)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(language.goalType(goal.type))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(goal.description)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Button(language.text(.deactivate)) {
                                viewModel.deactivateGoal(goal)
                            }
                            .font(.footnote)
                        }
                    }
                }

                Section(language.text(.addGoal)) {
                    TextField(language.text(.titlePlaceholder), text: $viewModel.newGoalTitle)
                    TextField(language.text(.descriptionPlaceholder), text: $viewModel.newGoalDescription, axis: .vertical)
                    Picker(language.text(.goalType), selection: $viewModel.newGoalType) {
                        ForEach(UserGoalType.allCases, id: \.self) { type in
                            Text(language.goalType(type)).tag(type)
                        }
                    }
                    Stepper("\(language.text(.targetFrequency)): \(Int(viewModel.newGoalFrequency))", value: $viewModel.newGoalFrequency, in: 1...7, step: 1)
                    Button {
                        viewModel.addGoal()
                    } label: {
                        Label(language.text(.addGoal), systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle(language.text(.goalsTab))
        }
    }
}

#Preview {
    let viewModel = OHeasViewModel()
    GoalsView(viewModel: viewModel, language: .chinese)
}
