#!/usr/bin/env bash
# Patrol (Flutter / web tooling) and backend Gradle run in parallel until tests finish.
# EXIT trap tears down the backend when Patrol finishes.
#
# Usage: patrol_e2e.sh web|web-headless|<patrol --device value> [--verbose|-v] [-- extra patrol args...]
#   web / web-headless — Chrome headed vs headless.
#   other first arg — patrol test --device <value> (simulator, emulator id, etc.).
#   --verbose / -v — more Gradle, Patrol, and Flutter logs.
#
# Speed: skip --verbose unless debugging. With CI unset, Gradle keeps its daemon.
set -euo pipefail

self=""
self=$(basename "$0")
readonly self
verbose=false

if [[ $# -lt 1 ]]; then
  echo "usage: $self web|web-headless|<patrol --device value> [--verbose|-v] [-- extra patrol test args...]" >&2
  exit 1
fi

device=$1
shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --verbose | -v) verbose=true; shift ;;
    --) break ;;
    *) break ;;
  esac
done

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
patrol_bin="${HOME}/.pub-cache/bin/patrol"

require_command() {
  local name=$1
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "$self: $name not found on PATH" >&2
    exit 1
  fi
}

require_patrol() {
  if [[ ! -x "$patrol_bin" ]]; then
    echo "$self: activating patrol_cli (patrol CLI missing)" >&2
    dart pub global activate patrol_cli
  fi
  if [[ ! -x "$patrol_bin" ]]; then
    echo "$self: patrol still missing at $patrol_bin after activate" >&2
    echo "$self: run: dart pub global activate patrol_cli" >&2
    exit 1
  fi
}

require_command dart
require_patrol

[[ "$verbose" == true ]] && echo "$self: verbose cwd=$root device=$device" >&2

back_pid=""
cleanup() {
  [[ -z "$back_pid" ]] && return
  [[ "$verbose" == true ]] && echo "$self: stopping backend pid=$back_pid" >&2
  pkill -P "$back_pid" 2>/dev/null || true
  kill "$back_pid" 2>/dev/null || true
  wait "$back_pid" 2>/dev/null || true
}
trap cleanup EXIT

case "$device" in
  web) patrol_device=(--device chrome) ;;
  web-headless) patrol_device=(--device chrome --web-headless true) ;;
  *) patrol_device=(--device "$device") ;;
esac

[[ "$verbose" == true ]] && patrol_device+=(--show-flutter-logs --verbose)

patrol_common=(
  "${patrol_device[@]}"
  --target patrol_test/smoke_test.dart
)

cd "$root/frontend"

patrol_invocation=("$patrol_bin")
[[ "$verbose" == true ]] && patrol_invocation+=(--verbose)
patrol_invocation+=(test "${patrol_common[@]}" "$@")

set +e
CI=true "${patrol_invocation[@]}" &
patrol_pid=$!
set -e

gradle_args=(--console=plain)
[[ -n "${CI:-}" ]] && gradle_args+=(--no-daemon)
if [[ "$verbose" == true ]]; then
  gradle_args+=(--info)
  echo "$self: (cd backend && ./gradlew ${gradle_args[*]} runBackend) (parallel patrol pid=$patrol_pid)" >&2
else
  gradle_args+=(--quiet)
fi

(cd "$root/backend" && ./gradlew "${gradle_args[@]}" runBackend) &
back_pid=$!

set +e
wait "$patrol_pid"
patrol_status=$?
set -e

if ! kill -0 "$back_pid" 2>/dev/null; then
  echo "$self: backend exited early (patrol exit=$patrol_status)" >&2
fi
exit "$patrol_status"
