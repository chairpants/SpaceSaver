# Changelog

All notable changes to SpaceSaver will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Future features go here

## [1.0.0] - 2026-06-21

### Added
- 🎉 Initial public release
- **Dashboard** — Visual disk overview with animated progress rings
- **Large Files Scanner** — Find files over 50MB/100MB/250MB/500MB/1GB
- **Duplicate Finder** — SHA-256 based duplicate detection
- **Cache Cleaner** — Clean Xcode, browser, and system caches
- **Trash Manager** — Visual gauge and one-click empty
- **Downloads Cleaner** — Filter old downloads by age and size
- **App Uninstaller** — Remove apps and leftover files
- **Login Items Manager** — Control startup items
- GitHub Actions workflow for automated releases

### Security
- All deletions move files to Trash (never permanent)
- No network calls, no telemetry, no data collection
- 100% local processing

[Unreleased]: https://github.com/yourusername/SpaceSaver/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/SpaceSaver/releases/tag/v1.0.0
