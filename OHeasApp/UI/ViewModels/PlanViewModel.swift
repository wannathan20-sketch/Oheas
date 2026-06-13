//
//  PlanViewModel.swift
//  OHeas
//
//  Manages goals, weekly plans, adaptive rescheduling, weekly reviews.
//  管理目标、周计划、自适应重调度、周复盘。
//

import Foundation
import SwiftUI          // <-- 添加这一行以支持 @AppStorage 等 SwiftUI 属性
import OHeasCore

@MainActor
final class PlanViewModel: ObservableObject {
    @Published var activeGoals: [UserGoal] = []
    @Published var currentWeeklyPlan: WeeklyPlan?
    @Published var todayDailyPlan: DailyPlan?
    @Published var recentPlanAdjustments: [PlanAdjustment] = []
    @Published var weeklyReview: WeeklyReview?
    @Published var newGoalTitle: String = "提升精力和稳定运动习惯"
    @Published var newGoalDescription: String = "每周稳定完成小而可持续的运动和恢复计划。"
    @Published var newGoalType: UserGoalType = .buildConsistency
    @Published var newGoalFrequency: Double = 5
    @Published var newGoalPriority: GoalPriority = .high
    @Published var isLoading = false
    @Published var isRegenerating = false

    @AppStorage("oheas.language") private var languageRawValue = AppLanguage.chinese.rawValue
    private var preferredLanguage: String {
        (AppLanguage(rawValue: languageRawValue) ?? .chinese).rawValue
    }

    private let calendar = Calendar.current
    private let goalStore = GoalStore(fileURL: OHeasStorageURLs.goals)
    private let planStore = PlanStore(fileURL: OHeasStorageURLs.weeklyPlans)
    private let weeklyPlanner = WeeklyPlanPlanner()
    private let rescheduler = AdaptiveRescheduler()
    private let weeklyReviewEngine = WeeklyReviewEngine()
    private let weeklyReviewStore = CodableFileStore<WeeklyReview>(fileURL: OHeasStorageURLs.weeklyReviews)
    private let errorReporter: ErrorReporter
    private lazy var recommendationStore = RecommendationHistoryStore(fileURL: OHeasStorageURLs.recommendations)
    private lazy var feedbackStore = FeedbackStore(fileURL: OHeasStorageURLs.feedback)
    private lazy var verificationStore = VerificationReportStore(fileURL: OHeasStorageURLs.verificationReports)
    private var syncEngine: SyncEngine?
    private var analyticsService: BetaAnalyticsService?

    /// Max number of recent plan adjustments to keep in memory.
    private let maxRecentAdjustments = 20

    init(errorReporter: ErrorReporter) {
        self.errorReporter = errorReporter
    }

    func configure(syncEngine: SyncEngine, analyticsService: BetaAnalyticsService) {
        self.syncEngine = syncEngine
        self.analyticsService = analyticsService
    }

    // MARK: - Goals

    func loadGoals() {
        do {
            activeGoals = try goalStore.getActiveGoals()
        } catch {
            errorReporter.record(category: .storage, message: "Failed to load goals: \(error.localizedDescription)")
            activeGoals = []
        }
    }

    func addGoal() {
        let goal = UserGoal(
            type: newGoalType,
            title: newGoalTitle,
            description: newGoalDescription,
            priority: newGoalPriority,
            targetFrequencyPerWeek: Int(newGoalFrequency.rounded()),
            preferredDays: [],
            constraints: []
        )
        do {
            try goalStore.addGoal(goal)
            loadGoals()
            // Reset form fields after successful add
            newGoalTitle = ""
            newGoalDescription = ""
        } catch {
            errorReporter.record(category: .storage, message: "Failed to add goal: \(error.localizedDescription)")
        }
    }

    func deactivateGoal(_ goal: UserGoal) {
        do {
            try goalStore.deactivateGoal(goal.id)
            loadGoals()
        } catch {
            errorReporter.record(category: .storage, message: "Failed to deactivate goal: \(error.localizedDescription)")
        }
    }

    func updateGoal(_ goal: UserGoal) {
        do {
            try goalStore.updateGoal(goal)
            loadGoals()
        } catch {
            errorReporter.record(category: .storage, message: "Failed to update goal: \(error.localizedDescription)")
        }
    }

    // MARK: - Weekly Plan

