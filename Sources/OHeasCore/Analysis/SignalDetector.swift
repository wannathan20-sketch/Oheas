//
//  SignalDetector.swift
//  OHeas
//
//  Detects health signals (HRV drop, sleep low, activity anomaly).
//  检测健康信号（HRV 下降、睡眠不足、活动异常）。
//


import Foundation

public struct SignalDetector: Sendable {
    public init() {}

    public func detect(today: DailyHealthMetrics, baseline: HealthBaseline, dataQuality: DataQualityReport, preferredLanguage: String = "en") -> [HealthSignal] {
        let zh = preferredLanguage == "zh"
        // Data confidence is low: avoid strong recovery conclusions to prevent over-interpretation.
        guard dataQuality.overallConfidence != .low else {
            return [
                HealthSignal(
                    type: .recoveryUncertainDueToMissingData,
                    severity: .medium,
                    evidence: localizedMissingReasons(dataQuality.missingReasons, zh: zh).joined(separator: " "),
                    explanation: zh
                        ? "由于多个关键恢复指标缺失，恢复信号会按保守方式解读。"
                        : "Recovery signals are intentionally conservative because multiple key recovery metrics are missing."
                )
            ]
        }

        let statuses = today.perMetricStatus
        var signals: [HealthSignal] = []

        if let todayHRV = today.hrv, let baselineHRV = baseline.averageHRV, baselineHRV > 0 {
            let percentDelta = (todayHRV - baselineHRV) / baselineHRV * 100.0
            if percentDelta <= -15.0 {
                let severity: SignalSeverity = {
                    let base: SignalSeverity = percentDelta <= -25.0 ? .high : .medium
                    // HRV from <3 samples is noisy — downgrade one level to avoid false alarms
                    if statuses[.hrv] == .partial { return base == .high ? .medium : .low }
                    return base
                }()
                signals.append(
                    HealthSignal(
                        type: .hrvLow,
                        severity: severity,
                        evidence: zh
                            ? "HRV \(todayHRV.roundedString())ms / 14 天基线 \(baselineHRV.roundedString())ms（\(percentDelta.roundedString())%）。"
                            : "HRV \(todayHRV.roundedString()) ms / 14d \(baselineHRV.roundedString()) ms (\(percentDelta.roundedString())%).",
                        explanation: zh
                            ? "HRV 明显低于基线，可能提示恢复偏低或近期压力偏高。这不是医学诊断。"
                            : "HRV is materially below baseline, which can indicate lower recovery or higher recent stress. This is not a diagnosis."
                    )
                )
            }
        }

        if let todayRHR = today.restingHeartRate, let baselineRHR = baseline.averageRestingHeartRate {
            let delta = todayRHR - baselineRHR
            if delta >= 5.0 {
                let severity: SignalSeverity = {
                    let base: SignalSeverity = delta >= 10.0 ? .high : .medium
                    // RHR from <3 samples is noisy — downgrade one level
                    if statuses[.restingHeartRate] == .partial { return base == .high ? .medium : .low }
                    return base
                }()
                signals.append(
                    HealthSignal(
                        type: .restingHeartHigh,
                        severity: severity,
                        evidence: zh
                            ? "静息心率 \(todayRHR.roundedString())bpm / 14 天基线 \(baselineRHR.roundedString())bpm（+\(delta.roundedString())bpm）。"
                            : "RHR \(todayRHR.roundedString()) bpm / 14d \(baselineRHR.roundedString()) bpm (+\(delta.roundedString()) bpm).",
                        explanation: zh
                            ? "静息心率高于基线，今天的建议应降低强度并优先恢复。"
                            : "Resting heart rate is above baseline, so today's recommendations should reduce intensity and favor recovery."
                    )
                )
            }
        }

        if let todaySleep = today.sleepHours, let baselineSleep = baseline.averageSleepHours {
            let deltaHours = baselineSleep - todaySleep
            if deltaHours >= 0.75 {
                signals.append(
                    HealthSignal(
                        type: .sleepLow,
                        severity: deltaHours >= 1.5 ? .high : .medium,
                        evidence: zh
                            ? "睡眠 \(todaySleep.roundedString()) 小时 / 14 天基线 \(baselineSleep.roundedString()) 小时（少 \((deltaHours * 60).roundedString()) 分钟）。"
                            : "Sleep \(todaySleep.roundedString()) h / 14d \(baselineSleep.roundedString()) h (-\((deltaHours * 60).roundedString()) min).",
                        explanation: zh
                            ? "睡眠明显低于基线，今天应保护精力，避免过度消耗。"
                            : "Sleep was meaningfully below baseline, so the decision frame should protect energy and avoid overreaching."
                    )
                )
            }
        }

        if let todaySteps = today.steps, let baselineSteps = baseline.averageSteps, baselineSteps > 0 {
            let ratio = todaySteps / baselineSteps
            if ratio <= 0.60 {
                signals.append(
                    HealthSignal(
                        type: .activityLow,
                        severity: ratio <= 0.40 ? .high : .medium,
                        evidence: zh
                            ? "步数 \(todaySteps.roundedString()) / 14 天基线 \(baselineSteps.roundedString())（\(((ratio - 1) * 100).roundedString())%）。"
                            : "Steps \(todaySteps.roundedString()) / 14d \(baselineSteps.roundedString()) (\(((ratio - 1) * 100).roundedString())%).",
                        explanation: zh
                            ? "活动量明显低于基线，小幅活动目标可能比完整训练更现实。"
                            : "Activity is well below baseline, so a small mobility target may be more realistic than a full workout."
                    )
                )
            } else if ratio >= 1.35 {
                signals.append(
                    HealthSignal(
                        type: .activityHigh,
                        severity: ratio >= 1.75 ? .high : .medium,
                        evidence: zh
                            ? "步数 \(todaySteps.roundedString()) / 14 天基线 \(baselineSteps.roundedString())（+\(((ratio - 1) * 100).roundedString())%）。"
                            : "Steps \(todaySteps.roundedString()) / 14d \(baselineSteps.roundedString()) (+\(((ratio - 1) * 100).roundedString())%).",
                        explanation: zh
                            ? "活动量高于基线，今晚更需要关注恢复支持和睡眠节奏。"
                            : "Activity is above baseline, so recovery support and sleep timing matter more tonight."
                    )
                )
            }
        }

        if signals.isEmpty, dataQuality.overallConfidence == .medium {
            signals.append(
                HealthSignal(
                    type: .recoveryUncertainDueToMissingData,
                    severity: .low,
                    evidence: localizedMissingReasons(dataQuality.missingReasons, zh: zh).joined(separator: " "),
                    explanation: zh
                        ? "现有数据没有强信号，但恢复数据缺失会降低判断置信度。"
                        : "Available data does not show a strong signal, but missing recovery data lowers confidence."
                )
            )
        }

        return signals
    }

