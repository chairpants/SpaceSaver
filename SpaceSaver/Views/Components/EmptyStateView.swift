//
//  EmptyStateView.swift
//  SpaceSaver
//
//  A beautiful empty state with SF Symbols, gradients, and entrance animations.
//

import SwiftUI

/// A beautiful empty state with animated entrance
struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    var action: (() -> Void)?
    var actionLabel: String?

    // Animation states
    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20

    var body: some View {
        VStack(spacing: Spacing.large) {
            // Icon with gradient background
            ZStack {
                // Gradient background circle
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.accentColor.opacity(0.3),
                                Color.accentColor.opacity(0.1),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                // SF Symbol with hierarchical rendering
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .light))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.accentColor)
            }
            .scaleEffect(iconScale)
            .opacity(iconOpacity)

            // Text content
            VStack(spacing: Spacing.small) {
                Text(title)
                    .font(.title3.weight(.semibold))

                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .offset(y: contentOffset)
            .opacity(iconOpacity)

            // Action button
            if let action = action, let label = actionLabel {
                Button {
                    action()
                } label: {
                    Label(label, systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .offset(y: contentOffset)
                .opacity(iconOpacity)
            }
        }
        .frame(maxWidth: 400)
        .padding(Spacing.xlarge)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                iconScale = 1
                iconOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                contentOffset = 0
            }
        }
    }
}

/// Empty state for scanning/waiting
struct ScanningEmptyState: View {
    let message: String

    var body: some View {
        VStack(spacing: Spacing.large) {
            // Animated scanning rings
            ScanningRings()
                .frame(width: 80, height: 80)

            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Animated scanning rings
struct ScanningRings: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            ForEach(0..<3) { i in
                Circle()
                    .stroke(
                        Color.accentColor.opacity(0.3 - Double(i) * 0.08),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [8, 4])
                    )
                    .frame(width: 60 - CGFloat(i) * 15, height: 60 - CGFloat(i) * 15)
                    .rotationEffect(.degrees(rotation + Double(i) * 30))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        EmptyStateView(
            icon: "doc.text.magnifyingglass",
            title: "No Large Files Found",
            description: "Files larger than 100 MB will appear here after scanning.",
            action: {},
            actionLabel: "Scan Again"
        )

        ScanningEmptyState(message: "Scanning for large files…")
    }
    .padding()
}
