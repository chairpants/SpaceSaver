# SpaceSaver

<p align="center">
  <img src="SpaceSaver/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" width="128" alt="SpaceSaver App Icon">
</p>

<p align="center">
  <strong>Reclaim disk space on your Mac — free, open-source, no BS.</strong><br>
  No subscriptions, no paywalls, no data collection. Just a clean Mac.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13+-blue?logo=apple" alt="macOS 13+">
  <img src="https://img.shields.io/badge/Swift-SwiftUI-orange?logo=swift" alt="SwiftUI">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License">
  <img src="https://img.shields.io/badge/downloads-github%20releases-blue" alt="Download from Releases">
</p>

<p align="center">
  <a href="#-download"><strong>Download</strong></a> •
  <a href="#-features"><strong>Features</strong></a> •
  <a href="#-screenshots"><strong>Screenshots</strong></a> •
  <a href="#-building-from-source"><strong>Build</strong></a>
</p>

---

## 🚀 Download

**Latest Release:** [SpaceSaver v1.0.0](https://github.com/yourusername/SpaceSaver/releases/latest)

| Version | Download | Requirements |
|---------|----------|--------------|
| Latest | [SpaceSaver.app.zip](https://github.com/yourusername/SpaceSaver/releases/latest/download/SpaceSaver.app.zip) | macOS 13+ |

**Installation:**
1. Download `SpaceSaver.app.zip` from the [Releases page](../../releases)
2. Unzip and drag `SpaceSaver.app` to your **Applications** folder
3. **Grant Full Disk Access** (System Settings → Privacy & Security → Full Disk Access → Add SpaceSaver)
4. Launch and start cleaning!

> ⚠️ **Note:** Full Disk Access is required to scan `~/Library`, system caches, and other protected locations.

---

## ✨ Features

### 📊 Dashboard
Visual overview of your disk with animated progress rings, storage breakdown by category, and quick-action shortcuts.

### 📁 Large Files Scanner
Find massive files eating your space. Filter by size (50MB to 1GB+), sort by name/size/date, and delete with one click.

### 📋 Duplicate Finder
Content-based duplicate detection using SHA-256 hashing. Groups duplicates, shows wasted space, and lets you clean selectively.

### 🧹 Cache Cleaner
One-click cleaning for:
- Xcode Derived Data (often GBs!)
- Browser caches (Safari, Chrome, Firefox)
- System and user caches
- Application support files

### 🗑️ Trash Manager
Visual gauge of your Trash size with one-click empty.

### 📥 Downloads Cleaner
Smart filters by age (30/60/90/180/365 days) or file size. Find those ancient downloads you forgot about.

### 📦 App Uninstaller
Remove apps **and** their leftover files scattered across Library folders.

### 🔐 Login Items Manager
View and control what launches at startup — LaunchAgents and Login Items.

---

## 📸 Screenshots

<p align="center">
  <em>Beautiful dark mode interface with native macOS design</em>
</p>

*(Screenshots coming soon — DM me if you take nice ones!)*

---

## 🛠️ Building from Source

Want to hack on it? Build it yourself:

### Requirements
- macOS 13.0+ (Ventura)
- Xcode 15+ (built with Xcode 26)

### Clone & Build

```bash
# Clone the repo
git clone https://github.com/yourusername/SpaceSaver.git
cd SpaceSaver

# Open in Xcode
open SpaceSaver.xcodeproj

# Or build from command line
xcodebuild -project SpaceSaver.xcodeproj -scheme SpaceSaver -configuration Release build
```

### Regenerate Project

If the `.xcodeproj` gets out of sync:

```bash
python3 generate_project.py
```

---

## 🏗️ Architecture

- **SwiftUI** — Native macOS interface
- **MVVM Pattern** — Clean separation of concerns
- **Background Processing** — File scanning on detached threads, UI stays responsive
- **Safety First** — All deletions move to Trash (never permanent)
- **Non-Sandboxed** — Full filesystem access (why it's not on App Store)

---

## 🔒 Permissions

**Full Disk Access** is needed for scanning protected directories:

1. System Settings → Privacy & Security → Full Disk Access
2. Click **+** and add **SpaceSaver.app**
3. Restart the app

Without this, scans of `~/Library` and system directories will be incomplete.

---

## 🛣️ Roadmap

- [ ] **Sunburst visualization** — DaisyDisk-style disk map
- [ ] **Menu bar integration** — Quick access from menu bar
- [ ] **Scheduled cleaning** — Automated cache cleanup
- [ ] **Duplicate image detection** — Visual similarity (not just hashes)
- [ ] **Quick Look** — Space bar preview for files

Got ideas? [Open an issue](../../issues)!

---

## 🤖 Built With AI

This project was created with the help of:

- **Claude Code** (Anthropic) — Primary development, architecture, and implementation
- **GLM-5.2** (Zhipu AI / Ollama) — Code review and optimization suggestions
- **Kimi-k2.5** (Moonshot AI) — Additional development assistance and debugging

A testament to what's possible when human direction meets AI capability. The entire app — from concept to working codebase — was built through collaborative AI-human pair programming.

---

## 📄 License

MIT License — Free to use, modify, and distribute. See [LICENSE](LICENSE) for details.

**Use at your own risk.** SpaceSaver moves files to Trash (recoverable), but always review before confirming deletions.

---

## 🏷️ Tags

`macos` `disk-cleanup` `storage-manager` `swift` `swiftui` `open-source` `free` `xcode` `cache-cleaner` `duplicate-finder` `large-files` `trash-manager` `app-uninstaller` `system-tools` `disk-space` `file-management` `macos-app` `native-macos`

---

<p align="center">
  Made with ❤️ (and AI) for Mac users running low on space.
</p>

<p align="center">
  <a href="https://github.com/yourusername/SpaceSaver/stargazers">⭐ Star this repo</a> if it helped you clean up your Mac!
</p>
