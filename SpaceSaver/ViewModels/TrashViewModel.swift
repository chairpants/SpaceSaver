//
//  TrashViewModel.swift
//  SpaceSaver
//
//  ViewModel for the Trash Manager feature.
//  Shows trash size and lets users empty it.
//

import SwiftUI

@MainActor
final class TrashViewModel: ObservableObject {

    // MARK: - Published State
    @Published var trashSize: Int64 = 0
    @Published var trashItemCount: Int = 0
    @Published var isLoading = false
    @Published var isEmptying = false
    @Published var errorMessage: String?
    @Published var showConfirmation = false

    // MARK: - Computed Properties

    /// Whether the Trash appears to be empty
    var isTrashEmpty: Bool {
        trashSize == 0 && trashItemCount == 0
    }

    /// Human-readable trash size
    var formattedTrashSize: String {
        FileSizeFormatter.string(fromBytes: trashSize)
    }

    // MARK: - Refresh Trash Info
    /// Queries the size and contents of the Trash folder.
    func refresh() async {
        isLoading = true

        // The macOS Trash is at ~/.Trash
        let trashURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".Trash")

        let path = trashURL.path

        // Check if Trash exists and list its contents
        let fileManager = FileManager.default

        guard let contents = try? fileManager.contentsOfDirectory(
            at: trashURL,
            includingPropertiesForKeys: [.fileSizeKey, .totalFileSizeKey, .isDirectoryKey]
        ) else {
            trashSize = 0
            trashItemCount = 0
            isLoading = false
            return
        }

        var totalSize: Int64 = 0
        var count = 0

        for url in contents {
            do {
                let values = try url.resourceValues(
                    forKeys: [.totalFileSizeKey, .fileSizeKey, .isDirectoryKey]
                )
                if values.isDirectory != true {
                    totalSize += Int64(values.totalFileSize ?? values.fileSize ?? 0)
                    count += 1
                }
            } catch {
                continue
            }
        }

        // Also measure directories in Trash recursively
        totalSize += await DiskUsage.shared.measureDirectorySize(at: path)

        trashSize = totalSize
        trashItemCount = count
        isLoading = false
    }

    // MARK: - Empty Trash
    /// Empties the macOS Trash by deleting contents of ~/.Trash.
    func emptyTrash() async {
        isEmptying = true
        errorMessage = nil

        let trashURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".Trash")

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: trashURL,
                includingPropertiesForKeys: nil
            )
            for item in contents {
                try? FileManager.default.removeItem(at: item)
            }
        } catch {
            errorMessage = "Could not empty Trash: \(error.localizedDescription)"
        }

        isEmptying = false

        // Refresh to show updated size
        await refresh()
    }

    // MARK: - Open Trash in Finder
    /// Opens the Trash folder in Finder
    func openInFinder() {
        // Open ~/.Trash in Finder
        NSWorkspace.shared.open(
            URL(fileURLWithPath: FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".Trash").path)
        )
    }
}