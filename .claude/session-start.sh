#!/bin/bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1 && [ -x /root/flutter/bin/flutter ]; then
  export PATH="/root/flutter/bin:$PATH"
  if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
    echo 'export PATH="/root/flutter/bin:$PATH"' >> "$CLAUDE_ENV_FILE"
  fi
fi

(cd frontend && flutter pub get)
(cd backend && ./gradlew classes --console=plain)
