//
//  DuplicateFinderView.swift
//  SpaceSaver (App Store Version)
//
//  Finds and manages duplicate files.
//  App Store version: Shows sandbox limitation notice.
//

import SwiftUI

struct DuplicateFinderView: View {
    @StateObject private var viewModel = DuplicateViewModel()
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
        .navigationTitle("Duplicate Finder")
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
            Text("This will move the selected files to the Trash.")
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

                Text("Due to App Sandbox restrictions, Duplicate Finder cannot access your home directory to scan for duplicates. This feature requires full disk access.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 450)

                Text("Download the non-App Store version for complete duplicate scanning.")
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
                    Task { await viewModel.scan() }
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

            // Results
            if viewModel.duplicateGroups.isEmpty {
                emptyState
            } else {
                duplicateList
            }
        }
    }

    // MARK: - Toolbar
    private var toolbar: some View {
        HStack(spacing: 12) {
            Button {
                Task { await viewModel.scan() }
            } label: {
                Label(viewModel.isScanning ? "Scanning…" : "Scan", systemImage: "magnifyingglass")
            }
            .disabled(viewModel.isScanning)

            Spacer()

            if !viewModel.duplicateGroups.isEmpty {
                Text("\(viewModel.groupCount) groups • \(viewModel.formattedWastedSpace) wasted")
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

    // MARK: - Duplicate List
    // Shows groups of duplicate files. Each group has files with identical content.
    private var duplicateList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(viewModel.duplicateGroups) { group in
                    duplicateGroupCard(group)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Group Card
    // A single duplicate group showing all copies of a file.
    private func duplicateGroupCard(_ group: DuplicateGroup) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                // Group header
                HStack {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(.orange)

                    Text("\(group.files.count) copies")
                        .fontWeight(.semibold)

                    Text("• \(group.formattedFileSize) each")
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(group.formattedWastedSpace) wasted")
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                }

                Divider()

                // File list
                ForEach(group.files) { file in
                    HStack {
                        Toggle("", isOn: Binding(
                            get: { file.isSelected },
                            set: { _ in viewModel.toggleFileSelection(groupId: group.id, fileId: file.id) }
                        ))
                        .toggleStyle(.checkbox)
                        .help("Check files to DELETE them")

                        Text(file.fileName)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Spacer()

                        Text(file.url.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
            .padding(8)
        }
    }

    // MARK: - Empty State
    @ViewBuilder
    private var emptyState: some View {
        if viewModel.isScanning {
            ScanningEmptyState(message: "Scanning for duplicates…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            EmptyStateView(
                icon: "doc.on.doc",
                title: "No Duplicates Found",
                description: "Duplicate files (identical content) will appear here after scanning.",
                action: {
                    Task { await viewModel.scan() }
                },
                actionLabel: "Scan for Duplicates"
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    DuplicateFinderView()
}
