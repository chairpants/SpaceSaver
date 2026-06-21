# SpaceSaver

A free, open-source macOS app to help you reclaim disk space. No subscriptions, no paywalls — just clean disk space.

Built with SwiftUI for macOS 13+ (Ventura and later).

## Features

- **Dashboard** — Visual overview of disk usage with a progress ring and category breakdown chart
- **Large Files Scanner** — Find files over a size threshold (50 MB – 1 GB), sorted by size
- **Duplicate Finder** — Detects duplicate files by size + SHA-256 content hash
- **Cache Cleaner** — One-click clean for Xcode, Safari, Chrome, Firefox, and system caches
- **Trash Manager** — View Trash size and empty it
- **Downloads Cleaner** — Find old/large downloads with age and size filters
- **App Uninstaller** — Remove apps and their leftover support files
- **Login Items Manager** — Toggle launch agents and login items

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15+ to build (developed with Xcode 26)
- **Full Disk Access** recommended (System Settings → Privacy & Security → Full Disk Access) so the app can scan protected directories like `~/Library`

## Building

### Option A: Open in Xcode (recommended)
1. Open `SpaceSaver.xcodeproj` in Xcode
2. Press `⌘R` to build and run

### Option B: Regenerate the project from source
If the `.xcodeproj` gets out of sync with the source files, regenerate it:
```sh
python3 generate_project.py
```
Then open the freshly generated `SpaceSaver.xcodeproj`.

### Option C: Build from the command line
```sh
xcodebuild -project SpaceSaver.xcodeproj -scheme SpaceSaver -configuration Debug build
```

## Project Structure

```
SpaceSaver/
├── SpaceSaver.xcodeproj        # Xcode project (generated)
├── generate_project.py         # Regenerates the .xcodeproj from source list
├── README.md
└── SpaceSaver/                 # App source
    ├── SpaceSaverApp.swift     # App entry point
    ├── ContentView.swift       # Sidebar navigation
    ├── Info.plist
    ├── Entitlements.plist
    ├── Assets.xcassets
    ├── Models/                 # Data models (DiskInfo, ScanResult, CacheCategory)
    ├── ViewModels/             # Business logic per feature
    ├── Views/                  # SwiftUI screens
    │   └── Components/         # Reusable UI (FileSizeFormatter, dialogs)
    └── Utilities/              # FileScanner, DiskUsage, CacheLocator
```

## Architecture

- **MVVM**: Each feature has a View + ViewModel pair. ViewModels are `ObservableObject` classes with `@Published` properties.
- **Background I/O**: All file scanning runs on background threads via `Task.detached` / `async`-await, keeping the UI responsive.
- **Safety first**: All deletions move files to Trash (never permanent delete). Bulk operations require confirmation.
- **Not sandboxed**: The app runs outside the App Sandbox so it can access the full filesystem. This means it can't be distributed via the Mac App Store, but it can be shared directly (notarize it for Gatekeeper).

## Distribution

To share a buildable copy: zip the whole folder. To share a runnable app:

1. Build a Release version in Xcode (`Product → Archive` or `xcodebuild -configuration Release`)
2. Notarize the app for Gatekeeper:
   ```sh
   xcrun notarytool submit SpaceSaver.app.zip --apple-id YOU@EMAIL.com --team-id TEAMID --wait
   xcrun stapler staple SpaceSaver.app
   ```

## License

Free to use, modify, and share. No warranty — use at your own risk. Always review what you're deleting before confirming.