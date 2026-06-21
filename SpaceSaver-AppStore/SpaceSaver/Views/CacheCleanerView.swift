//
//  CacheCleanerView.swift
//  SpaceSaver (App Store Version)
//
//  Shows cache categories with sizes and lets users clean them.
//  App Store version: Shows sandbox limitation notice.
//

import SwiftUI

struct CacheCleanerView: View {
    @StateObject private var viewModel = CacheCleanerViewModel()
    @State private var detailCategory: CacheCategory?
    @State private var showSandboxNotice = true

    var body: some View {
        VStack(spacing: 0) {
            if showSandboxNotice {
                sandboxNoticeView
            } else {
                // Original content
                originalContent
            }
        }
        .navigationTitle("Cache Cleaner")
        .frame(minWidth: 600, minHeight: 400)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Clean Selected Caches?", isPresented: $viewModel.showCleanConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Move to Trash", role: .destructive) {
                Task { await viewModel.cleanSelected() }
            }
        } message: {
            Text("This will move \(viewModel.formattedSelectedSize) of cache files to the Trash.")
        }
        .sheet(item: $detailCategory) { category in
            CacheCategoryDetailView(category: category)
        }
    }

    // MARK: - Sandbox Notice View
    private var sandboxNoticeView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.shield")
                .font(.system(size: 64))
                .foregroundStyle(.orange)

            VStack(spacing: 12) {
                Text("Feature Limited in App Store Version")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text("Due to App Sandbox restrictions, Cache Cleaner cannot access browser and system cache directories. This feature requires full disk access.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 450)

                Text("Download the non-App Store version for complete cache scanning.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 450)
            }

            HStack(spacing: 12) {
                Button {
                    // Open non-App Store download page
                    if let url = URL(string: "https://github.com/yourusername/spacesaver/releases") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label("Get Full Version", systemImage: "arrow.up.right.square")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    // Try anyway - show the original view
                    showSandboxNotice = false
                } label: {
                    Text("Try Anyway")
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    // MARK: - Original Content
    private var originalContent: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar

            Divider()

            // Category cards
            if viewModel.categories.isEmpty {
                ScanningEmptyState(message: "Scanning caches…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                categoryList
            }
        }
    }

    // MARK: - Toolbar
    private var toolbar: some View {
        HStack(spacing: 12) {
            Button {
                Task { await viewModel.scan() }
            } label: {
                Label(viewModel.isScanning ? "Scanning…" : "Rescan", systemImage: "arrow.clockwise")
            }
            .disabled(viewModel.isScanning)

            Spacer()

            if !viewModel.categories.isEmpty {
                Button("Select All") { viewModel.selectAll() }
                Button("Deselect All") { viewModel.deselectAll() }

                if viewModel.selectedSize > 0 {
                    Button(role: .destructive) {
                        viewModel.showCleanConfirmation = true
                    } label: {
                        Label("Clean \(viewModel.formattedSelectedSize)", systemImage: "trash")
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    // MARK: - Category List
    // Shows each cache category as a card with toggle and size info.
    private var categoryList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.categories.indices, id: \.self) { index in
                    categoryCard(index: index)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Category Card
    // A single cache category card showing name, description, size, and toggle.
    private func categoryCard(index: Int) -> some View {
        let category = viewModel.categories[index]
        return GroupBox {
            HStack(spacing: 16) {
                // Toggle
                Toggle("", isOn: $viewModel.categories[index].isSelected)
                    .toggleStyle(.checkbox)

                // Icon
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 36)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(category.name)
                            .fontWeight(.semibold)

                        if category.isCautioned {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                                .help("Deleting this may temporarily slow down the associated app")
                        }
                    }

                    Text(category.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Text(category.paths.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Spacer()

                // Size
                if category.calculatedSize > 0 {
                    Text(category.formattedSize)
                        .font(.title3)
                        .fontWeight(.bold)
                        .monospacedDigit()
                } else if viewModel.isScanning {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("—")
                        .foregroundStyle(.secondary)
                }

                // More Info — drill down to see exactly what's inside this category
                Button {
                    detailCategory = category
                } label: {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.borderless)
                .help("See what's inside this category")
            }
            .padding(8)
        }
    }
}

#Preview {
    CacheCleanerView()
}
