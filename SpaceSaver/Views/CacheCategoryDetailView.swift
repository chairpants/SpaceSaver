//
//  CacheCategoryDetailView.swift
//  SpaceSaver
//
//  Drill-down sheet for a cache category. Shows exactly what is inside each
//  of the category's paths — the top-level subfolders and files with their
//  measured sizes — so users can see what would be cleaned (and what is
//  actually using the space) before they act.
//

import SwiftUI

struct CacheCategoryDetailView: View {
    let category: CacheCategory

    // Per-path breakdowns. Keyed by the (expanded) path string.
    @State private var breakdowns: [String: [CacheBreakdownItem]] = [:]
    @State private var isScanning = false
    @State private var scannedPaths: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Content
            if isScanning && breakdowns.isEmpty {
                ProgressView("Measuring contents…")
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                contentList
            }
        }
        .frame(width: 640, height: 560)
        .task {
            await loadAllBreakdowns()
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.headline)
                Text("\(category.formattedSize) total • \(category.paths.count) location\(category.paths.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isScanning {
                ProgressView().controlSize(.small)
            }

            Button("Done") { dismiss() }
                .keyboardShortcut(.cancelAction)
        }
        .padding(12)
    }

    // MARK: - Content List
    private var contentList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(category.paths, id: \.self) { path in
                    pathSection(path: path)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Path Section
    // Shows one cache location and its top-level contents.
    @ViewBuilder
    private func pathSection(path: String) -> some View {
        let fullPath = expanded(path)
        let items = breakdowns[fullPath] ?? []

        VStack(alignment: .leading, spacing: 8) {
            // Path header
            HStack(spacing: 6) {
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
                Text(fullPath)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                if items.isEmpty && !scannedPaths.contains(fullPath) {
                    Text("Not found")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else if !items.isEmpty {
                    Text("Top \(items.count) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if items.isEmpty {
                if scannedPaths.contains(fullPath) {
                    Text("Empty or not accessible")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 22)
                }
            } else {
                // Breakdown rows
                ForEach(items) { item in
                    breakdownRow(item)
                }

                // Reveal-in-Finder button for this location
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: fullPath)])
                } label: {
                    Label("Open in Finder", systemImage: "arrow.up.forward.square")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .padding(.leading, 22)
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Breakdown Row
    private func breakdownRow(_ item: CacheBreakdownItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: item.systemImage)
                .foregroundStyle(item.isDirectory ? Color.accentColor : .secondary)
                .frame(width: 18)

            Text(item.name)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(item.url.path)

            if item.isSymlink {
                Text("alias")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text(item.formattedSize)
                .monospacedDigit()
                .foregroundStyle(.secondary)

            // Reveal the specific item in Finder
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            } label: {
                Image(systemName: "folder")
            }
            .buttonStyle(.borderless)
            .help("Reveal in Finder")
        }
        .padding(.leading, 22)
        .padding(.vertical, 1)
    }

    // MARK: - Loading
    private func loadAllBreakdowns() async {
        isScanning = true
        // Measure each path's breakdown concurrently
        await withTaskGroup(of: (String, [CacheBreakdownItem]).self) { group in
            for path in category.paths {
                let expanded = self.expanded(path)
                group.addTask {
                    let items = await CacheLocator.shared.getBreakdown(of: path)
                    return (expanded, items)
                }
            }
            for await (path, items) in group {
                await MainActor.run {
                    breakdowns[path] = items
                    scannedPaths.insert(path)
                }
            }
        }
        isScanning = false
    }

    // MARK: - Helpers
    /// Resolves a category path to its full filesystem path.
    private func expanded(_ path: String) -> String {
        path.hasPrefix("/") ? path : "\(FileManager.default.homeDirectoryForCurrentUser.path)/\(path)"
    }

    /// Dismisses the sheet. Uses the presentation mode environment.
    @Environment(\.dismiss) private var dismiss
}