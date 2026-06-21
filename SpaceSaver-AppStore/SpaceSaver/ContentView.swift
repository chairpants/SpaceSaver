//
//  ContentView.swift
//  SpaceSaver (App Store Version)
//
//  Main layout: NavigationSplitView with sidebar for feature navigation
//  and detail area for each feature's view.
//

import SwiftUI

// MARK: - Navigation Sections
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
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedSection) { item in
                Label(item.rawValue, systemImage: item.systemImage)
                    .foregroundStyle(item.accentColor)
                    .tag(item)
            }
            .listStyle(.sidebar)
            .navigationTitle("SpaceSaver")
            .frame(minWidth: 160, idealWidth: 180, maxWidth: 220)
        } detail: {
            detailView
        }
        .onReceive(NotificationCenter.default.publisher(for: .selectLargeFiles)) { _ in
            selectedSection = .largeFiles
        }
        .onReceive(NotificationCenter.default.publisher(for: .selectCacheCleaner)) { _ in
            selectedSection = .cacheCleaner
        }
    }

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

#Preview {
    ContentView()
        .frame(minWidth: 900, minHeight: 600)
}
