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

firebase_auth_emulator_health="http://127.0.0.1:9099/emulator/v1/projects/social-example-dev/config"
if ! curl -fs --max-time 2 "$firebase_auth_emulator_health" >/dev/null 2>&1; then
  detach=(nohup)
  command -v setsid >/dev/null 2>&1 && detach=(setsid nohup)

  (cd frontend && exec "${detach[@]}" npx --yes firebase-tools emulators:start --only auth --project social-example-dev \
    >/tmp/firebase-auth-emulator.log 2>&1 </dev/null) &
  disown

  for _ in $(seq 1 15); do
    curl -fs --max-time 2 "$firebase_auth_emulator_health" >/dev/null 2>&1 && break
    sleep 1
  done
fi
