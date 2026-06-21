//
//  DownloadsCleanerView.swift
//  SpaceSaver
//
//  Lists files in Downloads folder with age/size filters.
//  Helps users find and remove old downloads.
//

import SwiftUI

struct DownloadsCleanerView: View {
    @StateObject private var viewModel = DownloadsViewModel()

    // Sort order for the table — click a column header to sort.
    // Default: oldest first (so "old downloads" surface to the top).
    @State private var sortOrder: [KeyPathComparator<ScanResult>] = [
        KeyPathComparator(\.sortDate, order: .forward)
    ]

    /// Filtered files, sorted by the current column sort order.
    private var displayedFiles: [ScanResult] {
        viewModel.filteredFiles.sorted(using: sortOrder)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter toolbar
            filterBar

            Divider()

            // Results
            if viewModel.filteredFiles.isEmpty && !viewModel.isScanning {
                emptyState
            } else {
                downloadsTable
            }
        }
        .navigationTitle("Downloads Cleaner")
        .task {
            if viewModel.files.isEmpty {
                await viewModel.scan()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Filter Bar
    private var filterBar: some View {
        HStack(spacing: 12) {
            // Filter mode
            Picker("Filter", selection: $viewModel.filterMode) {
                ForEach(DownloadsViewModel.FilterMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .frame(width: 140)

            // Days/size threshold
            if viewModel.filterMode == .olderThan {
                Picker("Older Than", selection: $viewModel.filterDays) {
                    Text("30 days").tag(30)
                    Text("60 days").tag(60)
                    Text("90 days").tag(90)
                    Text("180 days").tag(180)
                    Text("365 days").tag(365)
                }
                .frame(width: 100)
            }

            // Sorting is now done by clicking table column headers.

            Button {
                Task { await viewModel.scan() }
            } label: {
                Label(viewModel.isScanning ? "Scanning…" : "Scan", systemImage: "arrow.clockwise")
            }
            .disabled(viewModel.isScanning)

            Spacer()

            // Selection info
            if viewModel.selectedCount > 0 {
                Text("\(viewModel.selectedCount) selected • \(viewModel.formattedSelectedSize)")
                    .foregroundStyle(.secondary)

                Button(role: .destructive) {
                    viewModel.showDeleteConfirmation = true
                } label: {
                    Label("Delete Selected", systemImage: "trash")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    // MARK: - Downloads Table
    private var downloadsTable: some View {
        Table(displayedFiles, sortOrder: $sortOrder) {
            TableColumn("Select") { file in
                Toggle("", isOn: Binding(
                    get: { file.isSelected },
                    set: { _ in viewModel.toggleSelection(file) }
                ))
                .toggleStyle(.checkbox)
            }
            .width(40)

            TableColumn("Name", value: \.fileName) { file in
                Text(file.fileName)
            }

            TableColumn("Size", value: \.sizeInBytes) { file in
                Text(file.formattedSize)
                    .monospacedDigit()
            }
            .width(100)

            TableColumn("Last Opened", value: \.sortDate) { file in
                Text(file.formattedLastAccessed)
            }
            .width(120)

            TableColumn("Path") { file in
                Text(file.directoryPath)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            TableColumn("Actions") { file in
                Button {
                    viewModel.revealInFinder(file)
                } label: {
                    Image(systemName: "folder")
                }
                .buttonStyle(.borderless)
            }
            .width(50)
        }
        .overlay(alignment: .bottom) {
            if !displayedFiles.isEmpty {
                HStack {
                    Text("\(displayedFiles.count) files • \(viewModel.formattedFilteredTotalSize) total")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Select All") { viewModel.selectAll() }
                    Button("Deselect All") { viewModel.deselectAll() }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.bar)
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            if viewModel.isScanning {
                ProgressView("Scanning Downloads…")
                    .controlSize(.large)
            } else {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("No Matching Downloads")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Try adjusting the filter to see more files.")
                    .foregroundStyle(.secondary)

                Button("Scan Again") {
                    Task { await viewModel.scan() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

