//
//  ChatFormatting.swift
//  OHeas
//
//  ChatFormatting.swift — view-layer formatting utilities for Chat.
//  Extracted from ChatViewModel to separate UI display logic from
//  business logic. These are pure functions with no state dependencies.
//

import OHeasCore
import Foundation

enum ChatFormatting {

    /// Produces a user-facing explanation for why health data is missing,
    /// used in system prompts and coach responses.
    static func localizedMissingReason(_ reason: String, language: AppLanguage) -> String {
        let lower = reason.lowercased()
        let zh = language == .chinese

        if lower.contains("sleep data has been missing") && lower.contains("consecutive days") {
            return zh ? "连续多天没有睡眠数据，建议检查 Apple Watch 睡眠设置" : "Sleep data has been missing for consecutive days — check Apple Watch sleep settings"
        }
        if lower.contains("sleep data") && lower.contains("missing") {
            return zh ? "睡眠数据缺失，可能昨晚未佩戴手表或设置未开启" : "Sleep data is missing — the watch may not have been worn or sleep tracking is off"
        }
        if lower.contains("recovery data") && lower.contains("missing") && lower.contains("consecutive") {
            return zh ? "连续多天缺少恢复数据，建议检查佩戴情况" : "Recovery data has been missing for consecutive days — check watch wear"
        }
        if lower.contains("hrv") && lower.contains("missing") {
            return zh ? "HRV 数据缺失，建议白天正常佩戴 Apple Watch" : "HRV data is missing — wear your Apple Watch during the day"
        }
        if lower.contains("activity") && lower.contains("missing") {
            return zh ? "活动数据缺失，建议检查运动与健身权限" : "Activity data is missing — check Motion & Fitness permissions"
        }
        if lower.contains("baseline") {
            return zh ? "基线数据不足，需要更多天数据才能给出可靠的对比建议" : "Baseline data is insufficient — more days needed for reliable comparisons"
        }
        if lower.contains("sync") {
            return zh ? "数据同步可能延迟，建议稍后再查看" : "Data sync may be delayed — check back shortly"
        }
        return zh
            ? "数据覆盖不足，建议保持保守解读"
            : "Data coverage is limited — interpret conservatively"
    }
}
