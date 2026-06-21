//
//  TrashManagerView.swift
//  SpaceSaver (App Store Version)
//
//  View for managing Trash contents.
//  App Store version: Shows sandbox limitation notice.
//

import SwiftUI

struct TrashManagerView: View {
    @StateObject private var viewModel = TrashViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar

            Divider()

            // Content
            if viewModel.showSandboxNotice || viewModel.isTrashEmpty {
                sandboxNoticeView
            } else {
                trashInfoView
            }
        }
        .navigationTitle("Trash Manager")
        .frame(minWidth: 600, minHeight: 400)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Empty Trash?", isPresented: $viewModel.showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Empty Trash", role: .destructive) {
                Task { await viewModel.emptyTrash() }
            }
        } message: {
            Text("This will permanently delete all items in the Trash. This action cannot be undone.")
        }
        .task {
            await viewModel.refresh()
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

                Text("Due to App Sandbox restrictions, Trash Manager cannot access the system Trash folder (~/.Trash). This feature requires full disk access.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 450)

                Text("Download the non-App Store version for complete Trash management.")
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
                    viewModel.openInFinder()
                } label: {
                    Label("Open Trash in Finder", systemImage: "folder")
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    // MARK: - Trash Info View
    private var trashInfoView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "trash")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("Trash Contents")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("\(viewModel.trashItemCount) items • \(viewModel.formattedTrashSize) total")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                viewModel.showConfirmation = true
            } label: {
                Label("Empty Trash", systemImage: "trash")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    // MARK: - Toolbar
    private var toolbar: some View {
        HStack(spacing: 12) {
            Button {
                Task { await viewModel.refresh() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .disabled(viewModel.isLoading || viewModel.isEmptying)

            Spacer()

            if !viewModel.isTrashEmpty {
                Button(role: .destructive) {
                    viewModel.showConfirmation = true
                } label: {
                    Label("Empty Trash", systemImage: "trash")
                }
                .disabled(viewModel.isEmptying)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

#Preview {
    TrashManagerView()
}
