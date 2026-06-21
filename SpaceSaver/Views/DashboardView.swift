//
//  DashboardView.swift
//  SpaceSaver
//
//  The main dashboard showing disk usage overview.
//  This is the first screen users see when they open the app.
//

import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with disk info
                diskOverviewCard

                // Category breakdown chart
                if !viewModel.categories.isEmpty {
                    categoryChart
                }

                // Quick actions
                quickActionsCard
            }
            .padding(24)
        }
        .navigationTitle("Dashboard")
        .task {
            // Load data when the view first appears.
            // .task automatically runs on a background thread.
            await viewModel.loadData()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Scanning disk…")
                    .padding(24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Disk Overview Card
    // Shows total disk, used, and free space with a progress ring.
    private var diskOverviewCard: some View {
        GroupBox {
            VStack(spacing: 16) {
                if let info = viewModel.diskInfo {
                    HStack(spacing: 32) {
                        // Progress ring showing used/free ratio
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 16)
                                .frame(width: 160, height: 160)

                            Circle()
                                .trim(from: 0, to: info.usedPercentage)
                                .stroke(
                                    usedColor(for: info.usedPercentage),
                                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                                )
                                .frame(width: 160, height: 160)
                                .rotationEffect(.degrees(-90))

                            VStack(spacing: 4) {
                                Text(info.formattedAvailable)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Available")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Disk info details
                        VStack(alignment: .leading, spacing: 12) {
                            StatusRow(
                                icon: "internaldrive",
                                label: "Total Capacity",
                                value: info.formattedTotal,
                                iconColor: .blue
                            )
                            StatusRow(
                                icon: "circle.fill",
                                label: "Used",
                                value: info.formattedUsed,
                                iconColor: .orange
                            )
                            StatusRow(
                                icon: "circle.dashed",
                                label: "Available",
                                value: info.formattedAvailable,
                                iconColor: .green
                            )
                            StatusRow(
                                icon: "percent",
                                label: "Usage",
                                value: FileSizeFormatter.percentageString(fromFraction: info.usedPercentage),
                                iconColor: usedColor(for: info.usedPercentage)
                            )
                        }

                        Spacer()
                    }
                } else {
                    Text("Unable to read disk information")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(8)
        } label: {
            Label("Disk Usage", systemImage: "internaldrive")
                .font(.headline)
        }
    }

    // MARK: - Category Chart
    // Horizontal bar chart showing disk usage by category.
    // Broken into a separate build expression to avoid "unable to type-check" errors.
    private var categoryChart: some View {
        GroupBox {
            chartContent
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisValueLabel {
                            if let intValue = value.as(Int64.self) {
                                Text(FileSizeFormatter.string(fromBytes: intValue))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: CGFloat(viewModel.categories.count) * 30 + 20)
        } label: {
            Label("Storage Breakdown", systemImage: "chart.bar")
                .font(.headline)
        }
    }

    /// Extracted chart body to simplify type-checking.
    private var chartContent: some View {
        Chart(viewModel.categories) { category in
            BarMark(
                x: .value("Size", category.sizeInBytes),
                y: .value("Category", category.name)
            )
            .foregroundStyle(by: .value("Category", category.name))
            .annotation(position: .trailing) {
                Text(category.formattedSize)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Quick Actions
    // Buttons for common cleanup actions.
    private var quickActionsCard: some View {
        GroupBox {
            HStack(spacing: 16) {
                Spacer()

                quickActionButton(
                    icon: "magnifyingglass",
                    title: "Find Large\nFiles",
                    color: .blue
                ) {
                    NotificationCenter.default.post(name: .selectLargeFiles, object: nil)
                }

                quickActionButton(
                    icon: "internaldrive",
                    title: "Clean\nCaches",
                    color: .orange
                ) {
                    NotificationCenter.default.post(name: .selectCacheCleaner, object: nil)
                }

                quickActionButton(
                    icon: "trash",
                    title: "Empty\nTrash",
                    color: .red
                ) {
                    NotificationCenter.default.post(name: .emptyTrash, object: nil)
                }

                Spacer()
            }
            .padding(.vertical, 8)
        } label: {
            Label("Quick Actions", systemImage: "bolt")
                .font(.headline)
        }
    }

    // MARK: - Quick Action Button
    private func quickActionButton(
        icon: String,
        title: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(color)

                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
            .frame(width: 100, height: 80)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    /// Returns a color based on disk usage percentage.
    /// Green < 70%, Yellow 70-90%, Red > 90%
    private func usedColor(for percentage: Double) -> Color {
        switch percentage {
        case ..<0.7:  return .green
        case 0.7..<0.9: return .yellow
        default:      return .red
        }
    }
}

