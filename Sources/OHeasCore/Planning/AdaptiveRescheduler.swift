//
//  AdaptiveRescheduler.swift
//  OHeas
//
//  Adaptively reschedules weekly plans based on recovery signals.
//  基于恢复信号自适应重调度周计划。
//


import Foundation

public struct AdaptiveRescheduler: Sendable {
    public init() {}

    public func reschedule(
        today: DailyHealthMetrics,
        dataQuality: DataQualityReport,
        detectedSignals: [HealthSignal],
        currentPlan: DailyPlan,
        activeExperiment: PersonalExperiment?,
        userGoals: [UserGoal],
        memory: UserMemory,
        previousDayPlan: DailyPlan? = nil
    ) -> DailyPlan {
        var plan = currentPlan
        let signalTypes = Set(detectedSignals.map(\.type))

        if let activeExperiment, plan.linkedExperimentId == nil {
            plan.planType = .experimentFocus
            plan.title = activeExperiment.title
            plan.description = activeExperiment.intervention
            plan.intensity = min(plan.intensity, .low)
            plan.linkedExperimentId = activeExperiment.id.uuidString
            plan.adjustmentReason = "Active experiment kept in today's plan."
            plan.status = .adjusted
        }

        if dataQuality.overallConfidence == .low {
            plan = conservative(plan, type: .dataCoverage, reason: "Data confidence is low; avoid strong recovery claims and rebuild sleep/HRV coverage.")
        } else if signalTypes.contains(.hrvLow), signalTypes.contains(.restingHeartHigh), signalTypes.contains(.sleepLow) {
            plan = conservative(plan, type: .sleepFocus, reason: "HRV low, resting heart rate high, and sleep low; reducing intensity today.")
        } else if signalTypes.contains(.recoveryUncertainDueToMissingData) {
            plan = conservative(plan, type: .lightActivity, reason: "Recovery is uncertain due to missing data; using a low-risk plan.")
        } else if signalTypes.contains(.activityLow), !signalTypes.contains(.hrvLow), !signalTypes.contains(.restingHeartHigh), plan.planType == .rest {
            plan.planType = .lightActivity
            plan.title = "Light consistency activity"
            plan.description = "A short easy walk is reasonable if you feel well."
            plan.intensity = .low
            plan.estimatedDurationMinutes = 15
            plan.adjustmentReason = "Activity is low while recovery signals are stable."
            plan.status = .adjusted
        }

        if previousDayPlan?.intensity == .high, plan.intensity == .high {
            plan = conservative(plan, type: .lightActivity, reason: "Avoiding consecutive high intensity days.")
        }

        plan.updatedAt = Date()
        return plan
    }

    private func conservative(_ plan: DailyPlan, type: DailyPlanType, reason: String) -> DailyPlan {
        var adjusted = plan
        adjusted.planType = type
        adjusted.title = type == .dataCoverage ? "Data coverage and easy day" : "Recovery-adjusted day"
        adjusted.description = type == .dataCoverage
            ? "Keep activity easy and wear Apple Watch tonight to improve recovery data."
            : "Keep effort low; choose rest, mobility, or an easy walk."
        adjusted.intensity = .veryLow
        adjusted.estimatedDurationMinutes = min(plan.estimatedDurationMinutes, 15)
        adjusted.targetMetrics = Array(Set(adjusted.targetMetrics + ["sleepHours", "hrv", "subjectiveEnergy"]))
        adjusted.adjustmentReason = reason
        adjusted.status = .adjusted
        return adjusted
    }
}

private func min(_ lhs: PlanIntensity, _ rhs: PlanIntensity) -> PlanIntensity {
    lhs.rank <= rhs.rank ? lhs : rhs
}

private extension PlanIntensity {
    var rank: Int {
        switch self {
        case .veryLow: 0
        case .low: 1
        case .medium: 2
        case .high: 3
        }
    }
}
