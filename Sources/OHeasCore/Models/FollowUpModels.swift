//
//  FollowUpModels.swift
//  OHeas
//
//  Coach follow-up chip and inline response models.
//  Data-driven follow-up questions that appear below the AI coach card.
//

import Foundation

// MARK: - Chip Category

/// Semantic category for follow-up chips, used to pick the right SF Symbol and color.
public enum ChipCategory: String, Codable, Sendable {
    case recovery
    case tomorrowPlan
    case details
    case historicalValidation
    case general
}

// MARK: - Chip Action

/// What happens when a user taps a follow-up chip.
public enum ChipAction: Codable, Equatable, Sendable {
    /// Ask a question and show the answer inline below the coach card.
    case askQuestion(String)
    /// Navigate to the Chat tab with a pre-filled prompt.
    case navigateToChat(String)

    /// The question or prompt text (English, for LLM).
    public var promptText: String {
        switch self {
        case .askQuestion(let q): return q
        case .navigateToChat(let q): return q
        }
    }
}

// MARK: - CoachFollowUpChip

/// A tappable suggestion chip shown below the AI coach recommendation card.
public struct CoachFollowUpChip: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    /// AppLanguage TextKey for the chip's display label.
    public var labelKey: String
    /// Semantic category for icon and color selection.
    public var category: ChipCategory
    /// The action to perform on tap.
    public var action: ChipAction

    public init(
        id: UUID = UUID(),
        labelKey: String,
        category: ChipCategory,
        action: ChipAction
    ) {
        self.id = id
        self.labelKey = labelKey
        self.category = category
        self.action = action
    }
}

// MARK: - CoachInlineResponse

/// A brief inline answer shown when a follow-up chip is tapped.
public struct CoachInlineResponse: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var chipId: UUID
    public var responseText: String
    public var timestamp: Date

    public init(
        id: UUID = UUID(),
        chipId: UUID,
        responseText: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.chipId = chipId
        self.responseText = responseText
        self.timestamp = timestamp
    }
}
