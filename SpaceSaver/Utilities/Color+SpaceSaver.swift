//
//  Color+SpaceSaver.swift
//  SpaceSaver
//
//  App-specific semantic colors and design system.
//

import SwiftUI

extension Color {
    // MARK: - App-Specific Semantic Colors

    /// Primary brand color - energetic cyan that evokes "fresh/clean"
    static let spaceSaverPrimary = Color.cyan

    /// Secondary accent for warnings/cautions
    static let spaceSaverWarning = Color.orange

    /// Destructive accent that feels less harsh than pure red
    static let spaceSaverDestructive = Color.pink

    // MARK: - Category Colors (for charts)

    /// Colors that work well in both light and dark mode
    static let categoryColors: [Color] = [
        Color(nsColor: .systemBlue),
        Color(nsColor: .systemGreen),
        Color(nsColor: .systemOrange),
        Color(nsColor: .systemPurple),
        Color(nsColor: .systemTeal),
        Color(nsColor: .systemPink),
        Color(nsColor: .systemIndigo)
    ]

    // MARK: - Section Accent Colors

    static let dashboardAccent = Color.cyan
    static let largeFilesAccent = Color.blue
    static let duplicatesAccent = Color.orange
    static let cacheAccent = Color.teal
    static let trashAccent = Color.red
    static let downloadsAccent = Color.indigo
    static let appsAccent = Color.purple
    static let loginItemsAccent = Color.green
}
