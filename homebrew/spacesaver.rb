cask "spacesaver" do
  version "1.0.0"
  sha256 :no_check

  url "https://github.com/yourusername/SpaceSaver/releases/download/v#{version}/SpaceSaver.app.zip"
  name "SpaceSaver"
  desc "Free, open-source macOS disk cleaner"
  homepage "https://github.com/yourusername/SpaceSaver"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true

  app "SpaceSaver.app"

  zap trash: [
    "~/Library/Application Support/com.spacesaver.app",
    "~/Library/Caches/com.spacesaver.app",
    "~/Library/Preferences/com.spacesaver.app.plist",
    "~/Library/Saved Application State/com.spacesaver.app.savedState",
  ]

  caveats <<~EOS
    SpaceSaver requires Full Disk Access to scan system directories.

    On first launch, grant permission in:
      System Settings → Privacy & Security → Full Disk Access → Add SpaceSaver

    Without this permission, some scans will return incomplete results.
  EOS
end
