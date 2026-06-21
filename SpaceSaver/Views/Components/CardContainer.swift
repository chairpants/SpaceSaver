//
//  CardContainer.swift
//  SpaceSaver
//
//  A premium card container with modern glassmorphism styling.
//

import SwiftUI

/// A premium card container that replaces GroupBox with better styling
struct CardContainer<Content: View, Label: View>: View {
    var isElevated: Bool = false
    @ViewBuilder let content: Content
    @ViewBuilder let label: Label

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            // Label area with proper spacing
            label
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            // Content with consistent padding
            content
                .padding(Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xlarge, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                // Subtle shadow for depth
                .shadow(
                    color: .black.opacity(isElevated ? 0.08 : 0.03),
                    radius: isElevated ? 8 : 2,
                    x: 0,
                    y: isElevated ? 4 : 1
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xlarge, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }
}

/// Convenience for cards without labels
struct ContentCard<Content: View>: View {
    @ViewBuilder let content: Content
    var isElevated: Bool = false

    var body: some View {
        content
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(
                        color: .black.opacity(isElevated ? 0.08 : 0.03),
                        radius: isElevated ? 8 : 2,
                        x: 0,
                        y: isElevated ? 4 : 1
                    )
            )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: Spacing.large) {
        CardContainer(isElevated: true) {
            Text("This is the card content")
                .font(.body)
        } label: {
            Label("Elevated Card", systemImage: "star.fill")
        }

        CardContainer {
            Text("Regular card content")
                .font(.body)
        } label: {
            Label("Regular Card", systemImage: "doc")
        }

        ContentCard(isElevated: true) {
            Text("Content only card with elevation")
        }
    }
    .padding()
    .frame(width: 400)
}
