//
//  DownloadsViewModel.swift
//  SpaceSaver
//
//  ViewModel for the Downloads Cleaner feature.
//  Lists files in ~/Downloads and lets users clean old/large ones.
//

import SwiftUI

@MainActor
final class DownloadsViewModel: ObservableObject {

    // MARK: - Published State
    @Published var files: [ScanResult] = []
    @Published var isScanning = false
    @Published var errorMessage: String?
    @Published var showDeleteConfirmation = false
    @Published var isDeleting = false

    // MARK: - Filter State
    @Published var filterDays: Int = 30       // Show files older than N days
    @Published var filterSizeMB: Int = 10   // Show files larger than N MB
    @Published var filterMode: FilterMode = .all

    // MARK: - Filter Options
    enum FilterMode: String, CaseIterable {
        case all = "All Files"
        case olderThan = "Older Than"
        case largerThan = "Larger Than"
    }

    // MARK: - Size Options
    let sizeOptions: [(label: String, mb: Int)] = [
        ("1 MB", 1),
        ("10 MB", 10),
        ("100 MB", 100),
        ("500 MB", 500),
        ("1 GB", 1024),
    ]

    // MARK: - Computed Properties

    /// Files matching the current filter. Sorting is handled by the table's
    /// column headers (sortOrder), not here, so clicking a column works.
    var filteredFiles: [ScanResult] {
        var result = files

        // Apply filter
        switch filterMode {
        case .olderThan:
            result = result.filter { file in
                guard let days = file.daysSinceLastAccess else { return false }
                return days >= filterDays
            }
        case .largerThan:
            let threshold = Int64(filterSizeMB) * 1_000_000  // MB to bytes
            result = result.filter { $0.sizeInBytes >= threshold }
        case .all:
            break  // No filter
        }

        return result
    }

    /// Total size of all filtered files
    var filteredTotalSize: Int64 {
        filteredFiles.reduce(0) { $0 + $1.sizeInBytes }
    }

    /// Total size of selected files
    var selectedSize: Int64 {
        files.filter { $0.isSelected }.reduce(0) { $0 + $1.sizeInBytes }
    }

    /// Number of selected files
    var selectedCount: Int {
        files.filter { $0.isSelected }.count
    }

    /// Human-readable sizes
    var formattedFilteredTotalSize: String {
        FileSizeFormatter.string(fromBytes: filteredTotalSize)
    }

    var formattedSelectedSize: String {
        FileSizeFormatter.string(fromBytes: selectedSize)
    }

    // MARK: - Dependencies
    private let scanner = FileScanner()

    // MARK: - Cache
    @Published var cacheAge: String? = nil

    // MARK: - Actions

    /// Scans the Downloads folder with cache support
    func scan() async {
        // Check cache first
        if let cached: [ScanResult] = ScanCache.shared.get(for: ScanCache.Keys.downloads, as: [ScanResult].self) {
            files = cached
            cacheAge = ScanCache.shared.ageDescription(for: ScanCache.Keys.downloads)

            // Refresh in background if cache is older than 2 minutes
            if let age = ScanCache.shared.age(for: ScanCache.Keys.downloads), age > 120 {
                await refreshInBackground()
            }
            return
        }

        // No cache - do full scan
        await performFullScan()
    }

    /// Performs a full scan and updates cache
    private func performFullScan() async {
        isScanning = true
        errorMessage = nil

        let downloadsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Downloads")

        let results = await scanner.scanLargeFiles(
            in: downloadsURL,
            minimumSize: 0  // Include all sizes
        )

        files = results
        ScanCache.shared.set(results, for: ScanCache.Keys.downloads, ttl: .medium)
        cacheAge = nil

        isScanning = false
    }

    /// Refreshes data in background without showing loading state
    private func refreshInBackground() async {
        let downloadsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Downloads")

        let results = await scanner.scanLargeFiles(
            in: downloadsURL,
            minimumSize: 0
        )

        // Only update if data changed
        if ScanCache.shared.hasChanged(results, for: ScanCache.Keys.downloads, as: [ScanResult].self) {
            files = results
            ScanCache.shared.set(results, for: ScanCache.Keys.downloads, ttl: .medium)
            cacheAge = nil
        }
    }

    /// Forces a fresh scan (user pulled to refresh)
    func forceRefresh() async {
        ScanCache.shared.invalidate(ScanCache.Keys.downloads)
        await performFullScan()
    }

    /// Toggles selection of a file
    func toggleSelection(_ result: ScanResult) {
        guard let index = files.firstIndex(where: { $0.id == result.id }) else { return }
        files[index].isSelected.toggle()
    }

    /// Selects all visible (filtered) files
    func selectAll() {
        let visibleIds = Set(filteredFiles.map { $0.id })
        for index in files.indices {
            if visibleIds.contains(files[index].id) {
                files[index].isSelected = true
            }
        }
    }

    /// Deselects all files
    func deselectAll() {
        for index in files.indices {
            files[index].isSelected = false
        }
    }

    /// Moves selected files to Trash
    func deleteSelected() async {
        isDeleting = true

        let toDelete = files.filter { $0.isSelected }

        for file in toDelete {
            do {
                try FileManager.default.trashItem(at: file.url, resultingItemURL: nil)
            } catch {
                errorMessage = "Could not delete \(file.fileName): \(error.localizedDescription)"
            }
        }

        // Remove deleted files from the list
        files.removeAll { $0.isSelected }
        isDeleting = false

        // Update cache with modified results
        ScanCache.shared.set(files, for: ScanCache.Keys.downloads, ttl: .medium)
    }

    /// Opens a file in Finder
    func revealInFinder(_ result: ScanResult) {
        NSWorkspace.shared.selectFile(result.url.path, inFileViewerRootedAtPath: "")
    }
}