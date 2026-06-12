//
//  ScoreCategoryBadge.swift
//  OHeas
//
//  Small colored capsule badge showing the Body Budget Score category.
//  显示身体预算评分分类的小型彩色胶囊徽章。
//

import SwiftUI
import OHeasCore

/// A small colored capsule showing the score category (Excellent / Good / Fair / Strained / Depleted).
struct ScoreCategoryBadge: View {
    let category: BudgetCategory
    let language: AppLanguage

    var body: some View {
        Text(language.budgetCategory(category))
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch category {
        case .excellent: OhColor.success
        case .good:      OhColor.recovery
        case .fair:      OhColor.warning
        case .strained:  OhColor.warning
        case .depleted:  OhColor.danger
        }
    }
}
