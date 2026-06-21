//
//  CacheCleanerViewModel.swift
//  SpaceSaver
//
//  ViewModel for the Cache Cleaner feature.
//  Measures cache sizes and cleans selected categories.
//

import SwiftUI

@MainActor
final class CacheCleanerViewModel: ObservableObject {

    // MARK: - Published State
    @Published var categories: [CacheCategory] = []
    @Published var isScanning = false
    @Published var isCleaning = false
    @Published var errorMessage: String?
    @Published var showCleanConfirmation = false
    @Published var totalFreed: Int64 = 0

    // MARK: - Computed Properties

    /// Categories selected for cleaning
    var selectedCategories: [CacheCategory] {
        categories.filter { $0.isSelected }
    }

    /// Total size of selected categories
    var selectedSize: Int64 {
        selectedCategories.reduce(0) { $0 + $1.calculatedSize }
    }

    /// Human-readable selected size
    var formattedSelectedSize: String {
        FileSizeFormatter.string(fromBytes: selectedSize)
    }

    /// Total size of all categories
    var totalSize: Int64 {
        categories.reduce(0) { $0 + $1.calculatedSize }
    }

    /// Human-readable total size
    var formattedTotalSize: String {
        FileSizeFormatter.string(fromBytes: totalSize)
    }

    // MARK: - Dependencies
    private let cacheLocator = CacheLocator.shared

    // MARK: - Cache
    @Published var cacheAge: String? = nil

    // MARK: - Actions

    /// Scans all cache categories and calculates their sizes
    func scan() async {
        // Check cache first
        if let cached = ScanCache.shared.get(for: ScanCache.Keys.cacheCleaner) {
            categories = cached
            cacheAge = ScanCache.shared.ageDescription(for: ScanCache.Keys.cacheCleaner)

            // Refresh in background if cache is older than 1 minute (cache sizes change often)
            if let age = ScanCache.shared.age(for: ScanCache.Keys.cacheCleaner), age > 60 {
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

        // Start with built-in categories (unselected, size = 0)
        categories = CacheCategory.builtInCategories

        // Measure each category's size concurrently
        let measured = await cacheLocator.measureAllCategories()

        // Preserve selection state and update sizes
        for index in categories.indices {
            if let measuredCategory = measured.first(where: { $0.name == categories[index].name }) {
                categories[index].calculatedSize = measuredCategory.calculatedSize
            }
        }

        ScanCache.shared.set(categories, for: ScanCache.Keys.cacheCleaner, ttl: .short)
        cacheAge = nil

        isScanning = false
    }

    /// Refreshes data in background without showing loading state
    private func refreshInBackground() async {
        let measured = await cacheLocator.measureAllCategories()

        // Create new categories array with updated sizes
        var updatedCategories = CacheCategory.builtInCategories
        for index in updatedCategories.indices {
            if let measuredCategory = measured.first(where: { $0.name == updatedCategories[index].name }) {
                updatedCategories[index].calculatedSize = measuredCategory.calculatedSize
            }
        }

        // Only update if data changed
        if ScanCache.shared.hasChanged(updatedCategories, for: ScanCache.Keys.cacheCleaner) {
            categories = updatedCategories
            ScanCache.shared.set(categories, for: ScanCache.Keys.cacheCleaner, ttl: .short)
            cacheAge = nil
        }
    }

    /// Forces a fresh scan (user pulled to refresh)
    func forceRefresh() async {
        ScanCache.shared.invalidate(ScanCache.Keys.cacheCleaner)
        await performFullScan()
    }

    /// Toggles selection of a category
    func toggleCategory(_ category: CacheCategory) {
        guard let index = categories.firstIndex(where: { $0.id == category.id }) else { return }
        categories[index].isSelected.toggle()
    }

    /// Selects all categories
    func selectAll() {
        for index in categories.indices {
            categories[index].isSelected = true
        }
    }

    /// Deselects all categories
    func deselectAll() {
        for index in categories.indices {
            categories[index].isSelected = false
        }
    }

    /// Cleans the selected cache categories.
    /// Moves items to Trash rather than permanently deleting.
    func cleanSelected() async {
        isCleaning = true
        var totalFreedThisRun: Int64 = 0

        for category in selectedCategories {
            do {
                let freed = try await cacheLocator.cleanCategory(category)
                totalFreedThisRun += freed
            } catch {
                errorMessage = "Error cleaning \(category.name): \(error.localizedDescription)"
            }
        }

        totalFreed += totalFreedThisRun
        isCleaning = false

        // Re-scan to update sizes
        await scan()
    }
}