//
//  SafetyGuardrail.swift
//  OHeas
//
//  Two-level safety check: L1 regex (0ms) + L2 LLM semantic deep review.
//  双级安全检查：L1 正则（零延迟）+ L2 LLM 语义深度审查。
//


import Foundation

public struct SafetyGuardrail: Sendable {
    public init() {}

    // MARK: - L1: Regex-based fast check (0 latency)

    public func assess(
        text: String,
        checkedEntityId: String,
        entityType: SafetyEntityType,
        dataQuality: DataQualityReport? = nil,
        recoveryIsLow: Bool = false,
        plannedIntensity: PlanIntensity? = nil
    ) -> SafetyAssessment {
        let flags = flags(
            in: text,
            dataQuality: dataQuality,
            recoveryIsLow: recoveryIsLow,
            plannedIntensity: plannedIntensity
        )
        let riskLevel = riskLevel(for: flags)
        let sanitized = riskLevel == .safe ? nil : sanitizedText(from: text, flags: flags)

        return SafetyAssessment(
            checkedEntityId: checkedEntityId,
            entityType: entityType,
            riskLevel: riskLevel,
            flags: flags,
            sanitizedText: sanitized
        )
    }

    // MARK: - L2: LLM-based deep semantic check (triggered when L1 is .caution or text is long)

    /// Performs a deeper semantic safety review using an LLM client.
    /// Recommended to call only when L1 `assess()` returns `.caution` or the text exceeds 200 characters.
    /// Falls back to the L1 assessment if the LLM call fails.
    public func deepAssess(
        text: String,
        checkedEntityId: String,
        entityType: SafetyEntityType,
        l1Assessment: SafetyAssessment,
        dataQuality: DataQualityReport? = nil,
        recoveryIsLow: Bool = false,
        client: LLMClientProtocol?
    ) async -> SafetyAssessment {
        guard let client else { return l1Assessment }

        let prompt = deepSafetyPrompt(text: text, entityType: entityType, l1Flags: l1Assessment.flags)

        do {
            let payload = CoachPromptPayload(systemPrompt: prompt, userContextJSON: "{}")
            let raw = try await client.generateRecommendationJSON(payload: payload)

            // Parse the LLM's safety verdict
            if let data = raw.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let hasIssue = json["has_safety_issue"] as? Bool ?? false
                let riskStr = json["risk_level"] as? String ?? "safe"
                let finding = json["finding"] as? String ?? ""

                if hasIssue {
                    let riskLevel: SafetyRiskLevel = riskStr == "unsafe" ? .unsafe : .caution
                    var flags = l1Assessment.flags
                    if !finding.isEmpty {
                        flags.append(SafetyFlag(
                            type: .missingDisclaimer,
                            excerpt: String(text.prefix(200)),
                            explanation: finding,
                            suggestedRewrite: "Semantic safety review flagged: \(finding). Ensure lifestyle-guidance boundary and avoid medical/overconfident language."
                        ))
                    }
                    return SafetyAssessment(
                        checkedEntityId: checkedEntityId,
                        entityType: entityType,
                        riskLevel: riskLevel,
                        flags: flags,
                        sanitizedText: flags.isEmpty ? nil : sanitizedText(from: text, flags: flags)
                    )
                }
            }
        } catch {
            // L2 failed — fall back to L1 assessment
        }

