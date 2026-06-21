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
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

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
                VStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    if let action {
                        Button(actionLabel) {
                            action()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 4)
                    }
                }
                .padding(40)
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
        }
        .font(.subheadline)
    }
}

