# SpaceSaver

<p align="center">
  <img src="SpaceSaver/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" width="128" alt="SpaceSaver App Icon">
</p>

<p align="center">
  <strong>A free, open-source macOS app to help you reclaim disk space.</strong><br>
  No subscriptions, no paywalls — just clean disk space.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13+-blue?logo=apple" alt="macOS 13+">
  <img src="https://img.shields.io/badge/Swift-SwiftUI-orange?logo=swift" alt="SwiftUI">
  <img src="https://img.shields.io/badge/license-Free-green" alt="License: Free">
</p>

---

## ✨ Features

SpaceSaver combines powerful disk cleaning tools with a beautiful, native macOS interface.

### 📊 Dashboard
- **Visual Disk Overview** — Animated progress ring showing used vs available space
- **Storage Breakdown** — Horizontal bar chart of disk usage by category
- **Quick Actions** — One-click shortcuts to common cleaning tasks
- **Color-coded Status** — Green (healthy), orange (warning), red (critical) disk usage indicators

### 📁 Large Files Scanner
- Scan entire home directory for files over customizable thresholds
- **Size Filters** — 50 MB, 100 MB, 250 MB, 500 MB, 1 GB minimums
- **Sortable Table** — Sort by name, size, last opened, or path
- **Reveal in Finder** — Jump directly to file locations
- **Safe Deletion** — Move to Trash with confirmation (never permanent)

### 📋 Duplicate Finder
- **Content-based Detection** — SHA-256 hash verification ensures true duplicates
- **Size Grouping** — Fast initial filtering by file size
- **Smart Grouping** — View duplicate files grouped by matching content
- **Wasted Space Display** — See exactly how much space duplicates consume
- **Selective Deletion** — Keep one copy, delete the rest

### 🧹 Cache Cleaner
- **One-click Cleaning** for common cache locations:
  - Xcode Derived Data
  - Safari, Chrome, Firefox caches
  - System and user caches
  - Application support files
- **Category Cards** — Visual breakdown of each cache type with sizes
- **Caution Indicators** — Warns about caches that may affect app performance

### 🗑️ Trash Manager
- **Visual Gauge** — See Trash size at a glance
- **One-click Empty** — Empty Trash with confirmation
- **Open in Finder** — Browse Trash before emptying

### 📥 Downloads Cleaner
- **Smart Filters** — Filter by age (30/60/90/180/365 days) or size
- **Default View** — Shows all files by default
- **Adaptive Empty State** — Smart messaging when filters hide files
- **Quick Actions** — Select all, deselect all, delete selected

### 📦 App Uninstaller
- **App Listing** — Browse installed applications
- **Leftover Detection** — Find support files in Application Support, Preferences, Caches
- **Complete Removal** — Delete apps and their associated files

### 🔐 Login Items Manager
- **Launch Agents** — View and toggle startup items
- **Login Items** — Manage apps that open at login
- **Status Indicators** — See which items are currently enabled

---

## 🎨 Design Highlights

SpaceSaver features a premium macOS-native design:

| Feature | Description |
|---------|-------------|
| **Glassmorphism Cards** | Rounded cards with subtle shadows and material backgrounds |
| **Animated Progress Ring** | Smooth gradient ring showing disk usage with entrance animations |
| **Empty States** | Beautiful animated illustrations when no results are found |
| **SF Symbols** | Hierarchical rendering with section-specific accent colors |
| **Consistent Spacing** | Design system with standardized spacing throughout |
| **Hierarchical Navigation** | Three-column layout potential (future enhancement) |

---

## 📸 Screenshots

<p align="center">
  <em>Screenshots coming soon — the app looks great in dark mode too!</em>
</p>

---

## 🚀 Getting Started

### Requirements

- **macOS 13.0 (Ventura)** or later
- **Xcode 15+** to build (developed with Xcode 26)
- **Full Disk Access** recommended — System Settings → Privacy & Security → Full Disk Access

> ⚠️ **Note:** Full Disk Access is needed to scan protected directories like `~/Library`. Without it, some scan results will be empty.

### Building

#### Option A: Open in Xcode (Recommended)

```bash
open SpaceSaver.xcodeproj
```

Then press `⌘R` to build and run.

#### Option B: Command Line

```bash
# Switch to full Xcode first (if not already done)
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# Build Debug version
xcodebuild -project SpaceSaver.xcodeproj -scheme SpaceSaver -configuration Debug build

# Build Release version
xcodebuild -project SpaceSaver.xcodeproj -scheme SpaceSaver -configuration Release build
```

#### Option C: Regenerate Project

If the `.xcodeproj` gets out of sync:

```bash
python3 generate_project.py
```

Then open the freshly generated `SpaceSaver.xcodeproj`.

---

## 📁 Project Structure

