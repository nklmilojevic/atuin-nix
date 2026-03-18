#!/usr/bin/env bash

set -euo pipefail

PACKAGE_FILE="package.nix"

TRIPLES=(
  "aarch64-apple-darwin"
  "x86_64-unknown-linux-musl"
  "aarch64-unknown-linux-musl"
)

usage() {
    echo "Usage: $0 [--check | <version>]"
    echo ""
    echo "Options:"
    echo "  --check     Check if a new version is available"
    echo "  <version>   Update to a specific version (e.g., 18.13.3)"
    echo ""
    echo "Examples:"
    echo "  $0 --check"
    echo "  $0 18.13.3"
    exit 1
}

get_current_version() {
    grep 'version = ' "$PACKAGE_FILE" | head -1 | cut -d'"' -f2
}

get_latest_version() {
    curl -s https://api.github.com/repos/atuinsh/atuin/releases/latest | \
        sed -n 's/.*"tag_name": "v\([^"]*\)".*/\1/p'
}

if [ $# -eq 0 ]; then
    usage
fi

if [ "$1" = "--check" ]; then
    CURRENT_VERSION=$(get_current_version)
    LATEST_VERSION=$(get_latest_version)

    echo "Current version: $CURRENT_VERSION"
    echo "Latest version:  $LATEST_VERSION"

    if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
        echo "Already up to date!"
        exit 0
    else
        echo "New version available: $LATEST_VERSION"
        echo "Run './scripts/update.sh $LATEST_VERSION' to update"
        exit 1
    fi
fi

VERSION="$1"

echo "Updating to Atuin version $VERSION..."

# Fetch platform-specific package hashes
declare -A TRIPLE_HASHES
for triple in "${TRIPLES[@]}"; do
    echo "Fetching hash for $triple..."
    URL="https://github.com/atuinsh/atuin/releases/download/v${VERSION}/atuin-${triple}.tar.gz"
    HASH=$(nix-prefetch-url "$URL" 2>/dev/null || echo "")

    if [ -z "$HASH" ]; then
        echo "Error: Could not fetch hash for $triple"
        exit 1
    fi

    TRIPLE_HASHES[$triple]="$HASH"
    echo "  $triple: $HASH"
done

echo "Updating $PACKAGE_FILE..."

# Update version
sed -i.bak "s/version = \".*\"/version = \"$VERSION\"/" "$PACKAGE_FILE"

# Update platform-specific hashes
for triple in "${TRIPLES[@]}"; do
    HASH="${TRIPLE_HASHES[$triple]}"
    awk -v triple="$triple" -v hash="$HASH" '
        $0 ~ "atuin-" triple "\\.tar\\.gz" { found=1 }
        found && /sha256 = / { sub(/sha256 = ".*"/, "sha256 = \"" hash "\""); found=0 }
        { print }
    ' "$PACKAGE_FILE" > "${PACKAGE_FILE}.tmp" && mv "${PACKAGE_FILE}.tmp" "$PACKAGE_FILE"
done

rm -f "${PACKAGE_FILE}.bak"

echo "Testing build..."
if nix build --no-link; then
    echo "Build successful!"
    echo ""
    echo "Version $VERSION has been successfully updated."
    echo "Don't forget to:"
    echo "  1. Test the new version: nix run . -- --version"
    echo "  2. Commit your changes"
    echo "  3. Push to GitHub"
else
    echo "Build failed. Please check the error messages above."
    exit 1
fi