    func buildOrAdjustWeeklyPlan(
        today: DailyHealthMetrics,
        baseline: HealthBaseline,
        quality: DataQualityReport,
        signals: [HealthSignal],
        userMemory: UserMemory,
        activeExperiment: PersonalExperiment?
    ) {
        isLoading = true
        defer { isLoading = false }

        let weekStart = calendar.oheasWeekStart(for: today.date)
        var plan: WeeklyPlan?
        do {
            plan = try planStore.getCurrentWeekPlan(for: today.date)
        } catch {
            errorReporter.record(category: .storage, message: "Failed to load current week plan: \(error.localizedDescription)")
        }

        if plan == nil {
            var recommendations: [CoachRecommendation]
            var feedback: [DailyFeedback]
            do {
                recommendations = try recommendationStore.all()
                feedback = try feedbackStore.all()
            } catch {
                recommendations = []
                feedback = []
            }
            let input = WeeklyPlanPlannerInput(
                activeGoals: activeGoals,
                recentMetrics: [], // Will be set by caller
                baseline: baseline,
                dataQuality: quality,
                detectedSignals: signals,
                userMemory: userMemory,
                activeExperiment: activeExperiment,
                recentRecommendations: recommendations,
                recentFeedback: feedback,
                previousPlan: nil,
                preferredLanguage: preferredLanguage
            )
            let newPlan = weeklyPlanner.generatePlan(input: input, weekStartDate: weekStart)
            do {
                try planStore.saveCurrentWeekPlan(newPlan)
                try syncEngine?.enqueue(newPlan, entityType: .weeklyPlan, entityId: newPlan.id.uuidString)
                analyticsService.map { _ = try? $0.record(eventType: .weeklyPlanGenerated, userId: "local") }
            } catch {
                errorReporter.record(category: .storage, message: "Failed to save weekly plan: \(error.localizedDescription)")
            }
            plan = newPlan
        }

        guard var plan else { return }

        // Reschedule today
        let todayIndex = plan.days.firstIndex { calendar.isDate($0.date, inSameDayAs: today.date) }
        if let todayIndex {
            let previous = todayIndex > 0 ? plan.days[todayIndex - 1] : nil
            let before = plan.days[todayIndex]
            let after = rescheduler.reschedule(
                today: today,
                dataQuality: quality,
                detectedSignals: signals,
                currentPlan: before,
                activeExperiment: activeExperiment,
                userGoals: activeGoals,
                memory: userMemory,
                previousDayPlan: previous
            )
            if after != before {
                recentPlanAdjustments.insert(
                    PlanAdjustment(date: today.date, beforeType: before.planType, afterType: after.planType, reason: after.adjustmentReason ?? automaticAdjustmentReason),
                    at: 0
                )
                // Trim to prevent unbounded growth
                if recentPlanAdjustments.count > maxRecentAdjustments {
                    recentPlanAdjustments = Array(recentPlanAdjustments.prefix(maxRecentAdjustments))
                }
                plan.days[todayIndex] = after
                do {
                    try planStore.replaceDailyPlan(planId: plan.id, dailyPlan: after)
                    try syncEngine?.enqueue(plan, entityType: .weeklyPlan, entityId: plan.id.uuidString)
                    analyticsService.map { _ = try? $0.record(eventType: .weeklyPlanAdjusted, userId: "local", properties: ["reason": after.adjustmentReason ?? "adjusted"]) }
                } catch {
                    errorReporter.record(category: .storage, message: "Failed to save plan adjustment: \(error.localizedDescription)")
                }
            }
            todayDailyPlan = plan.days[todayIndex]
        }
        currentWeeklyPlan = plan

        // Safety check on plan
        let safetyContext = AgentContext(
            userGoal: activeGoals.map(\.title).joined(separator: ", "),
            todayMetrics: today,
            baseline14d: baseline,
            dataQuality: quality,
            detectedSignals: signals,
            coachingConstraints: [],
            recommendedDecisionFrame: ""
        )
        let sanitized = SafetyGuardrail().sanitize(plan: plan, context: safetyContext)
        if sanitized.1.riskLevel != .safe {
            analyticsService.map { _ = try? $0.record(eventType: .safetyFlagTriggered, userId: "local", properties: ["riskLevel": sanitized.1.riskLevel.rawValue]) }
        }
    }

