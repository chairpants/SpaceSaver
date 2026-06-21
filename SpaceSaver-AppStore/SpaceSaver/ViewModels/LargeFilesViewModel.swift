//
//  LargeFilesViewModel.swift
//  SpaceSaver
//
//  ViewModel for the Large Files scanner.
//  Handles scanning, selection, and deletion of large files.
//

import SwiftUI

@MainActor
final class LargeFilesViewModel: ObservableObject {

    // MARK: - Published State
    @Published var scanResults: [ScanResult] = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var minimumSize: Int64 = 100_000_000  // 100 MB
    @Published var errorMessage: String?
    @Published var showDeleteConfirmation = false
    @Published var isDeleting = false

    // MARK: - Computed Properties

    /// Total size of all found files
    var totalSize: Int64 {
        scanResults.reduce(0) { $0 + $1.sizeInBytes }
    }

    /// Total size of selected (checked) files
    var selectedSize: Int64 {
        scanResults.filter { $0.isSelected }.reduce(0) { $0 + $1.sizeInBytes }
    }

    /// Number of selected files
    var selectedCount: Int {
        scanResults.filter { $0.isSelected }.count
    }

    /// Human-readable total size
    var formattedTotalSize: String {
        FileSizeFormatter.string(fromBytes: totalSize)
    }

    /// Human-readable selected size
    var formattedSelectedSize: String {
        FileSizeFormatter.string(fromBytes: selectedSize)
    }

    // MARK: - Size Thresholds
    /// Available minimum size options for the picker
    let sizeOptions: [(label: String, bytes: Int64)] = [
        ("50 MB", 50_000_000),
        ("100 MB", 100_000_000),
        ("250 MB", 250_000_000),
        ("500 MB", 500_000_000),
        ("1 GB", 1_000_000_000),
    ]

    // MARK: - Dependencies
    private let scanner = FileScanner()

    // MARK: - Actions

    /// Starts scanning the home directory for large files
    func scan() async {
        isScanning = true
        scanProgress = 0
        errorMessage = nil

        let homeDir = FileManager.default.homeDirectoryForCurrentUser

        scanResults = await scanner.scanLargeFiles(
            in: homeDir,
            minimumSize: minimumSize
        ) { progress in
            Task { @MainActor in
                self.scanProgress = progress
            }
        }

        isScanning = false
        scanProgress = 1.0
    }

    /// Toggles selection of a file
    func toggleSelection(_ result: ScanResult) {
        guard let index = scanResults.firstIndex(where: { $0.id == result.id }) else { return }
        scanResults[index].isSelected.toggle()
    }

    /// Selects all files
    func selectAll() {
        for index in scanResults.indices {
            scanResults[index].isSelected = true
        }
    }

    /// Deselects all files
    func deselectAll() {
        for index in scanResults.indices {
            scanResults[index].isSelected = false
        }
    }

    /// Moves selected files to Trash
    func deleteSelected() async {
        let toDelete = scanResults.filter { $0.isSelected }
        guard !toDelete.isEmpty else { return }

        isDeleting = true
        var deletedCount = 0

        for file in toDelete {
            do {
                try FileManager.default.trashItem(at: file.url, resultingItemURL: nil)
                deletedCount += 1
            } catch {
                // If one file fails, keep going with the rest
                errorMessage = "Could not delete \(file.fileName): \(error.localizedDescription)"
            }
        }

        // Remove deleted files from the list
        scanResults.removeAll { $0.isSelected }
        isDeleting = false
    }

    /// Opens the file's location in Finder
    func revealInFinder(_ result: ScanResult) {
        NSWorkspace.shared.selectFile(
            result.url.path,
            inFileViewerRootedAtPath: ""
        )
    }
}