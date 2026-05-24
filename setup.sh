#!/usr/bin/env bash
# easy repo setup, idempotent
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if ! command -v npx >/dev/null 2>&1; then
  echo "npx is not on PATH — install Node.js (e.g. via nvm) for commit-msg hooks" >&2
  exit 1
fi

if ! command -v asdf >/dev/null 2>&1; then
  echo "asdf is not on PATH — install from https://asdf-vm.com/guide/getting-started.html" >&2
  exit 1
fi

if ! asdf plugin list | grep -qx gitleaks; then
  echo "Adding asdf plugin: gitleaks"
  asdf plugin add gitleaks https://github.com/jmcvetta/asdf-gitleaks.git
fi

if ! asdf plugin list | grep -qx lefthook; then
  echo "Adding asdf plugin: lefthook"
  asdf plugin add lefthook https://github.com/jtzero/asdf-lefthook.git
fi

cd "$root"

asdf install

lefthook install

