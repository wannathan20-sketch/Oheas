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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isRegenerating = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Quick-access navigation row (always visible)
                    quickActions
                        .softAppear(true, delay: 0.02, reduceMotion: reduceMotion)

                    if viewModel.isLoading || isRegenerating {
                        SkeletonSection(cardCount: 1, cardHeight: 100)
                        SkeletonSection(cardCount: 7, cardHeight: 120)
                    } else if viewModel.todayDailyPlan != nil || viewModel.currentWeeklyPlan != nil {
                        // Today's plan
                        if let today = viewModel.todayDailyPlan {
                            planCard(today, title: language.text(.todayPlan), highlighted: true)
                                .softAppear(true, delay: 0.08, reduceMotion: reduceMotion)
                        }

                        // Weekly plan
                        if let plan = viewModel.currentWeeklyPlan {
                            weeklySection(plan)
                                .softAppear(true, delay: 0.14, reduceMotion: reduceMotion)
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
            .animation(OhAnimation.appear(), value: viewModel.isLoading)
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
                    isRegenerating = true
                    viewModel.regenerateWeeklyPlan()
                    Task {
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        await MainActor.run {
                            withAnimation(OhAnimation.stagger()) {
                                isRegenerating = false
                            }
                        }
                    }
                } label: {
                    Label(language.text(.regeneratePlan), systemImage: "arrow.clockwise")
                }
                .font(.caption)
                .pressableScale()
                .disabled(isRegenerating)
            }
            Text(plan.strategySummary)
                .font(.footnote)
                .foregroundStyle(.secondary)
            ForEach(Array(plan.days.enumerated()), id: \.element.id) { index, day in
                planCard(day, title: language.formatDate(day.date, dateStyle: .medium), highlighted: false)
                    .softAppear(true, delay: Double(index) * 0.035, reduceMotion: reduceMotion)
            }
        }
    }

    // MARK: - Plan Card

    private func planCard(_ day: DailyPlan, title: String, highlighted: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(highlighted ? .headline : .subheadline.weight(.semibold))
                if highlighted {
                    Text(language.text(.todayBadge))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
                Spacer()
                // Status badge for non-planned days (shown instead of plan type)
                if day.status != .planned {
                    Label(statusText(day.status), systemImage: statusIcon(day.status))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(statusColor(day.status))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(statusColor(day.status).opacity(0.12))
                        .clipShape(Capsule())
                        .transition(.scale.combined(with: .opacity))
                }
                Text(language.planType(day.planType))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(Capsule())
            }

            Text(day.title)
                .font(.subheadline.weight(.semibold))
            Text(day.description)
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Label("\(day.estimatedDurationMinutes) \(language.text(.minUnit))", systemImage: "timer")
                Label(language.planIntensity(day.intensity), systemImage: "gauge")
                Spacer()
                // Status label line for adjusted days
                if let reason = day.adjustmentReason {
                    Label(reason, systemImage: "info.circle")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if day.safetyNote?.localizedCaseInsensitiveContains("Adjusted for safety") == true || day.adjustmentReason?.localizedCaseInsensitiveContains("Safety guardrail") == true {
                Label(language.text(.safetyAdjustedLabel), systemImage: "shield.lefthalf.filled")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Action buttons — compact row
            if highlighted || day.status != .completed {
                HStack(spacing: 6) {
                    Button {
                        withAnimation(OhAnimation.stagger()) {
                            viewModel.updateDailyPlanStatus(day, status: .completed)
                        }
                    } label: {
                        Label(language.text(.markCompleted), systemImage: "checkmark")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .pressableScale()
                    .tint(day.status == .completed ? .green : .accentColor)
                    .disabled(day.status == .completed)

                    Button {
                        withAnimation(OhAnimation.stagger()) {
                            viewModel.updateDailyPlanStatus(day, status: .skipped)
                        }
                    } label: {
                        Label(language.text(.markSkipped), systemImage: "forward")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .pressableScale()
                    .tint(day.status == .skipped ? .secondary : nil)
                    .disabled(day.status == .skipped)

                    Spacer()

                    Menu {
                        ForEach(DailyPlanType.allCases, id: \.self) { type in
                            Button(language.planType(type)) {
                                withAnimation(OhAnimation.stagger()) {
                                    viewModel.replaceDailyPlan(day, type: type, duration: day.estimatedDurationMinutes)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.caption)
                    }
                    .pressableScale()

                    HStack(spacing: 4) {
                        Button {
                            withAnimation(OhAnimation.tab()) {
                                viewModel.replaceDailyPlan(day, type: day.planType, duration: max(5, day.estimatedDurationMinutes - 5))
                            }
                        } label: {
                            Image(systemName: "minus")
                                .font(.caption)
                        }
                        .pressableScale()

                        Button {
                            withAnimation(OhAnimation.tab()) {
                                viewModel.replaceDailyPlan(day, type: day.planType, duration: day.estimatedDurationMinutes + 5)
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.caption)
                        }
                        .pressableScale()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(statusBackground(day.status))
        .clipShape(RoundedRectangle(cornerRadius: Radius.small))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.small)
                .stroke(
                    highlighted ? Color.accentColor.opacity(0.25) :
                        statusColor(day.status).opacity(day.status == .planned ? 0 : 0.22),
                    lineWidth: highlighted ? 1.5 : 1
                )
        }
        .animation(OhAnimation.stagger(), value: day.status)
    }

    private func statusText(_ status: DailyPlanStatus) -> String {
        switch status {
        case .planned: return language.text(.planStatusPlanned)
        case .adjusted: return language.text(.planStatusAdjusted)
        case .completed: return language.text(.planStatusCompleted)
        case .skipped: return language.text(.planStatusSkipped)
        }
    }

    private func statusIcon(_ status: DailyPlanStatus) -> String {
        switch status {
        case .planned: return "circle"
        case .adjusted: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .skipped: return "forward.circle.fill"
        }
    }

    private func statusColor(_ status: DailyPlanStatus) -> Color {
        switch status {
        case .planned: return .clear
        case .adjusted: return .orange
        case .completed: return .green
        case .skipped: return .secondary
        }
    }

    private func statusBackground(_ status: DailyPlanStatus) -> Color {
        switch status {
        case .planned: return Color(.systemBackground)
        case .adjusted: return Color.orange.opacity(0.08)
        case .completed: return Color.green.opacity(0.08)
        case .skipped: return Color(.secondarySystemGroupedBackground)
        }
    }
}

#Preview {
    let viewModel = OHeasViewModel()
    PlanTabView(viewModel: viewModel, language: .chinese)
        .task { await viewModel.load() }
}
