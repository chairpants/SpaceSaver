//
//  CacheCleanerView.swift
//  SpaceSaver
//
//  Shows cache categories with sizes and lets users clean them.
//

import SwiftUI

struct CacheCleanerView: View {
    @StateObject private var viewModel = CacheCleanerViewModel()
    @State private var detailCategory: CacheCategory?

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar

            Divider()

            // Category cards
            if viewModel.categories.isEmpty {
                ProgressView("Scanning caches…")
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                categoryList
            }
        }
        .navigationTitle("Cache Cleaner")
        .task {
            if viewModel.categories.allSatisfy({ $0.calculatedSize == 0 }) {
                await viewModel.scan()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(item: $detailCategory) { category in
            CacheCategoryDetailView(category: category)
        }
    }

    // MARK: - Toolbar
    private var toolbar: some View {
        HStack(spacing: 12) {
            Button {
                Task { await viewModel.scan() }
            } label: {
                Label(viewModel.isScanning ? "Scanning…" : "Rescan", systemImage: "arrow.clockwise")
            }
            .disabled(viewModel.isScanning)

            Spacer()

            if !viewModel.categories.isEmpty {
                Button("Select All") { viewModel.selectAll() }
                Button("Deselect All") { viewModel.deselectAll() }

                if viewModel.selectedSize > 0 {
                    Button(role: .destructive) {
                        viewModel.showCleanConfirmation = true
                    } label: {
                        Label("Clean \(viewModel.formattedSelectedSize)", systemImage: "trash")
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    // MARK: - Category List
    // Shows each cache category as a card with toggle and size info.
    private var categoryList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.categories.indices, id: \.self) { index in
                    categoryCard(index: index)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Category Card
    // A single cache category card showing name, description, size, and toggle.
    private func categoryCard(index: Int) -> some View {
        let category = viewModel.categories[index]
        return GroupBox {
            HStack(spacing: 16) {
                // Toggle
                Toggle("", isOn: $viewModel.categories[index].isSelected)
                    .toggleStyle(.checkbox)

                // Icon
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 36)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(category.name)
                            .fontWeight(.semibold)

                        if category.isCautioned {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                                .help("Deleting this may temporarily slow down the associated app")
                        }
                    }

                    Text(category.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Text(category.paths.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Spacer()

                // Size
                if category.calculatedSize > 0 {
                    Text(category.formattedSize)
                        .font(.title3)
                        .fontWeight(.bold)
                        .monospacedDigit()
                } else if viewModel.isScanning {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("—")
                        .foregroundStyle(.secondary)
                }

                // More Info — drill down to see exactly what's inside this category
                Button {
                    detailCategory = category
                } label: {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.borderless)
                .help("See what's inside this category")
            }
            .padding(8)
        }
    }
}

