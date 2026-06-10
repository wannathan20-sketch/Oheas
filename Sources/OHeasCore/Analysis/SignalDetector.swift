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

    public func detect(today: DailyHealthMetrics, baseline: HealthBaseline, dataQuality: DataQualityReport) -> [HealthSignal] {
        // Data confidence is low: avoid strong recovery conclusions to prevent over-interpretation.
        guard dataQuality.overallConfidence != .low else {
            return [
                HealthSignal(
                    type: .recoveryUncertainDueToMissingData,
                    severity: .medium,
                    evidence: dataQuality.missingReasons.joined(separator: " "),
                    explanation: "Recovery signals are intentionally conservative because multiple key recovery metrics are missing."
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
                        evidence: "HRV \(todayHRV.roundedString()) ms / 14d \(baselineHRV.roundedString()) ms (\(percentDelta.roundedString())%).",
                        explanation: "HRV is materially below baseline, which can indicate lower recovery or higher recent stress. This is not a diagnosis."
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
                        evidence: "RHR \(todayRHR.roundedString()) bpm / 14d \(baselineRHR.roundedString()) bpm (+\(delta.roundedString()) bpm).",
                        explanation: "Resting heart rate is above baseline, so today's recommendations should reduce intensity and favor recovery."
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
                        evidence: "Sleep \(todaySleep.roundedString()) h / 14d \(baselineSleep.roundedString()) h (-\((deltaHours * 60).roundedString()) min).",
                        explanation: "Sleep was meaningfully below baseline, so the decision frame should protect energy and avoid overreaching."
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
                        evidence: "Steps \(todaySteps.roundedString()) / 14d \(baselineSteps.roundedString()) (\(((ratio - 1) * 100).roundedString())%).",
                        explanation: "Activity is well below baseline, so a small mobility target may be more realistic than a full workout."
                    )
                )
            } else if ratio >= 1.35 {
                signals.append(
                    HealthSignal(
                        type: .activityHigh,
                        severity: ratio >= 1.75 ? .high : .medium,
                        evidence: "Steps \(todaySteps.roundedString()) / 14d \(baselineSteps.roundedString()) (+\(((ratio - 1) * 100).roundedString())%).",
                        explanation: "Activity is above baseline, so recovery support and sleep timing matter more tonight."
                    )
                )
            }
        }

        if signals.isEmpty, dataQuality.overallConfidence == .medium {
            signals.append(
                HealthSignal(
                    type: .recoveryUncertainDueToMissingData,
                    severity: .low,
                    evidence: dataQuality.missingReasons.joined(separator: " "),
                    explanation: "Available data does not show a strong signal, but missing recovery data lowers confidence."
                )
            )
        }

        return signals
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
