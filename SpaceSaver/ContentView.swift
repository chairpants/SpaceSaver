//
//  ContentView.swift
//  SpaceSaver
//
//  Main layout: NavigationSplitView with sidebar for feature navigation
//  and detail area for each feature's view.
//

import SwiftUI

// MARK: - Navigation Sections
// Each section in the sidebar. We use an enum so the compiler
// catches typos and we get automatic switch/exhaustiveness checking.
enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case largeFiles = "Large Files"
    case duplicateFinder = "Duplicates"
    case cacheCleaner = "Caches"
    case trashManager = "Trash"
    case downloadsCleaner = "Downloads"
    case appUninstaller = "Apps"
    case loginItems = "Login Items"

    var id: String { rawValue }

    // SF Symbol icon for each section — gives the sidebar a polished look.
    var systemImage: String {
        switch self {
        case .dashboard:       return "chart.pie"
        case .largeFiles:      return "doc.fill"
        case .duplicateFinder: return "doc.on.doc"
        case .cacheCleaner:    return "internaldrive"
        case .trashManager:    return "trash"
        case .downloadsCleaner:return "arrow.down.circle"
        case .appUninstaller:  return "app.dashed"
        case .loginItems:      return "lock.desktopcomputer"
        }
    }
}

struct ContentView: View {
    @State private var selectedSection: SidebarItem? = .dashboard

    var body: some View {
        // NavigationSplitView gives us the standard macOS sidebar + detail layout.
        // It automatically handles sidebar collapse/expand and keyboard navigation.
        NavigationSplitView {
            // MARK: - Sidebar
            sidebar
        } detail: {
            // MARK: - Detail Area
            // Each section gets its own view. We switch on the selected item
            // to show the right content.
            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onReceive(NotificationCenter.default.publisher(for: .selectLargeFiles)) { _ in
            selectedSection = .largeFiles
        }
        .onReceive(NotificationCenter.default.publisher(for: .selectCacheCleaner)) { _ in
            selectedSection = .cacheCleaner
        }
    }

    // MARK: - Sidebar View
    // Lists all sections with icons. Grouped into "Overview" and "Clean Up".
    private var sidebar: some View {
        List(SidebarItem.allCases, selection: $selectedSection) { item in
            Label(item.rawValue, systemImage: item.systemImage)
                .tag(item)
        }
        .navigationTitle("SpaceSaver")
        .listStyle(.sidebar)
    }

    // MARK: - Detail View Router
    // Routes to the correct view based on the selected sidebar item.
    // Falls back to Dashboard when nothing is selected.
    @ViewBuilder
    private var detailView: some View {
        if let section = selectedSection {
            switch section {
            case .dashboard:
                DashboardView()
            case .largeFiles:
                LargeFilesView()
            case .duplicateFinder:
                DuplicateFinderView()
            case .cacheCleaner:
                CacheCleanerView()
            case .trashManager:
                TrashManagerView()
            case .downloadsCleaner:
                DownloadsCleanerView()
            case .appUninstaller:
                AppUninstallerView()
            case .loginItems:
                LoginItemsView()
            }
        } else {
            DashboardView()
        }
    }
}

