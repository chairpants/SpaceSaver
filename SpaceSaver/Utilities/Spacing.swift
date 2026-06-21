//
//  Spacing.swift
//  SpaceSaver
//
//  Consistent spacing values for the entire app.
//

import SwiftUI

/// Consistent spacing values for the entire app
enum Spacing {
    /// 4 points - Tight spacing for related elements
    static let tight: CGFloat = 4

    /// 8 points - Standard internal padding
    static let compact: CGFloat = 8

    /// 12 points - Between related components
    static let small: CGFloat = 12

    /// 16 points - Standard component padding
    static let medium: CGFloat = 16

    /// 20 points - Between major sections
    static let large: CGFloat = 20

    /// 24 points - Section padding
    static let xlarge: CGFloat = 24

    /// 32 points - Major section breaks
    static let xxlarge: CGFloat = 32
}

/// Corner radius values for consistency
enum CornerRadius {
    /// 4 points - Small elements like badges
    static let small: CGFloat = 4

    /// 8 points - Buttons, input fields
    static let medium: CGFloat = 8

    /// 12 points - Cards and containers
    static let large: CGFloat = 12

    /// 16 points - Major containers
    static let xlarge: CGFloat = 16
}
