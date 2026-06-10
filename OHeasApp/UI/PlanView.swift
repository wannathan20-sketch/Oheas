//
//  PlanView.swift
//  OHeas
//
//  PlanView.swift — OHeas UI component.
//  PlanView.swift — OHeas UI 组件。
//


import OHeasCore
import SwiftUI

struct PlanView: View {
    @ObservedObject var viewModel: OHeasViewModel
    let language: AppLanguage

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let today = viewModel.todayDailyPlan {
                        planCard(today, title: language.text(.todayPlan), highlighted: true)
                    }

                    if let plan = viewModel.currentWeeklyPlan {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(language.text(.weeklyPlan))
                                    .font(.headline)
                                Spacer()
                                Button {
                                    viewModel.regenerateWeeklyPlan()
                                } label: {
                                    Label(language.text(.regeneratePlan), systemImage: "arrow.clockwise")
                                }
                                .font(.caption)
                            }
                            Text(plan.strategySummary)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            ForEach(plan.days) { day in
                                planCard(day, title: day.date.formatted(date: .abbreviated, time: .omitted), highlighted: false)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(language.text(.planTab))
        }
    }

    private func planCard(_ day: DailyPlan, title: String, highlighted: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(highlighted ? .headline : .subheadline.weight(.semibold))
                Spacer()
                Text(language.planType(day.planType))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Text(day.title)
                .font(.subheadline.weight(.semibold))
            Text(day.description)
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack {
                Label("\(day.estimatedDurationMinutes) \(language.text(.minUnit))", systemImage: "timer")
                Label(day.intensity.rawValue.replacingOccurrences(of: "_", with: " "), systemImage: "gauge")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let reason = day.adjustmentReason {
                Text("\(language.text(.adjusted)): \(reason)")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }

            if day.safetyNote?.localizedCaseInsensitiveContains("Adjusted for safety") == true || day.adjustmentReason?.localizedCaseInsensitiveContains("Safety guardrail") == true {
                Label(language.text(.safetyAdjustedLabel), systemImage: "shield.lefthalf.filled")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button(language.text(.markCompleted)) {
                    viewModel.updateDailyPlanStatus(day, status: .completed)
                }
                .buttonStyle(.bordered)

                Button(language.text(.markSkipped)) {
                    viewModel.updateDailyPlanStatus(day, status: .skipped)
                }
                .buttonStyle(.bordered)

                Spacer()

                Menu {
                    ForEach(DailyPlanType.allCases, id: \.self) { type in
                        Button(language.planType(type)) {
                            viewModel.replaceDailyPlan(day, type: type, duration: day.estimatedDurationMinutes)
                        }
                    }
                } label: {
                    Label(language.text(.adjustLabel), systemImage: "slider.horizontal.3")
                }
                .font(.caption)

                HStack(spacing: 6) {
                    Button {
                        viewModel.replaceDailyPlan(day, type: day.planType, duration: max(5, day.estimatedDurationMinutes - 5))
                    } label: {
                        Image(systemName: "minus")
                    }

                    Button {
                        viewModel.replaceDailyPlan(day, type: day.planType, duration: day.estimatedDurationMinutes + 5)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                .buttonStyle(.bordered)
                .font(.caption)
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    let viewModel = OHeasViewModel()
    PlanView(viewModel: viewModel, language: .chinese)
}