    func regenerateWeeklyPlan(
        today: DailyHealthMetrics,
        baseline: HealthBaseline,
        quality: DataQualityReport,
        signals: [HealthSignal],
        userMemory: UserMemory,
        activeExperiment: PersonalExperiment?
    ) {
        isRegenerating = true
        defer { isRegenerating = false }

        var recommendations: [CoachRecommendation]
        var feedback: [DailyFeedback]
        do {
            recommendations = try recommendationStore.all()
            feedback = try feedbackStore.all()
        } catch {
            recommendations = []
            feedback = []
        }
        let input = WeeklyPlanPlannerInput(
            activeGoals: activeGoals,
            recentMetrics: [],
            baseline: baseline,
            dataQuality: quality,
            detectedSignals: signals,
            userMemory: userMemory,
            activeExperiment: activeExperiment,
            recentRecommendations: recommendations,
            recentFeedback: feedback,
            previousPlan: currentWeeklyPlan,
            preferredLanguage: preferredLanguage
        )
        let plan = weeklyPlanner.generatePlan(input: input, weekStartDate: calendar.oheasWeekStart(for: today.date))
        do {
            try planStore.saveCurrentWeekPlan(plan)
            try syncEngine?.enqueue(plan, entityType: .weeklyPlan, entityId: plan.id.uuidString)
            analyticsService.map { _ = try? $0.record(eventType: .weeklyPlanGenerated, userId: "local") }
        } catch {
            errorReporter.record(category: .storage, message: "Failed to save regenerated plan: \(error.localizedDescription)")
        }
        currentWeeklyPlan = plan
        todayDailyPlan = plan.days.first { calendar.isDate($0.date, inSameDayAs: today.date) }
    }

    func updateDailyPlanStatus(_ day: DailyPlan, status: DailyPlanStatus) {
        guard let plan = currentWeeklyPlan else { return }
        // Prevent marking future days as completed/skipped.
        guard day.date <= Date() else {
            errorReporter.record(category: .storage, message: "Cannot update plan status for a future date.")
            return
        }
        do {
            try planStore.updateDailyPlanStatus(planId: plan.id, dayId: day.id, status: status)
            currentWeeklyPlan = try planStore.getCurrentWeekPlan()
        } catch {
            errorReporter.record(category: .storage, message: "Failed to update plan status: \(error.localizedDescription)")
        }
    }

    func replaceDailyPlan(_ day: DailyPlan, type: DailyPlanType, duration: Int) {
        guard let plan = currentWeeklyPlan else { return }
        var updated = day
        updated.planType = type
        updated.estimatedDurationMinutes = duration
        updated.status = .adjusted
        updated.adjustmentReason = manualAdjustmentReason
        updated.updatedAt = Date()
        do {
            try planStore.replaceDailyPlan(planId: plan.id, dailyPlan: updated)
            try syncEngine?.enqueue(updated, entityType: .weeklyPlan, entityId: plan.id.uuidString)
            currentWeeklyPlan = try planStore.getCurrentWeekPlan()
        } catch {
            errorReporter.record(category: .storage, message: "Failed to replace daily plan: \(error.localizedDescription)")
        }
    }

    // MARK: - Weekly Review

    func buildWeeklyReviewIfPossible(
        userMemory: UserMemory,
        experimentHistory: [PersonalExperiment],
        metricsForWeek: [DailyHealthMetrics]
    ) {
        guard let plan = currentWeeklyPlan else { return }
        var feedbackHistory: [DailyFeedback]
        var recommendationHistory: [CoachRecommendation]
        var verificationReports: [VerificationReport]
        do {
            feedbackHistory = try feedbackStore.all()
            recommendationHistory = try recommendationStore.all()
            verificationReports = try verificationStore.all()
        } catch {
            feedbackHistory = []
            recommendationHistory = []
            verificationReports = []
        }
        let review = weeklyReviewEngine.review(
            plan: plan,
            feedbackHistory: feedbackHistory,
            recommendationHistory: recommendationHistory,
            verificationReports: verificationReports,
            experimentHistory: experimentHistory,
            memory: userMemory,
            metricsForWeek: metricsForWeek
        )
        weeklyReview = review
        do {
            try weeklyReviewStore.upsert(review) { $0.weekStartDate == review.weekStartDate }
            try syncEngine?.enqueue(review, entityType: .weeklyReview, entityId: review.id.uuidString)
        } catch {
            errorReporter.record(category: .storage, message: "Failed to save weekly review: \(error.localizedDescription)")
        }
    }

    func setRecentMetrics(_ metrics: [DailyHealthMetrics]) {
        // Stored for weekly review use
    }

    private var automaticAdjustmentReason: String {
        preferredLanguage == "zh" ? "已根据今天的数据调整。" : "Adjusted based on today's data."
    }

    private var manualAdjustmentReason: String {
        preferredLanguage == "zh" ? "用户手动调整。" : "Manually adjusted by user."
    }
}

private extension BetaAnalyticsService {
    func recordQuietly(eventType: BetaAnalyticsEventType, userId: String, properties: [String: String] = [:]) {
        _ = try? record(eventType: eventType, userId: userId, properties: properties)
    }
}
