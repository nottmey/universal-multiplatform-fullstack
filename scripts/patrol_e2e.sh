#!/usr/bin/env bash
# Patrol (Flutter / web) against local backend on 8080 and Auth emulator on 9099.
#
# Usage: patrol_e2e.sh web|web-headless|<patrol --device value> [--verbose|-v] [-- extra patrol args...]
set -euo pipefail

readonly auth_emulator_port=9099
readonly grpc_port=8080

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

tcp_port_open() {
  python3 -c "import socket; s=socket.socket(); s.settimeout(0.5); s.connect(('127.0.0.1', $1)); s.close()" 2>/dev/null
}

if ! tcp_port_open "$auth_emulator_port"; then
  echo "$self: auth emulator not listening on 127.0.0.1:${auth_emulator_port}" >&2
  echo "Start the Auth emulator first (from frontend/):" >&2
  echo "  firebase emulators:start --only auth" >&2
  exit 1
fi

[[ "$verbose" == true ]] && echo "$self: auth_emulator_port=$auth_emulator_port grpc_port=$grpc_port" >&2

wait_for_tcp_port() {
  local port=$1
  local attempt
  for attempt in $(seq 1 180); do
    if tcp_port_open "$port"; then
      return 0
    fi
    sleep 1
  done
  echo "$self: timed out waiting for 127.0.0.1:${port}" >&2
  return 1
}

back_pid=""
cleanup() {
  if [[ -n "$back_pid" ]]; then
    [[ "$verbose" == true ]] && echo "$self: stopping backend pid=$back_pid" >&2
    pkill -P "$back_pid" 2>/dev/null || true
    kill "$back_pid" 2>/dev/null || true
    wait "$back_pid" 2>/dev/null || true
    back_pid=""
  fi
}
trap cleanup EXIT

case "$device" in
  web) patrol_device=(--device chrome) ;;
  web-headless) patrol_device=(--device chrome --web-headless true) ;;
  *) patrol_device=(--device "$device") ;;
esac

[[ "$verbose" == true ]] && patrol_device+=(--show-flutter-logs --verbose)

patrol_dart_defines=(
  --dart-define=AUTH_EMULATOR_PORT="${auth_emulator_port}"
  --dart-define=GRPC_PORT="${grpc_port}"
)

patrol_common=(
  "${patrol_device[@]}"
  "${patrol_dart_defines[@]}"
  --target patrol_test/smoke_test.dart
)

gradle_args=(--console=plain)
[[ -n "${CI:-}" ]] && gradle_args+=(--no-daemon)
if [[ "$verbose" == true ]]; then
  gradle_args+=(--info)
  echo "$self: (cd backend && ./gradlew ${gradle_args[*]} runBackend)" >&2
else
  gradle_args+=(--quiet)
fi

(
  cd "$root/backend"
  ./gradlew "${gradle_args[@]}" runBackend
) &
back_pid=$!

# TODO: don't wait for port to be open, let the frontend start and re-try the connect
wait_for_tcp_port "$grpc_port"

cd "$root/frontend"

patrol_invocation=("$patrol_bin")
[[ "$verbose" == true ]] && patrol_invocation+=(--verbose)
patrol_invocation+=(test "${patrol_common[@]}" "$@")

set +e
CI=true "${patrol_invocation[@]}" &
patrol_pid=$!
set -e

set +e
wait "$patrol_pid"
patrol_status=$?
set -e

if ! kill -0 "$back_pid" 2>/dev/null; then
  echo "$self: backend exited early (patrol exit=$patrol_status)" >&2
fi
exit "$patrol_status"
