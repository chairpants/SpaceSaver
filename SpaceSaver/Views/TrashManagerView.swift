//
//  TrashManagerView.swift
//  SpaceSaver
//
//  Shows trash size and lets users empty the Trash.
//

import SwiftUI

struct TrashManagerView: View {
    @StateObject private var viewModel = TrashViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Trash icon
            Image(systemName: viewModel.isTrashEmpty ? "trash" : "trash.fill")
                .font(.system(size: 72))
                .foregroundStyle(viewModel.isTrashEmpty ? AnyShapeStyle(.secondary) : AnyShapeStyle(.red))

            if viewModel.isTrashEmpty {
                Text("Trash is Empty")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("No files in the Trash to clean up.")
                    .foregroundStyle(.secondary)
            } else {
                Text("Trash Contains \(viewModel.trashItemCount) items")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Using \(viewModel.formattedTrashSize) of disk space")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                // Empty Trash button
                Button(role: .destructive) {
                    viewModel.showConfirmation = true
                } label: {
                    Label("Empty Trash", systemImage: "trash")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isEmptying)
                .padding(.top, 8)
            }

            // Open in Finder
            Button {
                viewModel.openInFinder()
            } label: {
                Label("Open Trash in Finder", systemImage: "folder")
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .navigationTitle("Trash Manager")
        .task {
            await viewModel.refresh()
        }
        .alert("Empty Trash?", isPresented: $viewModel.showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Empty Trash", role: .destructive) {
                Task { await viewModel.emptyTrash() }
            }
        } message: {
            Text("This will permanently delete \(viewModel.trashItemCount) items totaling \(viewModel.formattedTrashSize). This cannot be undone.")
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            Task { await viewModel.refresh() }
        }
        .overlay {
            if viewModel.isEmptying {
                ProgressView("Emptying Trash…")
                    .padding(24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

