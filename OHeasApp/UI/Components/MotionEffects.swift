//
//  MotionEffects.swift
//  OHeas
//

import SwiftUI

struct SoftAppearModifier: ViewModifier {
    let isVisible: Bool
    let delay: Double
    let yOffset: CGFloat
    let reduceMotion: Bool
    @State private var hasEntered = false

    func body(content: Content) -> some View {
        let visible = isVisible && hasEntered

        content
            .opacity(visible ? 1 : 0)
            .offset(y: reduceMotion ? 0 : (visible ? 0 : yOffset))
            .scaleEffect(reduceMotion ? 1 : (visible ? 1 : 0.985), anchor: .top)
            .animation(
                reduceMotion ? nil : OhAnimation.appear().delay(delay),
                value: visible
            )
            .onAppear { hasEntered = true }
            .onDisappear { hasEntered = false }
    }
}

extension View {
    func softAppear(_ isVisible: Bool, delay: Double = 0, yOffset: CGFloat = 12, reduceMotion: Bool = false) -> some View {
        modifier(SoftAppearModifier(isVisible: isVisible, delay: delay, yOffset: yOffset, reduceMotion: reduceMotion))
    }
}
