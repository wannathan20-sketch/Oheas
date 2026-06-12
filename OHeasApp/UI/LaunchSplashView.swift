//
//  LaunchSplashView.swift
//  OHeas
//
//  Branded splash / loading view shown during app initialization.
//  Gradient background + OHeasLogo ring + tagline + "Waking up…" hint.
//  品牌启动过渡页：渐变背景 + OHeas 环形 Logo + 副标题 + 温暖加载提示。
//

import SwiftUI

struct LaunchSplashView: View {
    let language: AppLanguage
    let reduceMotion: Bool

    @State private var logoVisible = false
    @State private var taglineVisible = false

    var body: some View {
        ZStack {
            // Gradient background — mint → teal, matching the Today hero aesthetic
            LinearGradient(
                colors: [Color.mint.opacity(0.35), Color.teal.opacity(0.18), OhColor.groupedBg],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // Brand logo: gradient ring + centred "O"
                OHeasLogo(size: 100, showBackground: true)
                    .opacity(logoVisible ? 1 : 0)
                    .scaleEffect(logoVisible ? 1 : 0.7)

                // App name
                Text("OHeas")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.teal, Color.indigo],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(taglineVisible ? 1 : 0)
                    .offset(y: taglineVisible ? 0 : 8)

                // Warm loading hint — "Waking up…"
                Text(language.text(.splashWakingUp))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .opacity(taglineVisible ? 1 : 0)
                    .padding(.top, 8)

                Spacer()
                Spacer()
            }
        }
        .onAppear { animateIn() }
    }

    // MARK: - Animation

    private func animateIn() {
        if reduceMotion {
            logoVisible = true
            taglineVisible = true
            return
        }
        // Logo springs in first, then text fades up
        withAnimation(OhAnimation.gauge()) {
            logoVisible = true
        }
        withAnimation(OhAnimation.appear().delay(0.3)) {
            taglineVisible = true
        }
    }
}
