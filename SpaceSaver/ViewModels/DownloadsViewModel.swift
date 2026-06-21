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
    @Published var filterDays: Int = 30   // Show files older than N days
    @Published var filterMode: FilterMode = .olderThan

    // MARK: - Filter Options
    enum FilterMode: String, CaseIterable {
        case olderThan = "Older Than"
        case largerThan = "Larger Than"
        case all = "All Files"
    }

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
            let threshold = Int64(filterDays) * 1_000_000  // filterDays used as MB
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

    // MARK: - Actions

    /// Scans the Downloads folder
    func scan() async {
        isScanning = true
        errorMessage = nil

        let downloadsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Downloads")

        files = await scanner.scanLargeFiles(
            in: downloadsURL,
            minimumSize: 0  // Include all sizes
        )

        isScanning = false
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
    }

    /// Opens a file in Finder
    func revealInFinder(_ result: ScanResult) {
        NSWorkspace.shared.selectFile(result.url.path, inFileViewerRootedAtPath: "")
    }
}