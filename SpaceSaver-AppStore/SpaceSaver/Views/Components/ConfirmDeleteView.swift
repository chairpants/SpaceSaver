//
//  ConfirmDeleteView.swift
//  SpaceSaver
//
//  A reusable confirmation sheet that appears before deleting files.
//  Shows what will be deleted and how much space will be freed.
//

import SwiftUI

// MARK: - ConfirmDeleteView
// A modal dialog that asks "Are you sure?" before deleting files.
// Used by every feature that removes files — we always confirm
// because deleting is irreversible (even from Trash after 30 days).
struct ConfirmDeleteView: View {
    let items: [ScanResult]
    let totalSize: Int64
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Warning icon
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)

            Text("Confirm Deletion")
                .font(.title2)
                .fontWeight(.bold)

            Text("You are about to move \(itemCount) to the Trash.")
                .multilineTextAlignment(.center)

            if items.count <= 5 {
                // Show individual file names when there are few items
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(items) { item in
                        Text("• \(item.fileName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
            } else {
                // Summarize when there are many items
                Text("This includes \(items.count) items totaling \(FileSizeFormatter.string(fromBytes: totalSize)).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("This will free up \(FileSizeFormatter.string(fromBytes: totalSize)) of disk space.")
                .font(.subheadline)
                .fontWeight(.medium)

            HStack(spacing: 12) {
                Button("Cancel", role: .cancel) {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Move to Trash", role: .destructive) {
                    onConfirm()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(width: 400)
    }

    // MARK: - Helpers

    private var itemCount: String {
        if items.count == 1 {
            return "1 item"
        } else {
            return "\(items.count) items"
        }
    }
}

