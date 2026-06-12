//
//  DesignTokens.swift
//  OHeas
//
//  DesignTokens.swift — centralized design constants.
//  Phase 3: full semantic color / spacing / typography / animation / shadow system.
//

import SwiftUI

// MARK: - Semantic Color Tokens

enum OhColor {
    // MARK: Status colors
    static let success = Color.green
    static let warning = Color.orange
    static let danger = Color.red
    static let info = Color.blue
    static let recovery = Color.mint
    static let neutral = Color.secondary

    // MARK: Brand / accent
    static let primary = Color.indigo
    static let primaryLight = Color.indigo.opacity(0.12)
    static let accent = Color.teal

    // MARK: Metric colors
    static let sleep = Color.blue
    static let hrv = Color.green
    static let restingHR = Color.orange
    static let steps = Color.pink
    static let activeEnergy = Color.red
    static let exercise = Color.mint
    static let workouts = Color.purple

    // MARK: Surface colors
    static let cardBg = Color(.systemBackground)
    static let groupedBg = Color(.systemGroupedBackground)
    static let secondaryGroupedBg = Color(.secondarySystemGroupedBackground)

    // MARK: Text colors
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color(.tertiaryLabel)

    // MARK: Semantic backgrounds
    static let successBg = Color.green.opacity(0.10)
    static let warningBg = Color.orange.opacity(0.10)
    static let dangerBg = Color.red.opacity(0.10)
    static let infoBg = Color.blue.opacity(0.10)
    static let primaryBg = Color.indigo.opacity(0.08)

    // MARK: Chat bubble
    static let userBubbleBg = Color.indigo
    static let coachBubbleBg = Color(.systemGray6)

    // MARK: Gauge
    static let gaugeTrack = Color.secondary.opacity(0.15)
    static let gaugeHigh = Color.green
    static let gaugeMedium = Color.orange
    static let gaugeLow = Color.red
}

// MARK: - Typography Tokens

enum OhFont {
    static let caption2: Font = .caption2
    static let caption: Font = .caption
    static let footnote: Font = .footnote
    static let subheadline: Font = .subheadline
    static let body: Font = .body
    static let headline: Font = .headline
    static let title3: Font = .title3
    static let title2: Font = .title2
    static let title: Font = .title

    // MARK: Weighted variants
    static func caption(_ weight: Font.Weight = .regular) -> Font { .caption.weight(weight) }
    static func footnote(_ weight: Font.Weight = .regular) -> Font { .footnote.weight(weight) }
    static func subheadline(_ weight: Font.Weight = .regular) -> Font { .subheadline.weight(weight) }
    static func body(_ weight: Font.Weight = .regular) -> Font { .body.weight(weight) }
    static func headline(_ weight: Font.Weight = .regular) -> Font { .headline.weight(weight) }
}

// MARK: - Animation Tokens

enum OhAnimation {
    /// Quick press feedback: scale down and spring back
    static let pressResponse: Double = 0.28
    static let pressDamping: Double = 0.78

    /// Smooth appear / disappear
    static let appearResponse: Double = 0.46
    static let appearDamping: Double = 0.86

    /// Tab / page transitions
    static let tabResponse: Double = 0.32
    static let tabDamping: Double = 0.78

    /// List item stagger
    static let staggerResponse: Double = 0.38
    static let staggerDamping: Double = 0.84

    /// Gauge / progress animations
    static let gaugeResponse: Double = 0.80
    static let gaugeDamping: Double = 0.86

    /// Spring function helpers
    static func press() -> Animation { .spring(response: pressResponse, dampingFraction: pressDamping) }
    static func appear() -> Animation { .spring(response: appearResponse, dampingFraction: appearDamping) }
    static func tab() -> Animation { .spring(response: tabResponse, dampingFraction: tabDamping) }
    static func stagger() -> Animation { .spring(response: staggerResponse, dampingFraction: staggerDamping) }
    static func gauge() -> Animation { .spring(response: gaugeResponse, dampingFraction: gaugeDamping) }

    /// Non-spring presets
    static let shimmer = Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
    static let pulse = Animation.easeInOut(duration: 2.0)
    static let glow = Animation.easeInOut(duration: 3.2).repeatForever(autoreverses: true)
    static let dotPulse = Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)
}

// MARK: - Shadow Elevation Tokens

enum OhShadow {
    /// Subtle card shadow (default)
    static let card: (radius: CGFloat, y: CGFloat, opacity: CGFloat) = (6, 2, 0.04)
    /// Slightly elevated (hovered cards, modals)
    static let elevated: (radius: CGFloat, y: CGFloat, opacity: CGFloat) = (8, 3, 0.06)
    /// Input field, bottom sheets
    static let input: (radius: CGFloat, y: CGFloat, opacity: CGFloat) = (4, -2, 0.06)
    /// Colored accent glow (indigo)
    static let accentGlow: (radius: CGFloat, y: CGFloat, opacity: CGFloat) = (6, 2, 0.06)

}

extension View {
    /// Apply a shadow elevation preset from OhShadow.
    func ohShadow(_ elevation: (radius: CGFloat, y: CGFloat, opacity: CGFloat),
                  color: Color = .black) -> some View {
        self.shadow(
            color: color.opacity(elevation.opacity),
            radius: elevation.radius,
            y: elevation.y
        )
    }
}

// MARK: - Card Style

enum CardStyle {
    static let cornerRadius: CGFloat = Radius.medium
    static let padding: CGFloat = 16
    static let shadowRadius: CGFloat = 6
    static let shadowY: CGFloat = 2
    static let gap: CGFloat = 16
    static let innerSpacing: CGFloat = 12
}

// MARK: - Radius Tokens

enum Radius {
    static let tiny: CGFloat = 2
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let bubble: CGFloat = 18
}

// MARK: - Spacing Tokens

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}

// MARK: - Card Background Modifier

struct CardBackground: ViewModifier {
    var shadow: Bool = true

    func body(content: Content) -> some View {
        content
            .padding(CardStyle.padding)
            .background(OhColor.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: CardStyle.cornerRadius))
            .compositingGroup()
            .shadow(
                color: shadow ? .black.opacity(OhShadow.card.opacity) : .clear,
                radius: shadow ? OhShadow.card.radius : 0,
                y: shadow ? OhShadow.card.y : 0
            )
    }
}

// MARK: - View Extension

extension View {
    /// Apply the standard card background: padding, system background color,
    /// rounded corners, and optional subtle shadow.
    func cardBackground(shadow: Bool = true) -> some View {
        modifier(CardBackground(shadow: shadow))
    }
}
