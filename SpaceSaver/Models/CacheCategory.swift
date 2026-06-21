//
//  CacheCategory.swift
//  SpaceSaver
//
//  Defines the types of caches and temporary files the app can clean.
//  Each category maps to a specific set of directories on disk.
//

import Foundation

// MARK: - CacheCategory
// Represents a category of cache/temporary files that can be cleaned.
// Examples: Xcode Derived Data, Safari Cache, System Logs, etc.
struct CacheCategory: Identifiable, Codable {
    let id = UUID()

    /// Display name (e.g., "Xcode Derived Data")
    let name: String

    /// SF Symbol icon name
    let icon: String

    /// Description shown to the user
    let description: String

    /// The directory paths this category cleans
    /// These are all relative to the user's home directory
    let paths: [String]

    /// Whether this category is selected for cleaning
    var isSelected: Bool = false

    /// The calculated size of all paths combined (in bytes)
    /// Set after scanning; 0 before scan
    var calculatedSize: Int64 = 0

    /// Whether this category is potentially risky to clean
    /// (e.g., browser caches can slow down browsing temporarily)
    let isCautioned: Bool

    /// Human-readable size
    var formattedSize: String {
        FileSizeFormatter.string(fromBytes: calculatedSize)
    }
}

// MARK: - Built-in Cache Categories
// Predefined categories for common macOS caches.
// Users can toggle these on/off before cleaning.
extension CacheCategory {

    /// All built-in cache categories with their paths
    static let builtInCategories: [CacheCategory] = [
        // Xcode caches — safe to delete, Xcode rebuilds as needed
        CacheCategory(
            name: "Xcode Derived Data",
            icon: "hammer",
            description: "Build artifacts and indexes. Xcode rebuilds these automatically.",
            paths: [
                "Library/Developer/Xcode/DerivedData"
            ],
            isCautioned: false
        ),
        CacheCategory(
            name: "Xcode Archives",
            icon: "archivebox",
            description: "Saved app archives. Only delete if you don't need to export old builds.",
            paths: [
                "Library/Developer/Xcode/Archives"
            ],
            isCautioned: true
        ),
        CacheCategory(
            name: "Xcode Simulators",
            icon: "iphone",
            description: "iOS/tvOS/watchOS simulator runtimes and data.",
            paths: [
                "Library/Developer/CoreSimulator"
            ],
            isCautioned: true
        ),
        CacheCategory(
            name: "Xcode Device Support",
            icon: "desktopcomputer",
            description: "Debugging symbols and device support files.",
            paths: [
                "Library/Developer/Xcode/iOS DeviceSupport",
                "Library/Developer/Xcode/watchOS DeviceSupport",
                "Library/Developer/Xcode/tvOS DeviceSupport"
            ],
            isCautioned: true
        ),

        // Browser caches
        CacheCategory(
            name: "Safari Cache",
            icon: "safari",
            description: "Safari browser cache. Websites may load slightly slower after clearing.",
            paths: [
                "Library/Caches/com.apple.Safari",
                "Library/Safari/LocalStorage"
            ],
            isCautioned: true
        ),
        CacheCategory(
            name: "Chrome Cache",
            icon: "globe",
            description: "Google Chrome browser cache and temporary files.",
            paths: [
                "Library/Application Support/Google/Chrome/Default/Cache",
                "Library/Application Support/Google/Chrome/Default/Code Cache",
                "Library/Caches/Google"
            ],
            isCautioned: true
        ),
        CacheCategory(
            name: "Firefox Cache",
            icon: "flame",
            description: "Firefox browser cache and temporary data.",
            paths: [
                "Library/Caches/Firefox"
            ],
            isCautioned: true
        ),

        // System caches
        CacheCategory(
            name: "System Caches",
            icon: "internaldrive",
            description: "macOS system-level caches for various apps and services.",
            paths: [
                "Library/Caches"
            ],
            isCautioned: true
        ),
        CacheCategory(
            name: "System Logs",
            icon: "doc.text",
            description: "Application and system log files. Generally safe to delete.",
            paths: [
                "Library/Logs"
            ],
            isCautioned: false
        ),
        CacheCategory(
            name: "Application Support (All App Data)",
            icon: "app.dashed",
            description: "Active data for installed apps (NOT just leftovers). Often huge because it includes iCloud Drive's Mobile Documents. Use More Info to see the breakdown before considering any deletion.",
            paths: [
                "Library/Application Support"
            ],
            isCautioned: true
        )
    ]
}