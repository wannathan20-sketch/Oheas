//
//  TodayContentSection.swift
//  OHeas
//
//  Lightweight section wrapper — title + SF Symbol + content.
//  Unifies the Label(...).font(.subheadline.weight(.semibold)) pattern
//  used across Today sub-views.
//

import SwiftUI

/// A labeled content section with a title, SF Symbol icon, and content area.
///
/// Use this to wrap logical groups of content on the Today page, replacing
/// ad-hoc `Label + VStack` patterns for consistent visual hierarchy.
struct TodayContentSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            content()
        }
    }
}

// MARK: - Previews

#Preview("Section with content") {
    VStack(spacing: 20) {
        TodayContentSection(title: "Recovery Metrics", systemImage: "heart.fill") {
            Text("Sleep: 7.2h")
            Text("HRV: 48ms")
        }
        TodayContentSection(title: "Today's Plan", systemImage: "calendar") {
            Text("Light walk · 30 min")
        }
    }
    .padding()
}
