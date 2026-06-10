//
//  PromptRegressionTester.swift
//  OHeas
//
//  Detects prompt regression by comparing snapshots.
//  通过比较快照检测提示词回归。
//


import Foundation

public struct PromptSnapshot: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var caseId: String
    public var promptHash: String
    public var modelName: String
    public var outputHash: String
    public var recommendation: CoachRecommendation
    public var safetyFlags: [SafetyFlag]
    public var createdAt: Date

    public init(id: UUID = UUID(), caseId: String, promptHash: String, modelName: String, outputHash: String, recommendation: CoachRecommendation, safetyFlags: [SafetyFlag], createdAt: Date = Date()) {
        self.id = id
        self.caseId = caseId
        self.promptHash = promptHash
        self.modelName = modelName
        self.outputHash = outputHash
        self.recommendation = recommendation
        self.safetyFlags = safetyFlags
        self.createdAt = createdAt
    }
}

public struct RegressionResult: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var caseId: String
    public var changed: Bool
    public var regressionDetected: Bool
    public var differences: [String]
    public var createdAt: Date

    public init(id: UUID = UUID(), caseId: String, changed: Bool, regressionDetected: Bool, differences: [String], createdAt: Date = Date()) {
        self.id = id
        self.caseId = caseId
        self.changed = changed
        self.regressionDetected = regressionDetected
        self.differences = differences
        self.createdAt = createdAt
    }
}

public struct PromptRegressionTester: Sendable {
    private let store: CodableFileStore<PromptSnapshot>?
    private let promptBuilder: CoachPromptBuilder
    private let runner: AgentEvaluationRunner

    public init(
        store: CodableFileStore<PromptSnapshot>? = nil,
        promptBuilder: CoachPromptBuilder = CoachPromptBuilder(),
        runner: AgentEvaluationRunner = AgentEvaluationRunner()
    ) {
        self.store = store
        self.promptBuilder = promptBuilder
        self.runner = runner
    }

    public func saveSnapshot(for evaluationCase: EvaluationCase, modelName: String = "rule_based") throws -> PromptSnapshot {
        let result = runner.run(evaluationCase)
        let recommendation = result.recommendation ?? RuleBasedRecommendationGenerator().generate(context: evaluationCase.inputContext)
        let prompt = (try? promptBuilder.buildPayload(context: evaluationCase.inputContext).userContextJSON) ?? evaluationCase.description
        let output = (try? JSONEncoder.oheasPretty.encode(recommendation)).flatMap { String(data: $0, encoding: .utf8) } ?? recommendation.title
        let snapshot = PromptSnapshot(
            caseId: evaluationCase.id,
            promptHash: StableHash.hash(prompt),
            modelName: modelName,
            outputHash: StableHash.hash(output),
            recommendation: recommendation,
            safetyFlags: result.safetyAssessment?.flags ?? []
        )
        if let store {
            var snapshots = try store.load()
            snapshots.append(snapshot)
            try store.save(snapshots)
        }
        return snapshot
    }

    public func compareWithLatestSnapshot(
        case evaluationCase: EvaluationCase,
        snapshots existing: [PromptSnapshot] = [],
        modelName: String = "rule_based"
    ) throws -> RegressionResult {
        let snapshots = store.map { (try? $0.load()) ?? [] } ?? existing
        guard let latest = snapshots.filter({ $0.caseId == evaluationCase.id }).sorted(by: { $0.createdAt < $1.createdAt }).last else {
            _ = try saveSnapshot(for: evaluationCase, modelName: modelName)
            return RegressionResult(caseId: evaluationCase.id, changed: false, regressionDetected: false, differences: ["Baseline created."])
        }

        let current = try saveSnapshot(for: evaluationCase, modelName: modelName)
        let differences = differences(between: latest, and: current)
        let regression = differences.contains { $0.contains("Regression") }
        return RegressionResult(
            caseId: evaluationCase.id,
            changed: latest.outputHash != current.outputHash || latest.promptHash != current.promptHash,
            regressionDetected: regression,
            differences: differences.isEmpty ? ["No key behavior change detected."] : differences
        )
    }

    public func runRegressionSuite(cases: [EvaluationCase] = EvaluationFixtures.builtInCases, modelName: String = "rule_based") throws -> [RegressionResult] {
        try cases.map { try compareWithLatestSnapshot(case: $0, modelName: modelName) }
    }

    public func compareSnapshots(previous: PromptSnapshot, current: PromptSnapshot) -> RegressionResult {
        let output = differences(between: previous, and: current)
        return RegressionResult(
            caseId: current.caseId,
            changed: previous.outputHash != current.outputHash || previous.promptHash != current.promptHash,
            regressionDetected: output.contains { $0.contains("Regression") },
            differences: output.isEmpty ? ["No key behavior change detected."] : output
        )
    }

    private func differences(between old: PromptSnapshot, and new: PromptSnapshot) -> [String] {
        var output: [String] = []
        if old.promptHash != new.promptHash {
            output.append("Prompt payload changed.")
        }
        if old.outputHash != new.outputHash {
            output.append("Recommendation output changed.")
        }
        if !old.recommendation.tomorrowVerification.isEmpty, new.recommendation.tomorrowVerification.isEmpty {
            output.append("Regression: tomorrow verification was removed.")
        }
        if !old.recommendation.evidence.isEmpty, new.recommendation.evidence.isEmpty {
            output.append("Regression: evidence explanation was removed.")
        }
        if old.safetyFlags.isEmpty, !new.safetyFlags.isEmpty {
            output.append("Regression: new safety flags appeared: \(new.safetyFlags.map { $0.type.rawValue }.joined(separator: ", ")).")
        }
        if old.recommendation.confidence != .low, new.recommendation.confidence == .low {
            output.append("Confidence changed to low; review whether this is expected.")
        }
        return output
    }
}

private enum StableHash {
    static func hash(_ value: String) -> String {
        let scalars = value.unicodeScalars.map(\.value)
        let result = scalars.reduce(UInt64(5_381)) { partial, scalar in
            ((partial << 5) &+ partial) &+ UInt64(scalar)
        }
        return String(result, radix: 16)
    }
}
