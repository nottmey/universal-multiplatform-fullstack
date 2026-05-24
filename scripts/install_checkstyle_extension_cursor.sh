#!/usr/bin/env bash
# Install Java Checkstyle extension in Cursor from upstream VSIX (not on Open VSX).
# Usage: ./scripts/install_checkstyle_extension_cursor.sh [vsix_url]
set -euo pipefail

readonly default_vsix_url="https://github.com/jdneo/vscode-checkstyle/releases/download/v1.4.2/vscode-checkstyle-1.4.2.vsix"
vsix_url="${1:-$default_vsix_url}"

tmp="$(mktemp "${TMPDIR:-/tmp}/vscode-checkstyle-XXXXXX.vsix")"
cleanup() {
  rm -f "$tmp"
}
trap cleanup EXIT

curl -fsSL -o "$tmp" "$vsix_url"
cursor --install-extension "$tmp"
echo "Installed Checkstyle extension from: $vsix_url"
