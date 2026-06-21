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
        errorMessage = nil

        // The macOS Trash is at ~/.Trash
        let trashURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".Trash")

        let fileManager = FileManager.default

        // Check if we can access the Trash
        guard fileManager.fileExists(atPath: trashURL.path) else {
            // Trash doesn't exist (shouldn't happen, but handle it)
            trashSize = 0
            trashItemCount = 0
            isLoading = false
            return
        }

        do {
            // Try to list contents
            let contents = try fileManager.contentsOfDirectory(
                at: trashURL,
                includingPropertiesForKeys: nil
            )

            // Count all top-level items
            trashItemCount = contents.count

            // Calculate size by measuring each item
            var totalSize: Int64 = 0
            for url in contents {
                totalSize += await measureItemSize(at: url)
            }
            trashSize = totalSize

        } catch {
            // Permission denied or other error
            errorMessage = "Cannot access Trash: \(error.localizedDescription)\n\nMake sure SpaceSaver has Full Disk Access in System Settings → Privacy & Security → Full Disk Access"
            trashSize = 0
            trashItemCount = 0
        }

        isLoading = false
    }

    /// Measures the size of a file or directory
    private func measureItemSize(at url: URL) async -> Int64 {
        let fileManager = FileManager.default

        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            if let size = attributes[.size] as? Int64 {
                return size
            }
        } catch {
            // Fall through to directory calculation
        }

        // If it's a directory, calculate recursively
        var totalSize: Int64 = 0
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            do {
                let attrs = try fileManager.attributesOfItem(atPath: fileURL.path)
                if let size = attrs[.size] as? Int64 {
                    totalSize += size
                }
            } catch {
                continue
            }
        }

        return totalSize
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