        return l1Assessment
    }

    /// Whether a deep assessment is recommended based on L1 results and text characteristics.
    public func shouldDeepAssess(l1Assessment: SafetyAssessment, textLength: Int) -> Bool {
        l1Assessment.riskLevel == .caution || textLength > 200
    }

    private func deepSafetyPrompt(text: String, entityType: SafetyEntityType, l1Flags: [SafetyFlag]) -> String {
        """
        You are a safety reviewer for a health lifestyle coaching agent. Your job is to check whether a piece of text contains safety issues that could harm users.

        Review the following text (entity type: \(entityType.rawValue)) for these risks:
        1. Medical diagnosis language (implying the user has a disease)
        2. Emergency symptom descriptions (chest pain, fainting, etc.) without proper medical referral
        3. Overconfident claims (guaranteed, will definitely improve, proven)
        4. Unsafe weight loss or diet advice
        5. Supplement or medication recommendations
        6. High-intensity exercise advice when recovery is low
        7. Missing disclaimer that this is lifestyle guidance, not medical advice

        L1 regex flags already detected: \(l1Flags.map(\.type.rawValue).joined(separator: ", "))

        Text to review:
        ---
        \(text)
        ---

        Return JSON:
        {
          "has_safety_issue": true/false,
          "risk_level": "safe" | "caution" | "unsafe",
          "finding": "Brief explanation if issue found, empty if safe."
        }
        """
    }

    // MARK: - Sanitize methods

    public func sanitize(
        recommendation: CoachRecommendation,
        context: AgentContext
    ) -> (CoachRecommendation, SafetyAssessment) {
        let recoveryIsLow = context.detectedSignals.contains {
            [.sleepLow, .hrvLow, .restingHeartHigh, .activityHigh].contains($0.type)
        } || recommendation.state == .recoveryLow || recommendation.state == .overloaded
        let text = [
            recommendation.title,
            recommendation.summary,
            recommendation.recommendation,
            recommendation.tonightAction,
            recommendation.safetyNote ?? ""
        ].joined(separator: "\n")
        let assessment = assess(
            text: text,
            checkedEntityId: recommendation.id.uuidString,
            entityType: .recommendation,
            dataQuality: context.dataQuality,
            recoveryIsLow: recoveryIsLow
        )
        guard assessment.riskLevel != .safe else { return (recommendation, assessment) }

        var sanitized = recommendation
        sanitized.summary = conservativeSummary(for: recommendation, assessment: assessment, confidence: context.dataQuality.overallConfidence)
        sanitized.recommendation = safeAction(for: recommendation, recoveryIsLow: recoveryIsLow)
        sanitized.tonightAction = "Keep the evening low-risk and avoid pushing intensity; seek qualified care for urgent or unusual symptoms."
        sanitized.safetyNote = "Adjusted for safety boundaries. Lifestyle guidance only; not medical advice."
        return (sanitized, assessment)
    }

    public func sanitize(plan: WeeklyPlan, context: AgentContext) -> (WeeklyPlan, SafetyAssessment) {
        let recoveryIsLow = context.detectedSignals.contains {
            [.sleepLow, .hrvLow, .restingHeartHigh].contains($0.type)
        } || context.dataQuality.overallConfidence == .low
        let text = ([plan.strategySummary, plan.generatedFromContextSummary] + plan.days.flatMap { [$0.title, $0.description, $0.safetyNote ?? ""] })
            .joined(separator: "\n")
        let maxIntensity = plan.days.contains { $0.intensity == .high } ? PlanIntensity.high : nil
        let assessment = assess(
            text: text,
            checkedEntityId: plan.id.uuidString,
            entityType: .weeklyPlan,
            dataQuality: context.dataQuality,
            recoveryIsLow: recoveryIsLow,
            plannedIntensity: maxIntensity
        )
        guard assessment.riskLevel != .safe else { return (plan, assessment) }

        var sanitized = plan
        sanitized.strategySummary = "Plan adjusted to stay conservative when recovery or data confidence is limited."
        sanitized.days = sanitized.days.map { day in
            guard recoveryIsLow, day.intensity == .high || day.intensity == .medium else { return day }
            var copy = day
            copy.planType = .lightActivity
            copy.title = "Recovery-friendly activity"
            copy.description = "Keep effort easy; choose mobility or an easy walk."
            copy.intensity = .low
            copy.estimatedDurationMinutes = min(copy.estimatedDurationMinutes, 20)
            copy.adjustmentReason = "Safety guardrail reduced intensity because recovery or data confidence is limited."
            copy.safetyNote = "Adjusted for safety boundaries. Lifestyle guidance only."
            return copy
        }
        return (sanitized, assessment)
    }

    public func sanitize(experiment: PersonalExperiment, dataQuality: DataQualityReport) -> (PersonalExperiment, SafetyAssessment) {
        let text = [experiment.title, experiment.hypothesis, experiment.intervention, experiment.whyThisExperiment].joined(separator: "\n")
        let assessment = assess(
            text: text,
            checkedEntityId: experiment.id.uuidString,
            entityType: .experiment,
            dataQuality: dataQuality
        )
        guard assessment.riskLevel != .safe else { return (experiment, assessment) }

        var sanitized = experiment
        sanitized.hypothesis = "This low-risk lifestyle experiment may help explore a pattern, but results will be observational."
        sanitized.intervention = "Use a small, low-risk routine change and track sleep, HRV, resting heart rate, and subjective energy."
        sanitized.whyThisExperiment = "Adjusted to avoid medical, supplement, medication, or overconfident claims."
        return (sanitized, assessment)
    }

    public func sanitize(review: WeeklyReview) -> (WeeklyReview, SafetyAssessment) {
        let text = [
            review.adherenceSummary,
            review.recoverySummary,
            review.activitySummary,
            review.experimentSummary
        ].joined(separator: "\n")
        let assessment = assess(
            text: text,
            checkedEntityId: review.id.uuidString,
            entityType: .review
        )
        guard assessment.riskLevel != .safe else { return (review, assessment) }

        var sanitized = review
        sanitized.experimentSummary = "Observed trends are limited and should be treated as lifestyle signals, not proof of medical effect."
        sanitized.planAdjustmentsForNextWeek.insert("Keep next steps conservative and verify with future data.", at: 0)
        return (sanitized, assessment)
    }

    private func flags(
        in text: String,
        dataQuality: DataQualityReport?,
        recoveryIsLow: Bool,
        plannedIntensity: PlanIntensity?
    ) -> [SafetyFlag] {
        var output: [SafetyFlag] = []
        let lower = text.lowercased()

        output.append(contentsOf: phraseFlags(
            lower: lower,
            original: text,
            phrases: ["你患有", "你有糖尿病", "你有高血压", "诊断为", "diagnosed with", "you have disease", "you have hypertension"],
            type: .medicalDiagnosis,
            explanation: "The agent must not diagnose disease.",
            rewrite: "Use non-diagnostic language and suggest qualified medical care when appropriate."
        ))

        output.append(contentsOf: phraseFlags(
            lower: lower,
            original: text,
            phrases: ["胸痛", "晕厥", "昏厥", "持续异常心率", "chest pain", "fainting", "syncope", "persistent abnormal heart rate"],
            type: .emergencySymptom,
            explanation: "High-risk symptoms need medical triage language.",
            rewrite: "If this is current, severe, or unusual, contact emergency services or a qualified clinician."
        ))

        output.append(contentsOf: phraseFlags(
            lower: lower,
            original: text,
            phrases: ["证明有效", "一定会改善", "guaranteed", "will definitely", "proves this works", "proven to improve"],
            type: .overconfidentClaim,
            explanation: "Lifestyle coaching must not promise outcomes.",
            rewrite: "Say this may help and should be verified with future data."
        ))

        output.append(contentsOf: phraseFlags(
            lower: lower,
            original: text,
            phrases: ["因果", "caused by", "because your", "this caused"],
            type: .unsupportedCausalClaim,
            explanation: "Single-user observational data should not be framed as proven causality.",
            rewrite: "Describe the signal as an observed association or possible pattern."
        ))

        output.append(contentsOf: phraseFlags(
            lower: lower,
            original: text,
            phrases: ["减到每天500卡", "极端节食", "skip meals", "crash diet", "very low calorie"],
            type: .unsafeWeightLossAdvice,
            explanation: "Extreme dieting advice is unsafe.",
            rewrite: "Use sustainable, non-extreme lifestyle suggestions."
        ))

        output.append(contentsOf: phraseFlags(
            lower: lower,
            original: text,
            phrases: ["服用", "药物", "补剂", "supplement", "medication", "take ibuprofen", "take melatonin"],
            type: .supplementOrMedicationAdvice,
            explanation: "The agent should not recommend medication or supplements.",
            rewrite: "Remove medication/supplement advice and suggest discussing it with a clinician."
        ))

        if let dataQuality, dataQuality.overallConfidence == .low {
            let strongWords = ["must", "clearly", "definitely", "一定", "必然", "明确说明"]
            if let match = strongWords.first(where: { lower.contains($0.lowercased()) }) {
                output.append(SafetyFlag(
                    type: .overconfidentClaim,
                    excerpt: excerpt(containing: match, in: text),
                    explanation: "Low-confidence data requires conservative language.",
                    suggestedRewrite: "State that data is limited and offer one low-risk option or one follow-up question."
                ))
            }
        }

        let intensityText = ["high intensity", "hard intervals", "all-out", "冲刺", "高强度", "间歇训练"]
        if recoveryIsLow, plannedIntensity == .high || intensityText.contains(where: { lower.contains($0) }) {
            output.append(SafetyFlag(
                type: .highIntensityWhenRecoveryLow,
                excerpt: excerpt(containing: intensityText.first(where: { lower.contains($0) }) ?? "high", in: text),
                explanation: "High intensity is not appropriate when recovery appears low or uncertain.",
                suggestedRewrite: "Downgrade to rest, mobility, or easy activity."
            ))
        }

        let hasDisclaimer = lower.contains("not medical advice") || lower.contains("不是医疗建议") || lower.contains("not a medical diagnosis")
        if !hasDisclaimer, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            output.append(SafetyFlag(
                type: .missingDisclaimer,
                excerpt: String(text.prefix(120)),
                explanation: "Health coaching output should make the lifestyle boundary clear.",
                suggestedRewrite: "Add a short lifestyle-guidance disclaimer."
            ))
        }

        return output
    }

    private func phraseFlags(
        lower: String,
        original: String,
        phrases: [String],
        type: SafetyFlagType,
        explanation: String,
        rewrite: String
    ) -> [SafetyFlag] {
        phrases.compactMap { phrase in
            lower.contains(phrase.lowercased())
                ? SafetyFlag(type: type, excerpt: excerpt(containing: phrase, in: original), explanation: explanation, suggestedRewrite: rewrite)
                : nil
        }
    }

    private func riskLevel(for flags: [SafetyFlag]) -> SafetyRiskLevel {
        if flags.contains(where: { [.medicalDiagnosis, .emergencySymptom, .highIntensityWhenRecoveryLow, .unsafeWeightLossAdvice, .supplementOrMedicationAdvice].contains($0.type) }) {
            return .unsafe
        }
        if flags.isEmpty { return .safe }
        return .caution
    }

    private func sanitizedText(from text: String, flags: [SafetyFlag]) -> String {
        var lines = flags.map(\.suggestedRewrite)
        lines.append("Lifestyle guidance only; this is not medical advice.")
        if flags.contains(where: { $0.type == .emergencySymptom }) {
            lines.insert("For chest pain, fainting, or persistent abnormal heart rate, seek urgent medical help or contact a qualified clinician.", at: 0)
        }
        if lines.isEmpty {
            return text
        }
        return Array(Set(lines)).sorted().joined(separator: " ")
    }

    private func conservativeSummary(for recommendation: CoachRecommendation, assessment: SafetyAssessment, confidence: ConfidenceLevel) -> String {
        if confidence == .low {
            return "Available data is limited, so this recommendation has been adjusted to stay conservative and easy to verify."
        }
        if assessment.flags.contains(where: { $0.type == .emergencySymptom }) {
            return "This output mentioned a higher-risk symptom, so the advice has been narrowed to safety-first guidance."
        }
        return "This recommendation has been adjusted to avoid overconfident or medical language."
    }

    private func safeAction(for recommendation: CoachRecommendation, recoveryIsLow: Bool) -> String {
        if recoveryIsLow {
            return "Choose a low-risk recovery option today: easy mobility, an easy walk, hydration, and no intensity push."
        }
        return "Choose one small, low-risk lifestyle action today and verify how you feel tomorrow."
    }

    private func excerpt(containing phrase: String, in text: String) -> String {
        let lower = text.lowercased()
        guard let range = lower.range(of: phrase.lowercased()) else {
            return String(text.prefix(120))
        }
        let start = text.index(range.lowerBound, offsetBy: -30, limitedBy: text.startIndex) ?? text.startIndex
        let end = text.index(range.upperBound, offsetBy: 60, limitedBy: text.endIndex) ?? text.endIndex
        return String(text[start..<end])
    }
}
