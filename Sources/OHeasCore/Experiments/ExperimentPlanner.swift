//
//  ExperimentPlanner.swift
//  OHeas
//
//  Proposes personalized experiments based on patterns and data.
//  基于模式和数据提出个性化实验。
//


import Foundation

public struct ExperimentPlanner: Sendable {
    private let calendar: Calendar
    private let safetyGuardrail: SafetyGuardrail

    public init(calendar: Calendar = .current, safetyGuardrail: SafetyGuardrail = SafetyGuardrail()) {
        self.calendar = calendar
        self.safetyGuardrail = safetyGuardrail
    }

    public func propose(
        memory: UserMemory,
        recentMetrics: [DailyHealthMetrics],
        recentSignals: [HealthSignal],
        dataQuality: DataQualityReport,
        userGoal: String,
        previousExperiments: [PersonalExperiment]
    ) -> PersonalExperiment {
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 5, to: start) ?? start

        if dataQuality.overallConfidence == .low || lowCoverageIsFrequent(recentMetrics) {
            return safeExperiment(experiment(
                title: "Build 5-night recovery baseline",
                hypothesis: "Wearing Apple Watch for 5 consecutive nights to improve sleep and HRV coverage may increase recommendation confidence.",
                intervention: "Wear Apple Watch to bed for 5 consecutive nights and record morning energy.",
                targetMetrics: ["sleepHours", "hrv", "restingHeartRate", "subjectiveEnergy", "dataQuality"],
                why: "Recovery data confidence is currently low. Building data coverage is more reliable than adjusting training right now.",
                start: start,
                end: end
            ), dataQuality: dataQuality)
        }

        if let successful = memory.successfulInterventions.first {
            return safeExperiment(experiment(
                title: "Confirm a known effective strategy",
                hypothesis: "Repeating a previously helpful small intervention may confirm whether it works for you.",
                intervention: successful.intervention,
                targetMetrics: successful.targetMetrics,
                why: "A potentially effective intervention exists in long-term memory. Prioritize confirming it.",
                start: start,
                end: end
            ), dataQuality: dataQuality)
        }

        let signalTypes = Set(recentSignals.map(\.type))
        if signalTypes.contains(.sleepLow) || memory.knownPatterns.contains(where: { $0.title.localizedCaseInsensitiveContains("sleep") }) {
            return safeExperiment(experiment(
                title: "30-minute earlier bedtime experiment",
                hypothesis: "Going to bed 30 minutes earlier for 5 days may improve sleep duration and next-day recovery metrics.",
                intervention: "Go to bed 30 minutes earlier for 5 consecutive days.",
                targetMetrics: ["sleepHours", "hrv", "restingHeartRate", "subjectiveEnergy"],
                why: "Recent sleep-low signals suggest testing a small sleep regularity improvement.",
                start: start,
                end: end
            ), dataQuality: dataQuality)
        }

        if signalTypes.contains(.activityHigh), signalTypes.contains(.hrvLow) || signalTypes.contains(.restingHeartHigh) {
            return safeExperiment(experiment(
                title: "Low-intensity recovery after high-intensity days",
                hypothesis: "Doing only low-intensity activity the day after high-intensity training may help recovery metrics return toward baseline.",
                intervention: "Do only low-intensity activity the day after high-intensity training.",
                targetMetrics: ["hrv", "restingHeartRate", "subjectiveEnergy", "soreness"],
                why: "Recent high activity and lower recovery signals coincide. Good opportunity to verify recovery pacing.",
                start: start,
                end: end
            ), dataQuality: dataQuality)
        }

        if signalTypes.contains(.activityLow), !signalTypes.contains(.hrvLow), !signalTypes.contains(.restingHeartHigh) {
            return safeExperiment(experiment(
                title: "Light daily movement experiment",
                hypothesis: "A 15-minute afternoon walk for 5 days may improve activity consistency without sacrificing recovery.",
                intervention: "Take a 15-minute walk every afternoon for 5 consecutive days.",
                targetMetrics: ["steps", "activeEnergyKcal", "hrv", "subjectiveEnergy"],
                why: "Activity is low but recovery signals are stable. A light activity experiment is low-risk.",
                start: start,
                end: end
            ), dataQuality: dataQuality)
        }

        return safeExperiment(experiment(
            title: "Steady routine observation",
            hypothesis: "Keeping a fixed bedtime window for 5 days may help maintain stable recovery.",
            intervention: "Keep a fixed 30-minute wind-down window before bed for 5 days.",
            targetMetrics: ["sleepHours", "hrv", "subjectiveEnergy"],
            why: "No strong personalized pattern to build on yet. Start with a low-risk routine experiment to gather baseline data.",
            start: start,
            end: end
        ), dataQuality: dataQuality)
    }

    private func experiment(
        title: String,
        hypothesis: String,
        intervention: String,
        targetMetrics: [String],
        why: String,
        start: Date,
        end: Date
    ) -> PersonalExperiment {
        PersonalExperiment(
            title: title,
            hypothesis: hypothesis,
            intervention: intervention,
            startDate: start,
            endDate: end,
            targetMetrics: targetMetrics,
            whyThisExperiment: why
        )
    }

    private func safeExperiment(_ experiment: PersonalExperiment, dataQuality: DataQualityReport) -> PersonalExperiment {
        safetyGuardrail.sanitize(experiment: experiment, dataQuality: dataQuality).0
    }

    private func lowCoverageIsFrequent(_ metrics: [DailyHealthMetrics]) -> Bool {
        let recent = Array(metrics.suffix(7))
        let missingCount = recent.filter { day in
            day.perMetricStatus[.sleepHours] == .missing || day.perMetricStatus[.hrv] == .missing
        }.count
        return missingCount >= 3
    }
}
