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

    /// SF Symbol icon with filled variant for better visibility
    var systemImage: String {
        switch self {
        case .dashboard:        return "chart.pie.fill"
        case .largeFiles:       return "doc.text.fill"
        case .duplicateFinder:  return "doc.on.doc.fill"
        case .cacheCleaner:     return "internaldrive.fill"
        case .trashManager:     return "trash.fill"
        case .downloadsCleaner: return "arrow.down.circle.fill"
        case .appUninstaller:   return "app.fill"
        case .loginItems:       return "lock.desktopcomputer"
        }
    }

    /// Accent color for each section - helps users mentally map sections
    var accentColor: Color {
        switch self {
        case .dashboard:        return .cyan
        case .largeFiles:       return .blue
        case .duplicateFinder:  return .orange
        case .cacheCleaner:     return .teal
        case .trashManager:     return .red
        case .downloadsCleaner: return .indigo
        case .appUninstaller:   return .purple
        case .loginItems:       return .green
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
    // Lists all sections with icons using hierarchical rendering for depth.
    // Width is constrained to prevent it from extending past screen edge.
    private var sidebar: some View {
        List(SidebarItem.allCases, selection: $selectedSection) { item in
            Label {
                Text(item.rawValue)
            } icon: {
                Image(systemName: item.systemImage)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(item.accentColor)
            }
            .tag(item)
        }
        .navigationTitle("SpaceSaver")
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 150, ideal: 180, max: 250)
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

// MARK: - Preview
#Preview {
    ContentView()
}
