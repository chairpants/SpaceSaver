//
//  LargeFilesView.swift
//  SpaceSaver
//
//  Lists large files found on disk with sort/filter options.
//  Users can select files and move them to Trash.
//

import SwiftUI

struct LargeFilesView: View {
    @StateObject private var viewModel = LargeFilesViewModel()

    // Sort order for the table. Bound to the Table so clicking a column
    // header updates it; we then sort the results ourselves using it.
    // Default: largest files first (descending size).
    @State private var sortOrder: [KeyPathComparator<ScanResult>] = [
        KeyPathComparator(\.sizeInBytes, order: .reverse)
    ]

    /// The scan results, sorted by the current column sort order.
    private var sortedResults: [ScanResult] {
        viewModel.scanResults.sorted(using: sortOrder)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar

            Divider()

            // Results table
            if viewModel.scanResults.isEmpty {
                emptyState
            } else {
                resultsTable
            }
        }
        .navigationTitle("Large Files")
        .task {
            if viewModel.scanResults.isEmpty {
                await viewModel.scan()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Toolbar
    // Scan controls, size filter, and selection actions.
    private var toolbar: some View {
        HStack(spacing: 12) {
            // Size threshold picker
            Picker("Minimum Size", selection: $viewModel.minimumSize) {
                ForEach(viewModel.sizeOptions, id: \.bytes) { option in
                    Text(option.label).tag(option.bytes)
                }
            }
            .frame(width: 120)

            // Scan button
            Button {
                Task { await viewModel.scan() }
            } label: {
                Label(viewModel.isScanning ? "Scanning…" : "Scan", systemImage: "magnifyingglass")
            }
            .disabled(viewModel.isScanning)

            Spacer()

            // Selection actions
            if !viewModel.scanResults.isEmpty {
                Button("Select All") { viewModel.selectAll() }
                Button("Deselect All") { viewModel.deselectAll() }

                if viewModel.selectedCount > 0 {
                    Button(role: .destructive) {
                        viewModel.showDeleteConfirmation = true
                    } label: {
                        Label("Delete \(viewModel.selectedCount) files (\(viewModel.formattedSelectedSize))",
                              systemImage: "trash")
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    // MARK: - Results Table
    // Shows found files in a sortable table.
    // Clicking a column header updates `sortOrder`; `sortedResults` re-sorts.
    private var resultsTable: some View {
        Table(sortedResults, sortOrder: $sortOrder) {
            // Select column — not sortable (no value keypath)
            TableColumn("Select") { result in
                Toggle("", isOn: Binding(
                    get: { result.isSelected },
                    set: { _ in viewModel.toggleSelection(result) }
                ))
                .toggleStyle(.checkbox)
            }
            .width(40)

            // Sortable columns use TableColumn(_:value:) with a Comparable keypath.
            TableColumn("Name", value: \.fileName) { result in
                Text(result.fileName)
                    .help(result.url.path)  // Tooltip shows full path
            }

            TableColumn("Size", value: \.sizeInBytes) { result in
                Text(result.formattedSize)
                    .monospacedDigit()
            }
            .width(100)

            TableColumn("Last Opened", value: \.sortDate) { result in
                Text(result.formattedLastAccessed)
            }
            .width(120)

            TableColumn("Path") { result in
                Text(result.directoryPath)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(.secondary)
            }

            TableColumn("Actions") { result in
                Button {
                    viewModel.revealInFinder(result)
                } label: {
                    Image(systemName: "folder")
                }
                .buttonStyle(.borderless)
                .help("Reveal in Finder")
            }
            .width(50)
        }
    }

    // MARK: - Empty State
    // Shown when no large files are found or before a scan.
    private var emptyState: some View {
        VStack(spacing: 16) {
            if viewModel.isScanning {
                ProgressView("Scanning for large files…")
                    .controlSize(.large)
            } else {
                Image(systemName: "doc")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("No Large Files Found")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Files larger than \(FileSizeFormatter.string(fromBytes: viewModel.minimumSize)) will appear here after scanning.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

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

