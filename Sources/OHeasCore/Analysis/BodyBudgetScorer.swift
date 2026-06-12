//
//  BodyBudgetScorer.swift
//  OHeas
//
//  Computes a 0-100 "Body Budget Score" from today's metrics vs baseline.
//  基于今日指标与基线的对比，计算 0-100 的"身体预算评分"。
//
//  Market reference: Oura Readiness Score, Whoop Recovery %, Athlytic Recovery.
//

import Foundation

/// Computes a composite 0-100 Body Budget Score using four weighted pillars:
/// - Recovery (40%): sleep, HRV, resting heart rate z-scores vs 14-day baseline
/// - Activity (25%): steps and exercise minutes vs baseline
/// - Subjective (15%): user-reported energy, soreness, stress from DailyFeedback
/// - Signals (20%): penalty for detected high-severity HealthSignals
///
/// Missing data reduces the affected pillar's weight proportionally and shifts
/// contribution toward neutral (50) to avoid over-interpreting gaps.
public struct BodyBudgetScorer: Sendable {
    public init() {}

    // MARK: - Pillar weights (must sum to 1.0)

    private let recoveryWeight = 0.40
    private let activityWeight = 0.25
    private let subjectiveWeight = 0.15
    private let signalWeight = 0.20

    // MARK: - Public API

    /// Compute the Body Budget Score.
    /// - Parameters:
    ///   - today: Today's aggregated health metrics.
    ///   - baseline: 14-day rolling baseline.
    ///   - signals: Detected health signals (used for penalty calculation).
    ///   - feedback: Yesterday's subjective feedback (if available).
    ///   - preferredLanguage: "zh" or "en" for factor explanations.
    /// - Returns: A `BodyBudgetScore` with value, category, and factor breakdown.
    public func score(
        today: DailyHealthMetrics,
        baseline: HealthBaseline,
        signals: [HealthSignal],
        feedback: DailyFeedback?,
        preferredLanguage: String = "en"
    ) -> BodyBudgetScore {
        let zh = preferredLanguage == "zh"

        // --- Recovery pillar (40%) ---
        let (recoveryScore, recoveryFactors) = computeRecoveryPillar(
            today: today, baseline: baseline, weight: recoveryWeight, zh: zh
        )

        // --- Activity pillar (25%) ---
        let (activityScore, activityFactors) = computeActivityPillar(
            today: today, baseline: baseline, weight: activityWeight, zh: zh
        )

        // --- Subjective pillar (15%) ---
        let (subjectiveScore, subjectiveFactors) = computeSubjectivePillar(
            feedback: feedback, weight: subjectiveWeight, zh: zh
        )

        // --- Signal penalty (20%) ---
        let (signalPenalty, signalFactors) = computeSignalPenalty(
            signals: signals, weight: signalWeight, zh: zh
        )

        // Combine: recovery + activity + subjective - signalPenalty
        var rawScore = recoveryScore + activityScore + subjectiveScore - signalPenalty
        rawScore = max(0, min(100, rawScore))

        let value = Int(rawScore.rounded())
        let category = categorize(value)

        // Re-weight subjective pillar: if no feedback, redistribute its weight
        let effectiveSubjectiveWeight: Double = feedback != nil ? subjectiveWeight : 0
        let totalEffectiveWeight = recoveryWeight + activityWeight + effectiveSubjectiveWeight + signalWeight

        let allFactors = recoveryFactors + activityFactors + subjectiveFactors + signalFactors

        return BodyBudgetScore(
            value: value,
            category: category,
            factors: allFactors,
            recoverySubscore: recoveryScore / recoveryWeight * totalEffectiveWeight,
            activitySubscore: activityScore / activityWeight * totalEffectiveWeight,
            subjectiveSubscore: feedback != nil ? subjectiveScore / subjectiveWeight * totalEffectiveWeight : 50,
            signalPenalty: signalPenalty
        )
    }

    // MARK: - Category mapping

    private func categorize(_ score: Int) -> BudgetCategory {
        switch score {
        case 85...100: .excellent
        case 70..<85:  .good
        case 55..<70:  .fair
        case 35..<55:  .strained
        default:       .depleted
        }
    }

    // MARK: - Recovery pillar (sleep, HRV, RHR)