```
SpaceSaver/
├── SpaceSaver.xcodeproj           # Xcode project (generated)
├── generate_project.py              # Project generator
├── generate_icon.py               # Icon generator
├── README.md
├── LICENSE
└── SpaceSaver/                    # App source code
    ├── SpaceSaverApp.swift        # App entry point
    ├── ContentView.swift          # Sidebar navigation
    ├── Info.plist
    ├── Entitlements.plist
    ├── SpaceSaver-Icon.svg        # App icon source
    ├── Assets.xcassets/           # Icons, accent colors
    │   └── AppIcon.appiconset/    # macOS app icons (10 sizes)
    ├── Models/                    # Data models
    │   ├── DiskInfo.swift
    │   ├── ScanResult.swift
    │   └── CacheCategory.swift
    ├── ViewModels/                # Business logic
    │   ├── DashboardViewModel.swift
    │   ├── LargeFilesViewModel.swift
    │   ├── DuplicateViewModel.swift
    │   ├── CacheCleanerViewModel.swift
    │   ├── TrashViewModel.swift
    │   ├── DownloadsViewModel.swift
    │   ├── AppUninstallerViewModel.swift
    │   └── LoginItemsViewModel.swift
    ├── Views/                     # SwiftUI screens
    │   ├── DashboardView.swift
    │   ├── LargeFilesView.swift
    │   ├── DuplicateFinderView.swift
    │   ├── CacheCleanerView.swift
    │   ├── CacheCategoryDetailView.swift
    │   ├── TrashManagerView.swift
    │   ├── DownloadsCleanerView.swift
    │   ├── AppUninstallerView.swift
    │   ├── LoginItemsView.swift
    │   └── Components/            # Reusable UI components
    │       ├── CardContainer.swift
    │       ├── AnimatedProgressRing.swift
    │       ├── EmptyStateView.swift
    │       ├── ProgressView+.swift
    │       ├── FileSizeFormatter.swift
    │       ├── ConfirmDeleteView.swift
    │       └── StatusBadge.swift
    ├── Utilities/                 # Helper utilities
    │   ├── DiskUsage.swift
    │   ├── FileScanner.swift
    │   ├── CacheLocator.swift
    │   ├── Color+SpaceSaver.swift
    │   └── Spacing.swift
    └── ViewModels/                # (see above)
```

---

## 🏗️ Architecture

SpaceSaver follows modern SwiftUI patterns:

### MVVM Pattern
- Each feature has a **View** + **ViewModel** pair
- ViewModels are `@MainActor` `ObservableObject` classes with `@Published` properties
- Views observe state changes and react accordingly

### Background Processing
- All file scanning runs on background threads via `Task.detached`
- Keeps UI responsive during long operations
- Progress callbacks update UI on `@MainActor`

### Safety First
- **All deletions move files to Trash** — never permanent delete
- Bulk operations require confirmation dialogs
- Error handling with user-friendly messages

### Non-Sandboxed
- Runs outside App Sandbox for full filesystem access
- Cannot be distributed via Mac App Store
- Can be shared directly (notarize for Gatekeeper compliance)

---

## 🔒 Permissions

### Full Disk Access

SpaceSaver needs Full Disk Access to scan protected directories:

1. Open **System Settings** → **Privacy & Security** → **Full Disk Access**
2. Click the **+** button
3. Add **SpaceSaver.app**
4. Restart SpaceSaver

Without this permission, scans of `~/Library`, `~/Containers`, and system directories will return incomplete results.

---

## 📦 Distribution

### Share Buildable Source

Zip the entire project folder:

```bash
zip -r SpaceSaver-source.zip SpaceSaver/
```

### Build Release App

1. **Build Release** in Xcode: `Product → Archive`
2. **Distribute**: Click "Distribute App" → "Copy App"
3. **Save to**: `/Applications/`

### Notarize for Gatekeeper

```bash
# Create zip of the app
zip -r SpaceSaver.app.zip SpaceSaver.app

# Submit for notarization
xcrun notarytool submit SpaceSaver.app.zip \
  --apple-id YOUR_EMAIL@example.com \
  --team-id YOUR_TEAM_ID \
  --wait

# Staple the ticket to the app
xcrun stapler staple SpaceSaver.app
```

---

## 🛣️ Roadmap

Potential future enhancements:

- [ ] **Three-column layout** — Sidebar → List → Inspector panels
- [ ] **Quick Look integration** — Space bar preview for files
- [ ] **Menu bar icon** — Quick access from menu bar
- [ ] **Scheduled cleaning** — Automated cache cleanup
- [ ] **Duplicate image detection** — Visual similarity matching
- [ ] **Language localization** — Multi-language support

---

## 🙏 Credits

- Built with **SwiftUI** and **Swift**
- Icons using **SF Symbols**
- App icon designed in-house

---

## 📄 License

Free to use, modify, and share. No warranty — use at your own risk.

**Always review what you're deleting before confirming.** SpaceSaver moves files to Trash (not permanent deletion), but recovering from Trash still requires manual action.

---

<p align="center">
  Made with ❤️ for macOS users who need more disk space.
</p>
