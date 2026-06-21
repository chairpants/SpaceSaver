//
//  ScanResult.swift
//  SpaceSaver
//
//  A generic model for file scan results.
//  Used by Large Files, Duplicates, Downloads, and App Uninstaller
//  to represent a found file with its metadata.
//

import Foundation

// MARK: - ScanResult
// Represents a single file found during a scan.
// Conforms to Identifiable for use in SwiftUI Lists and Tables.
struct ScanResult: Identifiable, Codable {
    let id = UUID()

    /// Full file path on disk
    let url: URL

    /// File size in bytes
    let sizeInBytes: Int64

    /// Last access date (when the file was last opened/read)
    let lastAccessed: Date?

    /// Last modification date
    let lastModified: Date?

    /// Whether this file is selected for deletion by the user
    var isSelected: Bool = false

    // MARK: - Computed Properties

    /// Just the filename (no directory path)
    var fileName: String {
        url.lastPathComponent
    }

    /// The parent directory path as a string
    var directoryPath: String {
        url.deletingLastPathComponent().path
    }

    /// Human-readable file size (e.g., "2.4 GB")
    var formattedSize: String {
        FileSizeFormatter.string(fromBytes: sizeInBytes)
    }

    /// Human-readable last-accessed date (e.g., "3 months ago")
    var formattedLastAccessed: String {
        guard let date = lastAccessed else { return "Unknown" }
        return date.formatted(.relative(presentation: .named))
    }

    /// How long ago the file was last accessed, in days
    var daysSinceLastAccess: Int? {
        guard let date = lastAccessed else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: date, to: Date())
        return components.day
    }

    /// Non-optional date for table column sorting.
    /// Falls back to modification date, then distant past, so files with
    /// no access date still sort deterministically instead of crashing the
    /// sortable TableColumn (which requires a Comparable, non-optional value).
    var sortDate: Date {
        lastAccessed ?? lastModified ?? .distantPast
    }
}

// MARK: - DuplicateGroup
// A set of files that have identical content (determined by file size + hash).
// The user picks which files to keep; the rest are deleted.
struct DuplicateGroup: Identifiable, Codable {
    let id = UUID()

    /// A hash that identifies this duplicate set (same for all files in the group)
    let contentHash: String

    /// The common file size for all files in this group
    let fileSize: Int64

    /// All files that share the same content
    var files: [ScanResult]

    /// How much space can be reclaimed if we keep only one copy
    var wastedSpace: Int64 {
        // Keep one, delete the rest
        guard files.count > 1 else { return 0 }
        return fileSize * Int64(files.count - 1)
    }

    /// Human-readable wasted space
    var formattedWastedSpace: String {
        FileSizeFormatter.string(fromBytes: wastedSpace)
    }

    /// Human-readable file size
    var formattedFileSize: String {
        FileSizeFormatter.string(fromBytes: fileSize)
    }
}