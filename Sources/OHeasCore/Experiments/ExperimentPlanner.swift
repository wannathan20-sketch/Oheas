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
        previousExperiments: [PersonalExperiment],
        preferredLanguage: String = "en"
    ) -> PersonalExperiment {
        let zh = preferredLanguage == "zh"
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 5, to: start) ?? start

        if dataQuality.overallConfidence == .low || lowCoverageIsFrequent(recentMetrics) {
            return safeExperiment(experiment(
                title: zh ? "建立 5 晚恢复基线" : "Build 5-night recovery baseline",
                hypothesis: zh ? "连续 5 晚佩戴 Apple Watch，提升睡眠和 HRV 数据覆盖率，可能让建议更可靠。" : "Wearing Apple Watch for 5 consecutive nights to improve sleep and HRV coverage may increase recommendation confidence.",
                intervention: zh ? "连续 5 晚睡觉时佩戴 Apple Watch，并记录早晨精力。" : "Wear Apple Watch to bed for 5 consecutive nights and record morning energy.",
                targetMetrics: ["sleepHours", "hrv", "restingHeartRate", "subjectiveEnergy", "dataQuality"],
                why: zh ? "当前恢复数据置信度偏低。现在先补齐数据，比直接调整训练更可靠。" : "Recovery data confidence is currently low. Building data coverage is more reliable than adjusting training right now.",
                start: start,
                end: end
            ), dataQuality: dataQuality)
        }

        if let successful = memory.successfulInterventions.first {
            return safeExperiment(experiment(
                title: zh ? "验证一个已有效的小策略" : "Confirm a known effective strategy",
                hypothesis: zh ? "重复一次曾经有帮助的小行动，可以确认它是否真的适合你。" : "Repeating a previously helpful small intervention may confirm whether it works for you.",
                intervention: successful.intervention,
                targetMetrics: successful.targetMetrics,
                why: zh ? "长期记忆里已经有一个可能有效的行动，优先验证它更有价值。" : "A potentially effective intervention exists in long-term memory. Prioritize confirming it.",
                start: start,
                end: end
            ), dataQuality: dataQuality)
        }

        let signalTypes = Set(recentSignals.map(\.type))
        if signalTypes.contains(.sleepLow) || memory.knownPatterns.contains(where: { $0.title.localizedCaseInsensitiveContains("sleep") }) {
            return safeExperiment(experiment(
                title: zh ? "提前 30 分钟入睡实验" : "30-minute earlier bedtime experiment",
                hypothesis: zh ? "连续 5 天提前 30 分钟入睡，可能改善睡眠时长和次日恢复指标。" : "Going to bed 30 minutes earlier for 5 days may improve sleep duration and next-day recovery metrics.",
                intervention: zh ? "连续 5 天比平时提前 30 分钟上床睡觉。" : "Go to bed 30 minutes earlier for 5 consecutive days.",
                targetMetrics: ["sleepHours", "hrv", "restingHeartRate", "subjectiveEnergy"],
                why: zh ? "最近出现睡眠偏低信号，适合测试一个小幅、低风险的作息调整。" : "Recent sleep-low signals suggest testing a small sleep regularity improvement.",
                start: start,
                end: end
            ), dataQuality: dataQuality)
        }

        if signalTypes.contains(.activityHigh), signalTypes.contains(.hrvLow) || signalTypes.contains(.restingHeartHigh) {
            return safeExperiment(experiment(
                title: zh ? "高强度后低强度恢复实验" : "Low-intensity recovery after high-intensity days",
                hypothesis: zh ? "高强度训练后的次日只做低强度活动，可能帮助恢复指标回到基线附近。" : "Doing only low-intensity activity the day after high-intensity training may help recovery metrics return toward baseline.",
                intervention: zh ? "高强度训练后的第二天只做低强度活动。" : "Do only low-intensity activity the day after high-intensity training.",
                targetMetrics: ["hrv", "restingHeartRate", "subjectiveEnergy", "soreness"],
                why: zh ? "最近高活动量和恢复偏弱信号同时出现，适合验证恢复节奏。" : "Recent high activity and lower recovery signals coincide. Good opportunity to verify recovery pacing.",
                start: start,
                end: end
            ), dataQuality: dataQuality)
        }

        if signalTypes.contains(.activityLow), !signalTypes.contains(.hrvLow), !signalTypes.contains(.restingHeartHigh) {
            return safeExperiment(experiment(
                title: zh ? "每日轻活动实验" : "Light daily movement experiment",
                hypothesis: zh ? "连续 5 天下午散步 15 分钟，可能提升活动稳定性，同时不牺牲恢复。" : "A 15-minute afternoon walk for 5 days may improve activity consistency without sacrificing recovery.",
                intervention: zh ? "连续 5 天每天下午散步 15 分钟。" : "Take a 15-minute walk every afternoon for 5 consecutive days.",
                targetMetrics: ["steps", "activeEnergyKcal", "hrv", "subjectiveEnergy"],
                why: zh ? "活动量偏低，但恢复信号稳定。轻活动实验风险低，也更容易坚持。" : "Activity is low but recovery signals are stable. A light activity experiment is low-risk.",
                start: start,
                end: end
            ), dataQuality: dataQuality)
        }

        return safeExperiment(experiment(
            title: zh ? "稳定作息观察实验" : "Steady routine observation",
            hypothesis: zh ? "连续 5 天保持固定的睡前放松窗口，可能帮助恢复更稳定。" : "Keeping a fixed bedtime window for 5 days may help maintain stable recovery.",
            intervention: zh ? "连续 5 天睡前保留固定的 30 分钟放松时间。" : "Keep a fixed 30-minute wind-down window before bed for 5 days.",
            targetMetrics: ["sleepHours", "hrv", "subjectiveEnergy"],
            why: zh ? "目前还没有足够强的个人模式。先从低风险的作息实验开始，积累基线数据。" : "No strong personalized pattern to build on yet. Start with a low-risk routine experiment to gather baseline data.",
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
