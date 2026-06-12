//
//  CardView.swift
//  OHeas
//
//  CardView.swift — reusable card wrapper components.
//

import SwiftUI

/// A standard content card with consistent padding, background, corner radius,
/// and optional shadow. Use this as a drop-in wrapper around card content.
struct OCard<Content: View>: View {
    let shadow: Bool
    @ViewBuilder let content: () -> Content

    init(shadow: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.shadow = shadow
        self.content = content
    }

    var body: some View {
        content()
            .padding(CardStyle.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(OhColor.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: CardStyle.cornerRadius))
            .shadow(
                color: shadow ? .black.opacity(OhShadow.card.opacity) : .clear,
                radius: shadow ? OhShadow.card.radius : 0,
                y: shadow ? OhShadow.card.y : 0
            )
    }
}

/// A labeled card with a title and SF Symbol icon header.
struct OLabeledCard<Content: View>: View {
    let title: String
    let systemImage: String
    let shadow: Bool
    @ViewBuilder let content: () -> Content

    init(
        _ title: String,
        systemImage: String,
        shadow: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.shadow = shadow
        self.content = content
    }

    var body: some View {
        OCard(shadow: shadow) {
            VStack(alignment: .leading, spacing: CardStyle.innerSpacing) {
                Label(title, systemImage: systemImage)
                    .font(.headline)
                content()
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: CardStyle.gap) {
            OCard {
                Text("A simple card with default shadow.")
                    .font(.subheadline)
            }

            OLabeledCard("Health Metrics", systemImage: "heart.fill") {
                Text("Content inside a labeled card.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            OCard(shadow: false) {
                Text("Card without shadow")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
