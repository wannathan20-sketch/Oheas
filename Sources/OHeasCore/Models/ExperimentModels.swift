//
//  ExperimentModels.swift
//  OHeas
//
//  Personal experiment models — hypothesis, check-in, and evaluation.
//  个人实验模型 — 假设、签到和评估。
//


import Foundation

public enum ExperimentStatus: String, Codable, CaseIterable, Sendable {
    case proposed
    case active
    case completed
    case paused
    case cancelled
}

public struct PersonalExperiment: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var title: String
    public var hypothesis: String
    public var intervention: String
    public var durationDays: Int
    public var startDate: Date
    public var endDate: Date
    public var targetMetrics: [String]
    public var status: ExperimentStatus
    public var dailyCheckins: [ExperimentCheckin]
    public var result: ExperimentResult?
    public var createdFromPatternId: String?
    public var whyThisExperiment: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        hypothesis: String,
        intervention: String,
        durationDays: Int = 5,
        startDate: Date,
        endDate: Date,
        targetMetrics: [String],
        status: ExperimentStatus = .proposed,
        dailyCheckins: [ExperimentCheckin] = [],
        result: ExperimentResult? = nil,
        createdFromPatternId: String? = nil,
        whyThisExperiment: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.hypothesis = hypothesis
        self.intervention = intervention
        self.durationDays = durationDays
        self.startDate = startDate
        self.endDate = endDate
        self.targetMetrics = targetMetrics
        self.status = status
        self.dailyCheckins = dailyCheckins
        self.result = result
        self.createdFromPatternId = createdFromPatternId
        self.whyThisExperiment = whyThisExperiment
        self.createdAt = createdAt
    }
}

public struct ExperimentCheckin: Codable, Equatable, Identifiable, Sendable {
    public var id: String { ISO8601DateFormatter.oheasString(from: date) }
    public var date: Date
    public var completed: Bool
    public var note: String?
    public var subjectiveEnergy: Int?
    public var createdAt: Date

    public init(date: Date, completed: Bool, note: String? = nil, subjectiveEnergy: Int? = nil, createdAt: Date = Date()) {
        self.date = date
        self.completed = completed
        self.note = note
        self.subjectiveEnergy = subjectiveEnergy
        self.createdAt = createdAt
    }
}

public struct ExperimentResult: Codable, Equatable, Sendable {
    public var outcome: VerificationOutcome
    public var confidence: ConfidenceLevel
    public var summary: String
    public var evidence: [String]
    public var learnedPatternCandidate: String?

    public init(
        outcome: VerificationOutcome,
        confidence: ConfidenceLevel,
        summary: String,
        evidence: [String],
        learnedPatternCandidate: String? = nil
    ) {
        self.outcome = outcome
        self.confidence = confidence
        self.summary = summary
        self.evidence = evidence
        self.learnedPatternCandidate = learnedPatternCandidate
    }
}
