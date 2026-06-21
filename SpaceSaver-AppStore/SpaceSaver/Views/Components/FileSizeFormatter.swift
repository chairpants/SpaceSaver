//
//  FileSizeFormatter.swift
//  SpaceSaver
//
//  Formats byte counts into human-readable strings (e.g., "2.4 GB").
//  Used throughout the app whenever we display file sizes.
//

import Foundation

// MARK: - FileSizeFormatter
// A utility that converts raw byte counts to readable strings.
// We use a static method pattern so it's easy to call from anywhere
// without creating an instance.
enum FileSizeFormatter {

    // MARK: - Format Bytes
    /// Converts a byte count to a human-readable string.
    /// - Parameter bytes: The number of bytes
    /// - Returns: A formatted string like "2.4 GB" or "128 KB"
    ///
    /// Uses the "decimal" style (1 KB = 1000 bytes) which is what macOS
    /// Finder shows. Some tools use "binary" (1 KiB = 1024 bytes) but
    /// that would confuse most users.
    static func string(fromBytes bytes: Int64) -> String {
        // Handle edge cases first
        guard bytes >= 0 else { return "0 B" }
        guard bytes > 0 else { return "0 B" }

        // Define our units in ascending order
        // We use decimal units (power of 1000) to match macOS Finder
        let units = ["B", "KB", "MB", "GB", "TB", "PB"]
        var value = Double(bytes)
        var unitIndex = 0

        // Keep dividing by 1000 until we find the right unit
        while value >= 1000 && unitIndex < units.count - 1 {
            value /= 1000
            unitIndex += 1
        }

        // Format with appropriate decimal places:
        // - Bytes: no decimals
        // - KB: 1 decimal
        // - MB and above: 2 decimals
        let decimalPlaces: Int
        switch unitIndex {
        case 0:  decimalPlaces = 0  // Bytes
        case 1:  decimalPlaces = 1  // KB
        default: decimalPlaces = 2  // MB, GB, etc.
        }

        // Use NumberFormatter for locale-aware number formatting
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimalPlaces
        formatter.maximumFractionDigits = decimalPlaces

        let formattedValue = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(formattedValue) \(units[unitIndex])"
    }

    // MARK: - Format with Context
    /// Formats bytes with additional context about how many files.
    /// - Parameters:
    ///   - bytes: Total size in bytes
    ///   - fileCount: Number of files
    /// - Returns: String like "2.4 GB (128 files)"
    static func string(fromBytes bytes: Int64, fileCount: Int) -> String {
        let sizeString = string(fromBytes: bytes)
        let formattedCount = NumberFormatter.localizedString(
            from: NSNumber(value: fileCount),
            number: .decimal
        )
        return "\(sizeString) (\(formattedCount) files)"
    }

    // MARK: - Percentage
    /// Formats a percentage from a fraction.
    /// - Parameter fraction: A value between 0 and 1
    /// - Returns: String like "45.2%"
    static func percentageString(fromFraction fraction: Double) -> String {
        let percentage = max(0, min(1, fraction)) * 100
        return String(format: "%.1f%%", percentage)
    }
}