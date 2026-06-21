//
//  DuplicateFinderView.swift
//  SpaceSaver
//
//  Finds and manages duplicate files.
//  Groups duplicates by content hash and lets users pick which to keep.
//

import SwiftUI

struct DuplicateFinderView: View {
    @StateObject private var viewModel = DuplicateViewModel()

    var body: some View {
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
        .navigationTitle("Duplicate Finder")
        .task {
            if viewModel.duplicateGroups.isEmpty {
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
    private var emptyState: some View {
        VStack(spacing: 16) {
            if viewModel.isScanning {
                VStack(spacing: 12) {
                    ProgressView(value: viewModel.scanProgress) {
                        Text("Scanning for duplicates…")
                    }
                    .frame(width: 300)

                    Text("\(Int(viewModel.scanProgress * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            } else {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("No Duplicates Found")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Duplicate files (identical content) will appear here.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Scan for Duplicates") {
                    Task { await viewModel.scan() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

