//
//  DashboardViewModel.swift
//  SpaceSaver
//
//  ViewModel for the Dashboard view.
//  Loads disk info and category breakdown data.
//

import SwiftUI

// MARK: - DashboardViewModel
// ObservableObject publishes changes to the view automatically.
// When @Published properties change, SwiftUI redraws the view.
@MainActor
final class DashboardViewModel: ObservableObject {

    // MARK: - Published Properties
    // @Published tells SwiftUI to refresh the view when these change.
    @Published var diskInfo: DiskInfo?
    @Published var categories: [DiskCategory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let diskUsage = DiskUsage.shared

    // MARK: - Load Data
    /// Fetches disk usage info and category breakdown.
    /// Called when the dashboard first appears and when the user refreshes.
    func loadData() async {
        isLoading = true
        errorMessage = nil

        // Get overall disk info (fast — just a system call)
        let info = diskUsage.getBootVolumeInfo()
        diskInfo = info

        // Get category breakdown (slow — needs to scan directories)
        // This runs on a background thread automatically because
        // getCategoryBreakdown() is async
        do {
            categories = await diskUsage.getCategoryBreakdown()
        }

        isLoading = false
    }

    // MARK: - Refresh
    /// Reloads all data. Called by the refresh button.
    func refresh() async {
        await loadData()
    }
}