//
//  ButtonEffects.swift
//  OHeas
//
//  ButtonEffects.swift — press animations and interactive modifiers.
//

import SwiftUI

// MARK: - Pressable Scale Modifier

/// Adds a subtle scale-down animation on press using a simultaneous drag gesture
/// that does not interfere with the parent button's tap action.
struct PressableScaleModifier: ViewModifier {
    @State private var pressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed && !reduceMotion ? 0.97 : 1)
            .opacity(pressed ? 0.85 : 1)
            .animation(OhAnimation.press(), value: pressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !reduceMotion else { return }
                        pressed = true
                    }
                    .onEnded { _ in
                        pressed = false
                    }
            )
    }
}

// MARK: - Scale Button Style

/// A ButtonStyle that scales down on press. For plain buttons.
struct ScaleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(OhAnimation.press(), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply a subtle press-down scale effect. Safe to use on buttons
    /// that already have a `.buttonStyle()` — it uses a simultaneous
    /// gesture so tap actions are not blocked.
    func pressableScale() -> some View {
        modifier(PressableScaleModifier())
    }
}

extension ButtonStyle where Self == ScaleButtonStyle {
    /// A button style that scales down on press with spring animation.
    static var scalePress: ScaleButtonStyle { ScaleButtonStyle() }
}
