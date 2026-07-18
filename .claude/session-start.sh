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

# Firebase Auth emulator backs MainTest.bootstrap_devScenarioSmoke() and local `runBackend`.
# Idempotent: skip if a previous session already left it running in this container.
firebase_auth_emulator_health="http://127.0.0.1:9099/emulator/v1/projects/social-example-dev/config"
if ! curl -fs "$firebase_auth_emulator_health" >/dev/null 2>&1; then
  (cd frontend && nohup npx --yes firebase-tools emulators:start --only auth --project social-example-dev \
    >/tmp/firebase-auth-emulator.log 2>&1 &)

  for _ in $(seq 1 15); do
    if curl -fs "$firebase_auth_emulator_health" >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done
fi
