//
//  CoachInlineResponse.swift
//  OHeas
//
//  Inline quick-answer card shown below coach follow-up chips when a chip is tapped.
//  Provides a brief LLM-generated answer without leaving the Today tab.
//

import OHeasCore
import SwiftUI

struct InlineResponseCard: View {
    let response: CoachInlineResponse?
    let isLoading: Bool
    let language: AppLanguage
    let reduceMotion: Bool
    let onDismiss: () -> Void

    var body: some View {
        Group {
            if isLoading {
                loadingCard
            } else if let response {
                responseCard(response)
            }
        }
    }

    // MARK: - Loading

    private var loadingCard: some View {
        HStack(spacing: 10) {
            ProgressView()
                .scaleEffect(0.8)
            Text(language.text(.thinkingBriefLabel))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .background(OhColor.primaryBg)
        .clipShape(RoundedRectangle(cornerRadius: Radius.small))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.small)
                .strokeBorder(OhColor.primary.opacity(0.15), lineWidth: 1)
        )
        .transition(
            .move(edge: .top).combined(with: .opacity)
            .animation(reduceMotion ? nil : OhAnimation.appear())
        )
    }

    // MARK: - Response

    private func responseCard(_ response: CoachInlineResponse) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                // Left accent bar
                Rectangle()
                    .fill(OhColor.primary.opacity(0.5))
                    .frame(width: 3)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.tiny))
                    .padding(.trailing, 10)

                VStack(alignment: .leading, spacing: 8) {
                    // Header
                    HStack {
                        Label(language.text(.inlineResponseTitle), systemImage: "bubble.left.and.bubble.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(OhColor.primary)
                        Spacer()
                        Button {
                            withAnimation(reduceMotion ? nil : OhAnimation.appear()) {
                                onDismiss()
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(language.text(.chipDismissLabel))
                    }

                    // Response text
                    Text(response.responseText)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .background(OhColor.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: Radius.small))
        .shadow(color: .indigo.opacity(OhShadow.accentGlow.opacity * 0.5), radius: OhShadow.accentGlow.radius, y: OhShadow.accentGlow.y)
        .transition(
            .move(edge: .top).combined(with: .opacity)
            .animation(reduceMotion ? nil : OhAnimation.appear())
        )
    }
}