    private func computeRecoveryPillar(
        today: DailyHealthMetrics,
        baseline: HealthBaseline,
        weight: Double,
        zh: Bool
    ) -> (Double, [BudgetFactor]) {
        var factors: [BudgetFactor] = []
        var totalScore: Double = 0
        var activeWeight: Double = 0

        // Each sub-metric counts for 1/3 of the recovery pillar
        let subMetrics: [(HealthMetric, Double?, Double?, String)] = [
            (.sleepHours, today.sleepHours, baseline.averageSleepHours,
             zh ? "睡眠" : "Sleep"),
            (.hrv, today.hrv, baseline.averageHRV,
             zh ? "HRV" : "HRV"),
            (.restingHeartRate, today.restingHeartRate, baseline.averageRestingHeartRate,
             zh ? "静息心率" : "RHR"),
        ]

        let subWeight = weight / 3.0

        for (metric, todayVal, baselineVal, name) in subMetrics {
            guard let tv = todayVal, let bv = baselineVal, bv > 0 else {
                // Missing data: contribute neutral with reduced weight
                totalScore += 50 * subWeight * 0.3
                activeWeight += subWeight * 0.3
                continue
            }

            activeWeight += subWeight

            if metric == .restingHeartRate {
                // RHR: lower is better
                let delta = bv - tv  // positive = improvement
                let pctDelta = delta / bv
                let zScore = min(2.0, max(-2.0, pctDelta / 0.05))  // 5% change = 1 z-score
                let subscore = 50 + zScore * 25
                let clamped = min(100, max(0, subscore))
                totalScore += clamped * subWeight

                if abs(pctDelta) > 0.02 {
                    let contrib = (clamped - 50) * subWeight / 50 * weight
                    factors.append(BudgetFactor(
                        metric: metric,
                        contribution: contrib,
                        weight: subWeight,
                        explanation: zh
                            ? "\(name) \(String(format: "%.0f", tv)) bpm，\(delta > 0 ? "低于" : "高于")基线 \(String(format: "%.0f", bv)) bpm"
                            : "\(name) \(String(format: "%.0f", tv)) bpm, \(delta > 0 ? "below" : "above") baseline \(String(format: "%.0f", bv)) bpm"
                    ))
                }
            } else {
                // Sleep & HRV: higher is better
                let pctDelta = (tv - bv) / bv
                let zScore = min(2.0, max(-2.0, pctDelta / 0.10))  // 10% change = 1 z-score
                let subscore = 50 + zScore * 25
                let clamped = min(100, max(0, subscore))
                totalScore += clamped * subWeight

                if abs(pctDelta) > 0.03 {
                    let contrib = (clamped - 50) * subWeight / 50 * weight
                    let direction = pctDelta >= 0
                        ? (zh ? "高于" : "above")
                        : (zh ? "低于" : "below")
                    let unit = metric == .sleepHours
                        ? (zh ? "小时" : "h")
                        : "ms"
                    factors.append(BudgetFactor(
                        metric: metric,
                        contribution: contrib,
                        weight: subWeight,
                        explanation: "\(name) \(String(format: "%.1f", tv))\(unit)，\(direction) 基线 \(String(format: "%.1f", bv))\(unit)"
                    ))
                }
            }
        }

        // If no recovery data at all, return neutral
        if activeWeight == 0 {
            return (50 * weight, [
                BudgetFactor(
                    metric: .sleepHours,
                    contribution: 0,
                    weight: weight,
                    explanation: zh ? "恢复数据缺失，无法评分" : "Recovery data missing, cannot score"
                )
            ])
        }

        // Scale to full weight
        let scaled = totalScore / activeWeight * weight
        return (scaled, factors)
    }

    // MARK: - Activity pillar (steps, exercise minutes)

