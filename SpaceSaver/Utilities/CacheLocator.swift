//
//  CacheLocator.swift
//  SpaceSaver
//
//  Finds and measures the size of known cache directories.
//  Used by CacheCleanerViewModel to populate the cache categories.
//

import Foundation

// MARK: - CacheLocator
// Scans known cache locations and reports their sizes.
// Each method targets a specific area where macOS and apps store
// temporary/cache data.
final class CacheLocator {

    static let shared = CacheLocator()
    private init() {}

    // MARK: - Home Directory
    // Shortcut for the current user's home directory path.
    private var homeDir: String {
        FileManager.default.homeDirectoryForCurrentUser.path
    }

    // MARK: - Measure Cache Category
    /// Measures the total size of all paths in a CacheCategory.
    /// - Parameter category: The cache category to measure
    /// - Returns: The category with its calculatedSize updated
    func measureCategory(_ category: CacheCategory) async -> CacheCategory {
        var totalSize: Int64 = 0

        for path in category.paths {
            let fullPath: String
            if path.hasPrefix("/") {
                // Absolute path
                fullPath = path
            } else {
                // Relative to home directory
                fullPath = "\(homeDir)/\(path)"
            }

            let size = await DiskUsage.shared.measureDirectorySize(at: fullPath)
            totalSize += size
        }

        // Return a copy with the calculated size
        var updated = category
        updated.calculatedSize = totalSize
        return updated
    }

    // MARK: - Measure All Categories
    /// Measures all built-in cache categories concurrently.
    /// - Returns: Array of categories with sizes populated
    func measureAllCategories() async -> [CacheCategory] {
        // Run all measurements in parallel for speed
        await withTaskGroup(of: CacheCategory.self) { group in
            for category in CacheCategory.builtInCategories {
                group.addTask {
                    await self.measureCategory(category)
                }
            }

            var results: [CacheCategory] = []
            for await category in group {
                results.append(category)
            }

            // Maintain original order
            let originalOrder = CacheCategory.builtInCategories.map { $0.name }
            return results.sorted { a, b in
                guard let aIndex = originalOrder.firstIndex(of: a.name),
                      let bIndex = originalOrder.firstIndex(of: b.name) else {
                    return false
                }
                return aIndex < bIndex
            }
        }
    }

    // MARK: - Clean Category
    /// Deletes the contents of all paths in a CacheCategory.
    /// Moves items to Trash rather than permanently deleting.
    /// - Parameter category: The cache category to clean
    /// - Returns: Number of bytes freed
    @discardableResult
    func cleanCategory(_ category: CacheCategory) async throws -> Int64 {
        let fileManager = FileManager.default
        var totalFreed: Int64 = 0

        for path in category.paths {
            let fullPath: String
            if path.hasPrefix("/") {
                fullPath = path
            } else {
                fullPath = "\(homeDir)/\(path)"
            }

            let directoryURL = URL(fileURLWithPath: fullPath)

            // Check if the directory exists
            guard fileManager.fileExists(atPath: fullPath) else { continue }

            // Get the size before cleaning (for reporting)
            let sizeBefore = await DiskUsage.shared.measureDirectorySize(at: fullPath)

            // List contents of the directory
            guard let contents = try? fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil
            ) else { continue }

            // Move each item to Trash
            for itemURL in contents {
                do {
                    // trashItem moves to Trash and returns the new location
                    try FileManager.default.trashItem(at: itemURL, resultingItemURL: nil)
                } catch {
                    // Skip items that can't be trashed
                    continue
                }
            }

            totalFreed += sizeBefore
        }

        return totalFreed
    }

    // MARK: - Get Path Details
    /// Returns details about what's in a cache path.
    /// Useful for showing the user what will be deleted before they confirm.
    func getContents(of path: String) -> [URL] {
        let fullPath = path.hasPrefix("/") ? path : "\(homeDir)/\(path)"
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: fullPath),
              let contents = try? fileManager.contentsOfDirectory(
                at: URL(fileURLWithPath: fullPath),
                includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]
              ) else {
            return []
        }

        return contents
    }

    // MARK: - Breakdown (drill-down)
    /// Lists the immediate children of a path, each with its measured size.
    /// Used by the "More Info" view so users can see exactly what a category
    /// contains before cleaning — e.g. which subfolder of Application Support
    /// is actually using all the space.
    ///
    /// - Parameter path: A cache category path (relative to home, or absolute)
    /// - Returns: Top-level items sorted by size, largest first
    func getBreakdown(of path: String) async -> [CacheBreakdownItem] {
        let fullPath = path.hasPrefix("/") ? path : "\(homeDir)/\(path)"
        let fileManager = FileManager.default

        guard let contents = try? fileManager.contentsOfDirectory(
            at: URL(fileURLWithPath: fullPath),
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .totalFileSizeKey]
        ) else {
            return []
        }

        // Measure each child concurrently for speed
        let items = await withTaskGroup(of: CacheBreakdownItem?.self) { group in
            for url in contents {
                group.addTask {
                    guard let values = try? url.resourceValues(
                        forKeys: [.isDirectoryKey, .fileSizeKey, .totalFileSizeKey, .isSymbolicLinkKey]
                    ) else { return nil }

                    let isDir = values.isDirectory == true
                    let isSymlink = values.isSymbolicLink == true

                    // Size: directories measured recursively; files use their file size.
                    // Symlinks report 0 so we don't double-count link targets.
                    let size: Int64
                    if isSymlink {
                        size = 0
                    } else if isDir {
                        size = await DiskUsage.shared.measureDirectorySize(at: url.path)
                    } else {
                        size = Int64(values.totalFileSize ?? values.fileSize ?? 0)
                    }

                    return CacheBreakdownItem(
                        name: url.lastPathComponent,
                        url: url,
                        sizeInBytes: size,
                        isDirectory: isDir,
                        isSymlink: isSymlink
                    )
                }
            }

            var results: [CacheBreakdownItem] = []
            for await item in group {
                if let item { results.append(item) }
            }
            return results
        }

        return items.sorted { $0.sizeInBytes > $1.sizeInBytes }
    }
}

// MARK: - CacheBreakdownItem
// A single top-level item inside a cache path, with its measured size.
// Shown in the "More Info" drill-down sheet.
struct CacheBreakdownItem: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let sizeInBytes: Int64
    let isDirectory: Bool
    let isSymlink: Bool

    var formattedSize: String {
        FileSizeFormatter.string(fromBytes: sizeInBytes)
    }

    /// SF Symbol matching the item kind (folder / file / symlink)
    var systemImage: String {
        if isSymlink { return "folder.badge.gearshape" }
        return isDirectory ? "folder.fill" : "doc.fill"
    }
}