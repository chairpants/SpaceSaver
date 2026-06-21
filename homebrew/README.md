# SpaceSaver Homebrew Tap

Official Homebrew Cask for SpaceSaver - the free, open-source macOS disk cleaner.

## Installation

```bash
# Add this tap
brew tap yourusername/spacesaver

# Install SpaceSaver
brew install --cask spacesaver
```

## Upgrade

```bash
brew upgrade --cask spacesaver
```

## Uninstall

```bash
brew uninstall --cask spacesaver
brew untap yourusername/spacesaver
```

## For the Maintainers

### Setting up the tap

1. Create a new repository called `homebrew-spacesaver` on GitHub
2. Copy `spacesaver.rb` to that repo
3. Update the `sha256` in the formula after each release

### Calculating SHA256

After publishing a release, get the SHA256:

```bash
# Download the release
curl -L -o SpaceSaver.app.zip https://github.com/yourusername/SpaceSaver/releases/download/v1.0.0/SpaceSaver.app.zip

# Calculate SHA256
shasum -a 256 SpaceSaver.app.zip
```

Then update the formula with the new SHA256.

### Auto-updates

The `auto_updates true` flag tells Homebrew not to interfere with Sparkle/auto-updaters if you add one later.
