//
//  StreakFlameView.swift
//  OHeas
//
//  Animated flame icon showing streak count. Grows with longer streaks.
//  Pulses at milestone counts (7, 30, 100).
//

import SwiftUI

struct StreakFlameView: View {
    let count: Int
    let language: AppLanguage
    let reduceMotion: Bool

    @State private var previousCount: Int = 0
    @State private var pulseTrigger = false

    private var flameScale: CGFloat {
        if count >= 100 { 1.5 }
        else if count >= 30 { 1.3 }
        else if count >= 7 { 1.15 }
        else { 1.0 }
    }

    private var flameColor: Color {
        if count >= 30 { .orange }
        else if count >= 7 { .yellow }
        else { .secondary }
    }

    private var isMilestone: Bool {
        (count == 7 || count == 30 || count == 100) && count > previousCount
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14 * flameScale))
                .foregroundStyle(flameColor)
                .scaleEffect(pulseTrigger ? flameScale * 1.3 : flameScale)
                .animation(
                    reduceMotion ? nil : OhAnimation.pulse.repeatCount(3, autoreverses: true),
                    value: pulseTrigger
                )
            Text("\(count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
        }
        .onAppear {
            previousCount = count
        }
        .onChange(of: count) { _, newCount in
            if isMilestone {
                pulseTrigger = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    pulseTrigger = false
                }
            }
            previousCount = newCount
        }
        .accessibilityLabel("\(language.text(.currentStreak)): \(count) \(language.text(.daysUnit))")
    }
}
