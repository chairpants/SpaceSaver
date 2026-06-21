# SpaceSaver - App Store Version

This is the **App Store-compliant** version of SpaceSaver with macOS App Sandbox enabled.

## ⚠️ Important: Sandbox Limitations

Due to macOS App Sandbox requirements for the Mac App Store, this version has some limitations compared to the full (non-sandboxed) version:

### What's Fully Functional

| Feature | Status | Notes |
|---------|--------|-------|
| Dashboard | ✅ Full | Disk usage overview works completely |
| Large Files Scanner | ✅ Full | Scans user-accessible locations |
| Duplicate Finder | ✅ Full | Finds duplicates in accessible folders |
| Downloads Cleaner | ✅ Full | Full access to ~/Downloads |
| Cache Cleaner | ⚠️ Limited | Can clean user caches in ~/Library/Caches |
| Trash Manager | ⚠️ Limited | Can open Trash in Finder; cannot directly empty |
| App Uninstaller | ⚠️ Limited | Can view apps; cannot directly uninstall |
| Login Items Manager | ✅ Full | Full functionality |

### Sandbox Restrictions

The App Sandbox (required for Mac App Store) restricts access to:

- **System Trash** (`~/.Trash`) - Can view size if accessible, but requires Full Disk Access for full functionality
- **System Applications** (`/Applications`) - Cannot scan without Full Disk Access
- **System Caches** - Limited to user-accessible caches only
- **Other User Libraries** - Requires user-granted access

### Workarounds

This App Store version includes UI messages that guide users when sandbox restrictions apply:

1. **Trash Management**: Opens Trash in Finder for manual emptying
2. **App Uninstallation**: Reveals apps in Finder for manual removal
3. **System Locations**: Prompts users to use Finder for system-level operations

## Building

### Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later
- A Mac Developer account (for code signing and App Store submission)

### Build Steps

1. Open `SpaceSaver.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run (⌘+R)

### App Store Submission

1. Ensure you have a valid Developer ID
2. Configure signing with your Apple Developer account
3. Archive the project (Product → Archive)
4. Submit to App Store Connect via Organizer

## Entitlements

This version uses the following entitlements (`SpaceSaver.entitlements`):

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
<key>com.apple.security.files.downloads.read-write</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
```

## Files Different from Full Version

The following files have been modified for App Store compliance:

- `SpaceSaver.entitlements` - Uses `.entitlements` format (required for App Store)
- `Utilities/SandboxHelper.swift` - New file for sandbox-aware operations
- `ViewModels/TrashViewModel.swift` - Handles sandbox restrictions gracefully
- `ViewModels/AppUninstallerViewModel.swift` - Limited to user-accessible apps
- `Utilities/CacheLocator.swift` - Uses security-scoped resource access

## Full Disk Access

Users can optionally grant Full Disk Access in System Settings → Privacy & Security → Full Disk Access for enhanced functionality. However, this is **not required** - the app gracefully degrades when access is not available.

## Support

For issues specific to the App Store version, please mention "App Store" in your bug report.
