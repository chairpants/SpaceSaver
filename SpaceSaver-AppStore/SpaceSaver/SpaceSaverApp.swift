//
//  SpaceSaverApp.swift
//  SpaceSaver (App Store Version)
//
//  A free, open-source Mac disk space cleaner.
//  No subscriptions, no paywalls — just clean disk space.
//

import SwiftUI

// MARK: - App Entry Point
// @main tells Swift this is the app's starting point.
// The body defines the root view hierarchy and settings.
@main
struct SpaceSaverApp: App {

    // MARK: - App Delegate
    // NSApplicationDelegateAdaptor lets us hook into traditional
    // AppKit lifecycle events (like the dock menu) from SwiftUI.
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // WindowGroup creates the main app window.
        // We set a minimum size so the UI doesn't collapse on small screens.
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
        }
        // Standard macOS window chrome (default style)
        .defaultSize(width: 1000, height: 700)
        .windowStyle(.automatic)
        .windowResizability(.contentSize)
        // MARK: - Menu Bar Commands
        // SwiftUI automatically creates standard menus (File, Edit, View, etc.)
        // We add our custom commands here.
        .commands {
            CommandGroup(replacing: .newItem) {
                // Remove "New Window" since we don't support multi-window
            }

            CommandMenu("Tools") {
                Button("Scan Large Files") {
                    NotificationCenter.default.post(name: .selectLargeFiles, object: nil)
                }
                .keyboardShortcut("l", modifiers: .command)

                Button("Scan Caches") {
                    NotificationCenter.default.post(name: .selectCacheCleaner, object: nil)
                }
                .keyboardShortcut("k", modifiers: .command)

                Button("Empty Trash") {
                    NotificationCenter.default.post(name: .emptyTrash, object: nil)
                }
                .keyboardShortcut("e", modifiers: .command)
            }
        }
    }
}

// MARK: - App Delegate
// Handles traditional AppKit events that SwiftUI doesn't cover natively.
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure initial window appearance
        configureInitialWindow()

        // Check if we have Full Disk Access (needed for scanning system directories)
        checkFullDiskAccess()
    }

    /// Configures the initial window to ensure proper layout and styling
    private func configureInitialWindow() {
        // Give the window a moment to be created, then configure it
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                // Ensure proper title bar and toolbar appearance
                window.titlebarAppearsTransparent = false
                window.titleVisibility = .visible

                // Set proper min size to prevent layout issues
                window.minSize = NSSize(width: 900, height: 600)

                // Center the window initially
                window.center()
            }
        }
    }

    /// The app needs Full Disk Access to scan protected directories like
    /// ~/Library. Without it, many scan results will be empty.
    private func checkFullDiskAccess() {
        let testPath = "/Users/\(NSUserName())/Library/Containers"
        let fm = FileManager.default

        // Try to access a protected directory — if it fails, we don't have FDA
        if let contents = try? fm.contentsOfDirectory(atPath: testPath) {
            // If we can read it and it's not empty, we likely have access
            _ = contents
        }
        // Note: We don't block the app if FDA is missing — we just show
        // fewer results. The user can grant it later in System Settings.
    }
}

// MARK: - Notification Names
// Custom notifications let views communicate without tight coupling.
// For example, the menu bar can tell ContentView to switch tabs.
extension Notification.Name {
    static let selectLargeFiles = Notification.Name("selectLargeFiles")
    static let selectCacheCleaner = Notification.Name("selectCacheCleaner")
    static let emptyTrash = Notification.Name("emptyTrash")
}
