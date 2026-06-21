//
//  ProgressView+.swift
//  SpaceSaver
//
//  Custom styling and convenience extensions for ProgressView.
//  Provides a consistent look across all scanning/cleaning views.
//

import SwiftUI

// MARK: - Progress View Modifiers
extension View {

    /// Shows a scanning overlay with progress when `isScanning` is true.
    /// - Parameters:
    ///   - isScanning: Whether a scan is in progress
    ///   - message: Text to show below the progress indicator
    ///   - progress: Optional progress value (0 to 1). Nil = indeterminate.
    func scanningOverlay(
        isScanning: Bool,
        message: String = "Scanning…",
        progress: Double? = nil
    ) -> some View {
        overlay {
            if isScanning {
                ZStack {
                    // Semi-transparent background to dim the content
                    // Note: Removed ignoresSafeArea to prevent layout issues with sidebar
                    Color.black.opacity(0.3)

                    VStack(spacing: 12) {
                        if let progress {
                            ProgressView(value: progress)
                                .progressViewStyle(.linear)
                                .frame(width: 200)
                        } else {
                            ProgressView()
                                .controlSize(.large)
                        }

                        Text(message)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    /// Premium glassmorphism scanning overlay with smooth animations.
    /// - Parameters:
    ///   - isScanning: Whether a scan is in progress
    ///   - message: Text to show below the progress indicator
    ///   - progress: Optional progress value (0 to 1). Nil = indeterminate.
    func premiumScanningOverlay(
        isScanning: Bool,
        message: String = "Scanning…",
        progress: Double? = nil
    ) -> some View {
        overlay {
            if isScanning {
                ZStack {
                    // Semi-transparent background with animation
                    // Note: Removed ignoresSafeArea to prevent layout issues with sidebar
                    Color.black.opacity(0.15)

                    // Glass card
                    VStack(spacing: 20) {
                        if let progress {
                            VStack(spacing: 12) {
                                ProgressView(value: progress)
                                    .progressViewStyle(.linear)
                                    .tint(.accentColor)
                                    .frame(width: 240)

                                HStack {
                                    Text(message)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Text("\(Int(progress * 100))%")
                                        .font(.callout.monospacedDigit())
                                }
                                .frame(width: 240)
                            }
                        } else {
                            ProgressView()
                                .controlSize(.large)
                                .tint(.accentColor)

                            Text(message)
                                .font(.subheadline.weight(.medium))
                        }
                    }
                    .padding(32)
                    .background(
                        ZStack {
                            // Multiple material layers for depth
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.ultraThinMaterial)
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.accentColor.opacity(0.05))
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                        }
                    )
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }

    /// Shows an empty state when there are no results.
    /// - Parameters:
    ///   - isEmpty: Whether to show the empty state
    ///   - icon: SF Symbol name for the illustration
    ///   - title: Main message
    ///   - description: Secondary explanation text
    ///   - action: Optional button to take action (e.g., "Scan Now")
    ///   - actionLabel: Label for the action button
    func emptyState(
        isEmpty: Bool,
        icon: String,
        title: String,
        description: String,
        action: (() -> Void)? = nil,
        actionLabel: String = "Scan Now"
    ) -> some View {
        overlay {
            if isEmpty {
                EmptyStateView(
                    icon: icon,
                    title: title,
                    description: description,
                    action: action,
                    actionLabel: actionLabel
                )
            }
        }
    }
}

// MARK: - Status Row View
// A compact row showing a label, value, and optional icon.
// Used in the dashboard and detail views for key metrics.
struct StatusRow: View {
    let icon: String
    let label: String
    let value: String
    var iconColor: Color = .accentColor

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 20)

            Text(label)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
                .monospacedDigit()
        }
        .font(.subheadline)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        StatusRow(
            icon: "internaldrive.fill",
            label: "Total Capacity",
            value: "1 TB",
            iconColor: .blue
        )
        .padding()
        .frame(width: 300)
    }
}
