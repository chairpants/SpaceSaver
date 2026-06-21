//
//  LargeFilesView.swift
//  SpaceSaver (App Store Version)
//
//  Lists large files found on disk with sort/filter options.
//  App Store version: Shows sandbox limitation notice.
//

import SwiftUI

struct LargeFilesView: View {
    @StateObject private var viewModel = LargeFilesViewModel()

    // Sort order for the table
    @State private var sortOrder: [KeyPathComparator<ScanResult>] = [
        KeyPathComparator(\.sizeInBytes, order: .reverse)
    ]

    private var sortedResults: [ScanResult] {
        viewModel.scanResults.sorted(using: sortOrder)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar

            Divider()

            // Content
            if viewModel.scanResults.isEmpty {
                sandboxNoticeView
            } else {
                resultsTable
            }
        }
        .navigationTitle("Large Files")
        .frame(minWidth: 600, minHeight: 400)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Delete Selected Files?", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Move to Trash", role: .destructive) {
                Task { await viewModel.deleteSelected() }
            }
        } message: {
            Text("This will move \(viewModel.selectedCount) files (\(viewModel.formattedSelectedSize)) to the Trash.")
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

                Text("Due to App Sandbox restrictions, Large Files scanner cannot access your home directory. Only Downloads and specific user-selected folders can be scanned.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 450)

                Text("Use the Downloads section for full functionality, or download the non-App Store version for complete disk scanning.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 450)
            }

            HStack(spacing: 16) {
                Button {
                    // Switch to Downloads
                    NotificationCenter.default.post(name: Notification.Name("selectDownloads"), object: nil)
                } label: {
                    Label("Go to Downloads", systemImage: "arrow.down.circle")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    // Open non-App Store download page (GitHub)
                    if let url = URL(string: "https://github.com/yourusername/spacesaver/releases") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label("Get Full Version", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    // MARK: - Toolbar
    private var toolbar: some View {
        HStack(spacing: 12) {
            Picker("Minimum Size", selection: $viewModel.minimumSize) {
                ForEach(viewModel.sizeOptions, id: \.bytes) { option in
                    Text(option.label).tag(option.bytes)
                }
            }
            .pickerStyle(.menu)
            .fixedSize()
            .disabled(true) // Disabled in sandbox

            Button {
                // No-op - scanning doesn't work in sandbox
            } label: {
                Label("Scan Unavailable", systemImage: "magnifyingglass")
            }
            .disabled(true)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    // MARK: - Results Table
    private var resultsTable: some View {
        Table(sortedResults, sortOrder: $sortOrder) {
            TableColumn("Select") { result in
                Toggle("", isOn: Binding(
                    get: { result.isSelected },
                    set: { _ in viewModel.toggleSelection(result) }
                ))
                .toggleStyle(.checkbox)
            }
            .width(40)

            TableColumn("Name", value: \.fileName) { result in
                Text(result.fileName)
                    .help(result.url.path)
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
}

// MARK: - Notification Extension
extension Notification.Name {
    static let selectDownloads = Notification.Name("selectDownloads")
}

#Preview {
    LargeFilesView()
}