    private func localizedMissingReasons(_ reasons: [String], zh: Bool) -> [String] {
        guard zh else { return reasons }
        return reasons.map { reason in
            let lower = reason.lowercased()
            if lower.contains("sleep data has been missing") && lower.contains("consecutive days") {
                return "睡眠数据已连续多天缺失，请检查 Apple Watch 睡眠设置或夜间佩戴情况。"
            }
            if lower.contains("recovery data has been missing") && lower.contains("consecutive days") {
                return "恢复数据已连续多天缺失，建议睡眠时佩戴 Apple Watch 以建立可靠基线。"
            }
            if lower.contains("apple watch data may still be syncing") {
                return "Apple Watch 数据可能仍在同步。如果已佩戴手表，请稍等几分钟后刷新。"
            }
            if lower.contains("sleep data is missing") {
                return "睡眠数据缺失，可能是夜间未佩戴 Apple Watch 或未开启睡眠追踪。"
            }
            if lower.contains("hrv data is missing") {
                return "HRV 数据缺失，会限制恢复解读。"
            }
            if lower.contains("resting heart rate is missing") {
                return "静息心率缺失，会限制压力和恢复判断。"
            }
            if lower.contains("step count is missing") {
                return "步数数据缺失。"
            }
            if lower.contains("active energy is missing") {
                return "活动能量数据缺失。"
            }
            if lower.contains("exercise minutes are missing") {
                return "运动分钟数缺失。"
            }
            if lower.contains("workout records could not be queried") {
                return "无法读取运动记录。"
            }
            if lower.contains("aggregated metrics hidden by privacy settings") {
                return "聚合指标已被隐私设置隐藏。"
            }
            return reason
        }
    }
}

extension Double {
    package func roundedString(digits: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = digits
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
