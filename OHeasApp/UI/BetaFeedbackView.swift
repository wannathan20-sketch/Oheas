//
//  BetaFeedbackView.swift
//  OHeas
//
//  BetaFeedbackView.swift — OHeas UI component.
//  BetaFeedbackView.swift — OHeas UI 组件。
//


import OHeasCore
import SwiftUI

struct BetaFeedbackView: View {
    @ObservedObject var viewModel: OHeasViewModel

    @AppStorage("oheas.language") private var languageRawValue = AppLanguage.chinese.rawValue
    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .chinese
    }

    @State private var wasHelpful: Helpfulness = .notRated
    @State private var wasUnderstandable: Understandability = .notRated
    @State private var feltIntrusive: IntrusionLevel = .notRated
    @State private var privacyConcern: PrivacyConcern = .notRated
    @State private var freeText: String = ""
    @State private var showConfirmation = false
    @State private var previouslySubmitted: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                if previouslySubmitted {
                    Section {
                        Label(language.text(.betaFeedbackThanks), systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } footer: {
                        Text(language.text(.feedbackResubmitNote))
                    }
                }

                Section {
                    Picker(language.text(.betaFeedbackHelpfulQuestion), selection: $wasHelpful) {
                        ForEach(Helpfulness.allCases, id: \.self) { v in Text(v.label(for: language)).tag(v) }
                    }

                    Picker(language.text(.betaFeedbackUnderstandableQuestion), selection: $wasUnderstandable) {
                        ForEach(Understandability.allCases, id: \.self) { v in Text(v.label(for: language)).tag(v) }
                    }

                    Picker(language.text(.betaFeedbackIntrusiveQuestion), selection: $feltIntrusive) {
                        ForEach(IntrusionLevel.allCases, id: \.self) { v in Text(v.label(for: language)).tag(v) }
                    }

                    Picker(language.text(.betaFeedbackPrivacyQuestion), selection: $privacyConcern) {
                        ForEach(PrivacyConcern.allCases, id: \.self) { v in Text(v.label(for: language)).tag(v) }
                    }
                } header: {
                    Text(language.text(.quickFeedback))
                } footer: {
                    Text(language.text(.feedbackDescription))
                }

                Section {
                    TextField(language.text(.betaFeedbackFreeTextPlaceholder), text: $freeText, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section {
                    Button {
                        submit()
                    } label: {
                        Label(language.text(.betaFeedbackSubmit), systemImage: "paperplane")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSubmit)
                } footer: {
                    Text(language.text(.feedbackStorageNote))
                        .font(.caption)
                }
            }
            .navigationTitle(language.text(.betaFeedbackNavTitle))
            .alert(language.text(.betaFeedbackSubmittedTitle), isPresented: $showConfirmation) {
                Button(language.text(.betaFeedbackOK), role: .cancel) {}
            } message: {
                Text(language.text(.feedbackThankYou))
            }
            .onAppear {
                previouslySubmitted = BetaFeedbackStore.hasSubmittedToday()
            }
        }
    }

    private var canSubmit: Bool {
        wasHelpful != .notRated || wasUnderstandable != .notRated || feltIntrusive != .notRated || privacyConcern != .notRated || !freeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submit() {
        let feedback = BetaFeedbackEntry(
            date: Date(),
            wasHelpful: wasHelpful,
            wasUnderstandable: wasUnderstandable,
            feltIntrusive: feltIntrusive,
            privacyConcern: privacyConcern,
            freeText: freeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : freeText
        )
        BetaFeedbackStore.save(feedback)
        previouslySubmitted = true
        showConfirmation = true

        if viewModel.hasConsent(.betaAnalytics) {
            viewModel.recordConsent(.betaAnalytics, accepted: true)
            // Recording this is a no-op if already consented; the event just gets stored locally
            let _ = viewModel // accessibility for analytics
        }
    }
}

// MARK: - Data types

enum Helpfulness: String, Codable, CaseIterable {
    case notRated = ""
    case veryHelpful = "very_helpful"
    case somewhatHelpful = "somewhat_helpful"
    case notHelpful = "not_helpful"
    case didNotApply = "did_not_apply"

    func label(for language: AppLanguage) -> String {
        switch self {
        case .notRated: return "—"
        case .veryHelpful: return language.text(.feedbackVeryHelpful)
        case .somewhatHelpful: return language.text(.feedbackSomewhatHelpful)
        case .notHelpful: return language.text(.feedbackNotHelpful)
        case .didNotApply: return language.text(.feedbackDidNotApply)
        }
    }
}

enum Understandability: String, Codable, CaseIterable {
    case notRated = ""
    case easy = "easy"
    case okay = "okay"
    case confusing = "confusing"

    func label(for language: AppLanguage) -> String {
        switch self {
        case .notRated: return "—"
        case .easy: return language.text(.feedbackEasy)
        case .okay: return language.text(.feedbackOkay)
        case .confusing: return language.text(.feedbackConfusing)
        }
    }
}

enum IntrusionLevel: String, Codable, CaseIterable {
    case notRated = ""
    case notAtAll = "not_at_all"
    case aLittle = "a_little"
    case tooMuch = "too_much"

    func label(for language: AppLanguage) -> String {
        switch self {
        case .notRated: return "—"
        case .notAtAll: return language.text(.feedbackNotAtAll)
        case .aLittle: return language.text(.feedbackALittle)
        case .tooMuch: return language.text(.feedbackTooMuch)
        }
    }
}

enum PrivacyConcern: String, Codable, CaseIterable {
    case notRated = ""
    case none = "none"
    case mild = "mild"
    case significant = "significant"

    func label(for language: AppLanguage) -> String {
        switch self {
        case .notRated: return "—"
        case .none: return language.text(.feedbackNoConcerns)
        case .mild: return language.text(.feedbackMildConcern)
        case .significant: return language.text(.feedbackSignificantConcern)
        }
    }
}

struct BetaFeedbackEntry: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var date: Date
    var wasHelpful: Helpfulness
    var wasUnderstandable: Understandability
    var feltIntrusive: IntrusionLevel
    var privacyConcern: PrivacyConcern
    var freeText: String?
}

// MARK: - Local persistence

enum BetaFeedbackStore {
    private static var fileURL: URL {
        OHeasStorageURLs.betaFeedback
    }

    static func save(_ entry: BetaFeedbackEntry) {
        var entries = load()
        // Replace today's entry if already submitted
        entries.removeAll { Calendar.current.isDate($0.date, inSameDayAs: entry.date) }
        entries.append(entry)
        if let data = try? JSONEncoder.oheasPretty.encode(entries) {
            try? data.write(to: fileURL, options: [.atomic])
        }
    }

    static func load() -> [BetaFeedbackEntry] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder.oheas.decode([BetaFeedbackEntry].self, from: data)) ?? []
    }

    static func hasSubmittedToday() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return load().contains { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }
}

// MARK: - Storage URL support

extension OHeasStorageURLs {
    static var betaFeedback: URL {
        baseDirectory.appendingPathComponent("beta_feedback.json")
    }
}

#if DEBUG
#Preview {
    BetaFeedbackView(viewModel: OHeasViewModel())
}
#endif