    private func computeActivityPillar(
        today: DailyHealthMetrics,
        baseline: HealthBaseline,
        weight: Double,
        zh: Bool
    ) -> (Double, [BudgetFactor]) {
        var factors: [BudgetFactor] = []
        var totalScore: Double = 0
        var activeWeight: Double = 0

        let subWeight = weight / 2.0

        // Steps
        if let todaySteps = today.steps, let baselineSteps = baseline.averageSteps, baselineSteps > 0 {
            activeWeight += subWeight
            let ratio = todaySteps / baselineSteps
            // Optimal range: 80%-120% of baseline
            let subscore: Double
            if ratio >= 0.8 && ratio <= 1.2 {
                subscore = 85  // in the sweet spot
            } else if ratio < 0.8 {
                subscore = max(20, 50 + (ratio - 0.5) * 100)  // penalize very low activity
            } else {
                subscore = max(60, 100 - (ratio - 1.2) * 50)  // slight penalty for very high
            }
            totalScore += subscore * subWeight

            if abs(ratio - 1.0) > 0.1 {
                let contrib = (subscore - 50) * subWeight / 50 * weight
                let direction = ratio >= 1.0
                    ? (zh ? "高于" : "above")
                    : (zh ? "低于" : "below")
                factors.append(BudgetFactor(
                    metric: .steps,
                    contribution: contrib,
                    weight: subWeight,
                    explanation: zh
                        ? "步数 \(String(format: "%.0f", todaySteps))，\(direction) 基线 \(String(format: "%.0f", baselineSteps))"
                        : "Steps \(String(format: "%.0f", todaySteps)), \(direction) baseline \(String(format: "%.0f", baselineSteps))"
                ))
            }
        } else {
            // Missing: neutral reduced
            totalScore += 50 * subWeight * 0.3
            activeWeight += subWeight * 0.3
        }

        // Exercise minutes
        if let todayEx = today.exerciseMinutes, let baselineEx = baseline.averageExerciseMinutes, baselineEx > 0 {
            activeWeight += subWeight
            let ratio = todayEx / baselineEx
            let subscore: Double
            if ratio >= 0.7 && ratio <= 1.3 {
                subscore = 80
            } else if ratio < 0.7 {
                subscore = max(25, 50 + (ratio - 0.3) * 100)
            } else {
                subscore = max(60, 100 - (ratio - 1.3) * 40)
            }
            totalScore += subscore * subWeight

            if abs(ratio - 1.0) > 0.15 {
                let contrib = (subscore - 50) * subWeight / 50 * weight
                let direction = ratio >= 1.0
                    ? (zh ? "高于" : "above")
                    : (zh ? "低于" : "below")
                factors.append(BudgetFactor(
                    metric: .exerciseMinutes,
                    contribution: contrib,
                    weight: subWeight,
                    explanation: zh
                        ? "运动 \(String(format: "%.0f", todayEx)) 分钟，\(direction) 基线 \(String(format: "%.0f", baselineEx)) 分钟"
                        : "Exercise \(String(format: "%.0f", todayEx)) min, \(direction) baseline \(String(format: "%.0f", baselineEx)) min"
                ))
            }
        } else {
            totalScore += 50 * subWeight * 0.3
            activeWeight += subWeight * 0.3
        }

        if activeWeight == 0 {
            return (50 * weight, [])
        }

        let scaled = totalScore / activeWeight * weight
        return (scaled, factors)
    }

    // MARK: - Subjective pillar (energy, soreness, stress)

    private func computeSubjectivePillar(
        feedback: DailyFeedback?,
        weight: Double,
        zh: Bool
    ) -> (Double, [BudgetFactor]) {
        guard let fb = feedback else {
            return (50 * weight, [])
        }

        let subWeight = weight / 3.0
        var totalScore: Double = 0

        // Energy (1-10): higher = better, map to 0-100
        let energyScore = Double(fb.subjectiveEnergy) / 10.0 * 100
        totalScore += energyScore * subWeight

        // Soreness (1-10): lower = better, invert
        let sorenessScore = (11.0 - Double(fb.soreness)) / 10.0 * 100
        totalScore += sorenessScore * subWeight

        // Stress (1-10): lower = better, invert
        let stressScore = (11.0 - Double(fb.stress)) / 10.0 * 100
        totalScore += stressScore * subWeight

        let factors = [
            BudgetFactor(
                metric: .sleepHours,  // proxy for subjective
                contribution: (energyScore + sorenessScore + stressScore - 150) / 3.0 * weight / 50,
                weight: weight,
                explanation: zh
                    ? "精力 \(fb.subjectiveEnergy)/10 · 酸痛 \(fb.soreness)/10 · 压力 \(fb.stress)/10"
                    : "Energy \(fb.subjectiveEnergy)/10 · Soreness \(fb.soreness)/10 · Stress \(fb.stress)/10"
            )
        ]

        return (totalScore, factors)
    }

    // MARK: - Signal penalty

    private func computeSignalPenalty(
        signals: [HealthSignal],
        weight: Double,
        zh: Bool
    ) -> (Double, [BudgetFactor]) {
        guard !signals.isEmpty else { return (0, []) }

        var penalty: Double = 0
        var factors: [BudgetFactor] = []

        for signal in signals {
            let signalPenalty: Double
            switch signal.severity {
            case .high:   signalPenalty = weight * 35  // high severity = big penalty
            case .medium: signalPenalty = weight * 15
            case .low:    signalPenalty = weight * 5
            }
            penalty += signalPenalty

            let metric: HealthMetric
            switch signal.type {
            case .sleepLow:       metric = .sleepHours
            case .hrvLow:         metric = .hrv
            case .restingHeartHigh: metric = .restingHeartRate
            case .activityLow,
                 .activityHigh:   metric = .steps
            case .recoveryUncertainDueToMissingData: metric = .hrv
            }

            factors.append(BudgetFactor(
                metric: metric,
                contribution: -signalPenalty,
                weight: signalPenalty / penalty * weight,
                explanation: signal.explanation
            ))
        }

        // Cap total penalty at 100% of signal weight
        let capped = min(penalty, weight * 100)
        return (capped, factors)
    }
}
