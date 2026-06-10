//
//  PlanTabView.swift
//  OHeas
//
//  PlanTabView.swift — OHeas UI component.
//  PlanTabView.swift — OHeas UI 组件。
//


import OHeasCore
import SwiftUI

/// Plan tab that combines weekly plan, goals, experiments, and weekly review
/// into a single NavigationStack-based hub.
struct PlanTabView: View {
    @ObservedObject var viewModel: OHeasViewModel
    let language: AppLanguage
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Quick-access navigation row (always visible)
                    quickActions

                    if viewModel.isLoading {
                        SkeletonSection(cardCount: 1, cardHeight: 100)
                        SkeletonSection(cardCount: 7, cardHeight: 120)
                    } else if viewModel.todayDailyPlan != nil || viewModel.currentWeeklyPlan != nil {
                        // Today's plan
                        if let today = viewModel.todayDailyPlan {
                            planCard(today, title: language.text(.todayPlan), highlighted: true)
                        }

                        // Weekly plan
                        if let plan = viewModel.currentWeeklyPlan {
                            weeklySection(plan)
                        }
                    } else {
                        ContentUnavailableView(
                            language.text(.emptyPlanTitle),
                            systemImage: "calendar.badge.plus",
                            description: Text(language.text(.emptyPlanDescription))
                        )
                        .padding(.vertical, 48)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(language.text(.planTab))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: 12) {
            NavigationLink {
                GoalsView(viewModel: viewModel, language: language)
            } label: {
                Label(language.text(.goalsTab), systemImage: "target")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)

            NavigationLink {
                ExperimentsView(viewModel: viewModel, language: language)
            } label: {
                Label(language.text(.experimentsTab), systemImage: "flask")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)

            if viewModel.weeklyReview != nil {
                NavigationLink {
                    WeeklyReviewView(viewModel: viewModel, language: language)
                } label: {
                    Label(language.text(.weeklyReviewTab), systemImage: "chart.pie")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Weekly Section

    private func weeklySection(_ plan: WeeklyPlan) -> some View {
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

    // MARK: - Plan Card

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
    PlanTabView(viewModel: viewModel, language: .chinese)
        .task { await viewModel.load() }
}
