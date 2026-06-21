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
            VStack(spacing: Spacing.xlarge) {
                // Header with disk info
                diskOverviewCard

                // Category breakdown chart
                if !viewModel.categories.isEmpty {
                    categoryChart
                }

                // Quick actions
                quickActionsCard
            }
            .padding(Spacing.xlarge)
        }
        .navigationTitle("Dashboard")
        .frame(minWidth: 600, minHeight: 400)
        .task {
            await viewModel.loadData()
        }
        .overlay {
            if viewModel.isLoading {
                ScanningEmptyState(message: "Scanning disk…")
                    .background(.ultraThinMaterial)
            }
        }
    }

    // MARK: - Disk Overview Card
    // Shows total disk, used, and free space with an animated progress ring.
    private var diskOverviewCard: some View {
        CardContainer(isElevated: true) {
            VStack(spacing: Spacing.large) {
                if let info = viewModel.diskInfo {
                    HStack(spacing: Spacing.xxlarge) {
                        // Animated progress ring showing used/free ratio
                        AnimatedProgressRing(
                            percentage: info.usedPercentage,
                            availableBytes: info.availableSpace,
                            size: 160,
                            lineWidth: 20
                        )

                        // Disk info details with improved typography
                        VStack(alignment: .leading, spacing: Spacing.medium) {
                            StatusRow(
                                icon: "internaldrive.fill",
                                label: "Total Capacity",
                                value: info.formattedTotal,
                                iconColor: .blue
                            )

                            Divider()

                            StatusRow(
                                icon: "circle.fill",
                                label: "Used",
                                value: info.formattedUsed,
                                iconColor: usedColor(for: info.usedPercentage)
                            )

                            StatusRow(
                                icon: "checkmark.circle.fill",
                                label: "Available",
                                value: info.formattedAvailable,
                                iconColor: .green
                            )

                            Divider()

                            HStack(spacing: Spacing.compact) {
                                Image(systemName: "percent")
                                    .foregroundStyle(usedColor(for: info.usedPercentage))
                                    .frame(width: 20)

                                Text("Usage")
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text(FileSizeFormatter.percentageString(fromFraction: info.usedPercentage))
                                    .fontWeight(.medium)
                                    .foregroundStyle(usedColor(for: info.usedPercentage))
                            }
                            .font(.subheadline)
                        }
                        .frame(width: 200)

                        Spacer()
                    }
                } else {
                    EmptyStateView(
                        icon: "internaldrive.badge.exclamationmark",
                        title: "Unable to Read Disk",
                        description: "SpaceSaver couldn't access your disk information. This might be a permissions issue.",
                        action: {
                            Task { await viewModel.loadData() }
                        },
                        actionLabel: "Try Again"
                    )
                }
            }
            .padding(Spacing.compact)
        } label: {
            Label("Disk Usage", systemImage: "internaldrive.fill")
        }
    }

    // MARK: - Category Chart
    // Horizontal bar chart showing disk usage by category.
    private var categoryChart: some View {
        CardContainer {
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
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(.secondary.opacity(0.2))
                    AxisValueLabel {
                        if let intValue = value.as(Int64.self) {
                            Text(FileSizeFormatter.string(fromBytes: intValue))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(stroke: StrokeStyle(lineWidth: 0))
            }
            .chartLegend(.hidden)
            .frame(height: CGFloat(viewModel.categories.count) * 40 + 40)
        } label: {
            Label("Storage Breakdown", systemImage: "chart.bar.fill")
        }
    }

    // MARK: - Quick Actions
    // Buttons for common cleanup actions.
    private var quickActionsCard: some View {
        CardContainer {
            HStack(spacing: Spacing.large) {
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
            .padding(.vertical, Spacing.compact)
        } label: {
            Label("Quick Actions", systemImage: "bolt.fill")
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
            VStack(spacing: Spacing.compact) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .symbolRenderingMode(.hierarchical)

                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
            .frame(width: 100, height: 80)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    /// Returns a color based on disk usage percentage.
    /// Green < 70%, Yellow 70-90%, Red > 90%
    private func usedColor(for percentage: Double) -> Color {
        switch percentage {
        case ..<0.7:  return .green
        case 0.7..<0.9: return .orange
        default:      return .red
        }
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
}
