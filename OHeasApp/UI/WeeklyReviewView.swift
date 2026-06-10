//
//  WeeklyReviewView.swift
//  OHeas
//
//  WeeklyReviewView.swift — OHeas UI component.
//  WeeklyReviewView.swift — OHeas UI 组件。
//


import OHeasCore
import SwiftUI

struct WeeklyReviewView: View {
    @ObservedObject var viewModel: OHeasViewModel
    let language: AppLanguage

    var body: some View {
        NavigationStack {
            ScrollView {
                if let review = viewModel.weeklyReview {
                    VStack(alignment: .leading, spacing: 16) {
                        summaryCard(review)
                        textCard(title: language.text(.recoverySection), body: review.recoverySummary)
                        textCard(title: language.text(.activitySection), body: review.activitySummary)
                        textCard(title: language.text(.experimentSection), body: review.experimentSummary)
                        listCard(title: language.text(.learnedPattern), items: review.usefulPatterns)
                        listCard(title: language.text(.nextWeekSection), items: review.planAdjustmentsForNextWeek)
                    }
                    .padding()
                } else {
                    Text(language.text(.noReview))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(language.text(.weeklyReviewTab))
        }
    }

    private func summaryCard(_ review: WeeklyReview) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(language.text(.completionRate))
                .font(.headline)
            Text("\(Int(review.completionRate * 100))%")
                .font(.title2.weight(.semibold))
            Text(review.adherenceSummary)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("\(language.text(.dataConfidence)): \(language.confidence(review.confidence))")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func textCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func listCard(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    let viewModel = OHeasViewModel()
    WeeklyReviewView(viewModel: viewModel, language: .chinese)
}
