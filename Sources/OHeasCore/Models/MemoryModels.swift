//
//  MemoryModels.swift
//  OHeas
//
//  User memory and pattern models for long-term learning.
//  用户记忆和模式模型，用于长期学习。
//


import Foundation

public struct UserMemory: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var userId: String
    public var preferences: UserPreferences
    public var constraints: [UserConstraint]
    public var knownPatterns: [KnownPattern]
    public var successfulInterventions: [InterventionMemory]
    public var ineffectiveInterventions: [InterventionMemory]
    public var riskNotes: [RiskNote]
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        userId: String = "local-user",
        preferences: UserPreferences = UserPreferences(),
        constraints: [UserConstraint] = [],
        knownPatterns: [KnownPattern] = [],
        successfulInterventions: [InterventionMemory] = [],
        ineffectiveInterventions: [InterventionMemory] = [],
        riskNotes: [RiskNote] = [],
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.preferences = preferences
        self.constraints = constraints
        self.knownPatterns = knownPatterns
        self.successfulInterventions = successfulInterventions
        self.ineffectiveInterventions = ineffectiveInterventions
        self.riskNotes = riskNotes
        self.updatedAt = updatedAt
    }
}

public struct UserPreferences: Codable, Equatable, Sendable {
    public var preferredWorkoutTypes: [String]
    public var dislikedWorkoutTypes: [String]
    public var preferredWorkoutTime: String?
    public var coachingTone: String?

    public init(
        preferredWorkoutTypes: [String] = [],
        dislikedWorkoutTypes: [String] = [],
        preferredWorkoutTime: String? = nil,
        coachingTone: String? = nil
    ) {
        self.preferredWorkoutTypes = preferredWorkoutTypes
        self.dislikedWorkoutTypes = dislikedWorkoutTypes
        self.preferredWorkoutTime = preferredWorkoutTime
        self.coachingTone = coachingTone
    }
}

public struct UserConstraint: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var type: String
    public var description: String
    public var source: String
    public var createdAt: Date

    public init(id: UUID = UUID(), type: String, description: String, source: String, createdAt: Date = Date()) {
        self.id = id
        self.type = type
        self.description = description
        self.source = source
        self.createdAt = createdAt
    }
}

public struct KnownPattern: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var title: String
    public var description: String
    public var relatedMetrics: [String]
    public var confidence: SignalSeverity
    public var evidenceCount: Int
    public var firstObservedAt: Date
    public var lastObservedAt: Date
    public var examples: [String]

    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        relatedMetrics: [String],
        confidence: SignalSeverity,
        evidenceCount: Int,
        firstObservedAt: Date,
        lastObservedAt: Date,
        examples: [String]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.relatedMetrics = relatedMetrics
        self.confidence = confidence
        self.evidenceCount = evidenceCount
        self.firstObservedAt = firstObservedAt
        self.lastObservedAt = lastObservedAt
        self.examples = examples
    }
}

public struct InterventionMemory: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var intervention: String
    public var observedEffect: String
    public var targetMetrics: [String]
    public var confidence: SignalSeverity
    public var evidenceCount: Int
    public var lastObservedAt: Date

    public init(
        id: UUID = UUID(),
        intervention: String,
        observedEffect: String,
        targetMetrics: [String],
        confidence: SignalSeverity,
        evidenceCount: Int,
        lastObservedAt: Date
    ) {
        self.id = id
        self.intervention = intervention
        self.observedEffect = observedEffect
        self.targetMetrics = targetMetrics
        self.confidence = confidence
        self.evidenceCount = evidenceCount
        self.lastObservedAt = lastObservedAt
    }
}

public struct RiskNote: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var description: String
    public var severity: SignalSeverity
    public var source: String
    public var createdAt: Date

    public init(id: UUID = UUID(), description: String, severity: SignalSeverity, source: String, createdAt: Date = Date()) {
        self.id = id
        self.description = description
        self.severity = severity
        self.source = source
        self.createdAt = createdAt
    }
}

public struct UserMemorySummary: Codable, Equatable, Sendable {
    public var knownPatternSummaries: [String]
    public var successfulInterventionSummaries: [String]
    public var ineffectiveInterventionSummaries: [String]
    public var riskNoteSummaries: [String]

    public init(memory: UserMemory) {
        knownPatternSummaries = memory.knownPatterns.prefix(5).map { "\($0.title): \($0.description)" }
        successfulInterventionSummaries = memory.successfulInterventions.prefix(5).map { "\($0.intervention): \($0.observedEffect)" }
        ineffectiveInterventionSummaries = memory.ineffectiveInterventions.prefix(5).map { "\($0.intervention): \($0.observedEffect)" }
        riskNoteSummaries = memory.riskNotes.prefix(3).map(\.description)
    }
}
