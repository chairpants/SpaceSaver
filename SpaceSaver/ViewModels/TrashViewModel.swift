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

    // MARK: - Cache
    @Published var cacheAge: String? = nil

    // Simple struct for caching trash stats
    private struct TrashStats: Codable {
        let size: Int64
        let count: Int
    }

    // MARK: - Refresh Trash Info
    /// Queries the size and contents of the Trash folder with cache support
    func refresh() async {
        // Check cache first
        if let cached: TrashStats = ScanCache.shared.get(for: ScanCache.Keys.trash, as: TrashStats.self) {
            trashSize = cached.size
            trashItemCount = cached.count
            cacheAge = ScanCache.shared.ageDescription(for: ScanCache.Keys.trash)

            // Refresh in background if cache is older than 1 minute
            if let age = ScanCache.shared.age(for: ScanCache.Keys.trash), age > 60 {
                await refreshInBackground()
            }
            return
        }

        // No cache - do full refresh
        await performFullRefresh()
    }

    /// Performs a full refresh and updates cache
    private func performFullRefresh() async {
        isLoading = true
        errorMessage = nil

        let (size, count) = await calculateTrashStats()
        trashSize = size
        trashItemCount = count

        // Store in cache
        let stats = TrashStats(size: size, count: count)
        ScanCache.shared.set(stats, for: ScanCache.Keys.trash, ttl: .short)
        cacheAge = nil

        isLoading = false
    }

    /// Calculates trash size and count
    private func calculateTrashStats() async -> (size: Int64, count: Int) {
        let trashURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".Trash")
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: trashURL.path) else {
            return (0, 0)
        }

        do {
            let contents = try fileManager.contentsOfDirectory(at: trashURL, includingPropertiesForKeys: nil)
            var totalSize: Int64 = 0
            for url in contents {
                totalSize += await measureItemSize(at: url)
            }
            return (totalSize, contents.count)
        } catch {
            errorMessage = "Cannot access Trash: \(error.localizedDescription)"
            return (0, 0)
        }
    }

    /// Refreshes data in background without showing loading state
    private func refreshInBackground() async {
        let (size, count) = await calculateTrashStats()

        // Only update if changed
        let newStats = TrashStats(size: size, count: count)
        if ScanCache.shared.hasChanged(newStats, for: ScanCache.Keys.trash, as: TrashStats.self) {
            trashSize = size
            trashItemCount = count
            ScanCache.shared.set(newStats, for: ScanCache.Keys.trash, ttl: .short)
            cacheAge = nil
        }
    }

    /// Forces a fresh refresh
    func forceRefresh() async {
        ScanCache.shared.invalidate(ScanCache.Keys.trash)
        await performFullRefresh()
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

        // Clear cache and refresh
        ScanCache.shared.invalidate(ScanCache.Keys.trash)
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