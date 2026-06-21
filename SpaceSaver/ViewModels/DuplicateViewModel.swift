//
//  DuplicateViewModel.swift
//  SpaceSaver
//
//  ViewModel for the Duplicate Finder feature.
//  Scans for duplicate files and lets users choose which to delete.
//

import SwiftUI

@MainActor
final class DuplicateViewModel: ObservableObject {

    // MARK: - Published State
    @Published var duplicateGroups: [DuplicateGroup] = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var errorMessage: String?
    @Published var showDeleteConfirmation = false
    @Published var isDeleting = false

    // MARK: - Scan Directory
    // Default: home directory. User can change this.
    @Published var scanDirectory: URL = FileManager.default.homeDirectoryForCurrentUser

    // MARK: - Computed Properties

    /// Total wasted space across all duplicate groups
    var totalWastedSpace: Int64 {
        duplicateGroups.reduce(0) { $0 + $1.wastedSpace }
    }

    /// Human-readable wasted space
    var formattedWastedSpace: String {
        FileSizeFormatter.string(fromBytes: totalWastedSpace)
    }

    /// Number of duplicate groups found
    var groupCount: Int {
        duplicateGroups.count
    }

    /// Total number of duplicate files
    var totalDuplicateFiles: Int {
        duplicateGroups.reduce(0) { $0 + $1.files.count }
    }

    // MARK: - Dependencies
    private let scanner = FileScanner()

    // MARK: - Cache
    @Published var cacheAge: String? = nil

    // MARK: - Actions

    /// Starts scanning with cache support
    func scan() async {
        // Check cache first
        if let cached: [DuplicateGroup] = ScanCache.shared.get(for: ScanCache.Keys.duplicates, as: [DuplicateGroup].self) {
            duplicateGroups = cached
            cacheAge = ScanCache.shared.ageDescription(for: ScanCache.Keys.duplicates)

            // Refresh in background if cache is older than 5 minutes (duplicates are expensive)
            if let age = ScanCache.shared.age(for: ScanCache.Keys.duplicates), age > 300 {
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
        scanProgress = 0
        errorMessage = nil

        let groups = await scanner.scanDuplicates(
            in: scanDirectory
        ) { progress in
            Task { @MainActor in
                self.scanProgress = progress
            }
        }

        duplicateGroups = groups
        ScanCache.shared.set(groups, for: ScanCache.Keys.duplicates, ttl: .long)
        cacheAge = nil

        isScanning = false
        scanProgress = 1.0
    }

    /// Refreshes data in background without showing loading state
    private func refreshInBackground() async {
        let groups = await scanner.scanDuplicates(
            in: scanDirectory
        ) { _ in
            // No progress updates for background refresh
        }

        // Only update if data changed
        if ScanCache.shared.hasChanged(groups, for: ScanCache.Keys.duplicates, as: [DuplicateGroup].self) {
            duplicateGroups = groups
            ScanCache.shared.set(groups, for: ScanCache.Keys.duplicates, ttl: .long)
            cacheAge = nil
        }
    }

    /// Forces a fresh scan (user pulled to refresh)
    func forceRefresh() async {
        ScanCache.shared.invalidate(ScanCache.Keys.duplicates)
        await performFullScan()
    }

    /// Toggles selection of a file within a duplicate group.
    /// In each group, the user keeps one file and deletes the rest.
    func toggleFileSelection(groupId: UUID, fileId: UUID) {
        guard let groupIndex = duplicateGroups.firstIndex(where: { $0.id == groupId }) else { return }
        guard let fileIndex = duplicateGroups[groupIndex].files.firstIndex(where: { $0.id == fileId }) else { return }
        duplicateGroups[groupIndex].files[fileIndex].isSelected.toggle()
    }

    /// Moves selected duplicate files to Trash.
    /// Only deletes files the user has explicitly checked.
    func deleteSelected() async {
        isDeleting = true

        for groupIndex in duplicateGroups.indices {
            let toDelete = duplicateGroups[groupIndex].files.filter { $0.isSelected }

            for file in toDelete {
                do {
                    try FileManager.default.trashItem(at: file.url, resultingItemURL: nil)
                } catch {
                    errorMessage = "Could not delete \(file.fileName): \(error.localizedDescription)"
                }
            }
        }

        // Remove groups that are now empty or have only 1 file left
        duplicateGroups.removeAll { group in
            let remaining = group.files.filter { !$0.isSelected }
            return remaining.count <= 1
        }

        // Clear selections in remaining groups
        for index in duplicateGroups.indices {
            duplicateGroups[index].files.removeAll { $0.isSelected }
            duplicateGroups[index].files.indices.forEach { duplicateGroups[index].files[$0].isSelected = false }
        }

        isDeleting = false

        // Update cache with modified results
        ScanCache.shared.set(duplicateGroups, for: ScanCache.Keys.duplicates, ttl: .long)
    }
}