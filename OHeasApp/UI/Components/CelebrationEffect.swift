//
//  CelebrationEffect.swift
//  OHeas
//
//  Confetti celebration overlay shown when a new badge is unlocked.
//  Uses TimelineView + Canvas for particle animation. Falls back to a simple
//  banner when Reduce Motion is enabled.
//

import SwiftUI

struct CelebrationEffect: View {
    @Binding var show: Bool
    let badgeName: String
    let language: AppLanguage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let particleCount = 36
    private let colors: [Color] = [
        OhColor.success, OhColor.primary, OhColor.warning,
        OhColor.info, .pink, .orange, .yellow
    ]

    var body: some View {
        if reduceMotion {
            reducedMotionBanner
        } else {
            fullConfetti
        }
    }

    // MARK: - Full Confetti

    private var fullConfetti: some View {
        ZStack {
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    let seed = now.remainder(dividingBy: 10.0)

                    for i in 0..<particleCount {
                        let angle = Double(i) / Double(particleCount) * .pi * 2
                        let speed = 80.0 + Double(i % 5) * 20
                        let xBase = size.width * 0.5 + cos(angle) * size.width * 0.3
                        let elapsed = (now * 0.8 + seed * Double(i)).truncatingRemainder(dividingBy: 3.0)
                        let x = xBase + cos(angle + elapsed) * 30
                        let y = -20 + elapsed * speed

                        guard y < size.height + 20 else { continue }

                        let rect = CGRect(
                            x: x, y: y,
                            width: 6 + Double(i % 3) * 2,
                            height: 4 + Double(i % 2) * 3
                        )
                        let color = colors[i % colors.count].opacity(
                            max(0, 1.0 - elapsed / 2.5)
                        )
                        context.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(color))
                    }
                }
            }
            .allowsHitTesting(false)

            // Badge name banner
            VStack {
                Spacer().frame(height: 60)
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("🎉 \(badgeName)")
                        .font(.headline.weight(.bold))
                    Image(systemName: "sparkles")
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.large))
                .shadow(radius: OhShadow.elevated.radius)
                Spacer()
            }
            .transition(.scale.combined(with: .opacity))
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.5)) { show = false }
            }
        }
    }

    // MARK: - Reduced Motion Banner

    private var reducedMotionBanner: some View {
        VStack {
            Spacer().frame(height: 80)
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.text(.badgeUnlockedToast))
                        .font(.headline.weight(.bold))
                    Text(badgeName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.large))
            .shadow(radius: OhShadow.elevated.radius)
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.5)) { show = false }
            }
        }
    }
}
