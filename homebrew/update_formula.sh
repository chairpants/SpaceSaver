#!/bin/bash
# Update the Homebrew formula with new version and SHA256
# Usage: ./update_formula.sh VERSION

set -e

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "Usage: ./update_formula.sh 1.0.0"
    exit 1
fi

# Download the release
echo "Downloading SpaceSaver v${VERSION}..."
curl -L -o SpaceSaver.app.zip "https://github.com/yourusername/SpaceSaver/releases/download/v${VERSION}/SpaceSaver.app.zip"

# Calculate SHA256
echo "Calculating SHA256..."
SHA256=$(shasum -a 256 SpaceSaver.app.zip | awk '{print $1}')

# Update the formula
echo "Updating formula..."
sed -i '' "s/version .*/version \"${VERSION}\"/" spacesaver.rb
sed -i '' "s/sha256 .*/sha256 \"${SHA256}\"/" spacesaver.rb

# Cleanup
rm SpaceSaver.app.zip

echo "✅ Formula updated for v${VERSION}"
echo "SHA256: ${SHA256}"
echo ""
echo "Next steps:"
echo "1. Commit the changes"
echo "2. Push to your homebrew-spacesaver repo"
echo "3. Users can now: brew upgrade --cask spacesaver"
