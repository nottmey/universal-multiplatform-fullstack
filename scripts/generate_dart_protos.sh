#!/usr/bin/env bash
# Generate Dart gRPC stubs from backend protos into frontend/lib/proto.
#
# Usage (from any cwd):
#   /path/to/repo/scripts/generate_dart_protos.sh
#
# Requires: protoc on PATH, dart on PATH, and protoc_plugin (installed automatically when missing).
set -euo pipefail

self=""
self=$(basename "$0")
readonly self

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
proto_import_dir="$root/backend/src/main/proto"
dart_out_dir="$root/frontend/lib/proto"
protoc_gen_dart="${HOME}/.pub-cache/bin/protoc-gen-dart"

require_command() {
  local name=$1
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "$self: $name not found on PATH" >&2
    exit 1
  fi
}

require_command protoc
require_command dart

if [[ ! -x "$protoc_gen_dart" ]]; then
  echo "$self: activating protoc_plugin (protoc-gen-dart missing)" >&2
  dart pub global activate protoc_plugin
fi

if [[ ! -x "$protoc_gen_dart" ]]; then
  echo "$self: protoc-gen-dart still missing at $protoc_gen_dart" >&2
  echo "$self: run: dart pub global activate protoc_plugin" >&2
  exit 1
fi

proto_files=()
while IFS= read -r path; do
  [[ -n "$path" ]] && proto_files+=("$path")
done < <(find "$proto_import_dir" -maxdepth 1 -name '*.proto' | sort)
if [[ ${#proto_files[@]} -eq 0 ]]; then
  echo "$self: no .proto files in $proto_import_dir" >&2
  exit 1
fi

mkdir -p "$dart_out_dir"

protoc_args=(
  "--plugin=protoc-gen-dart=${protoc_gen_dart}"
  "--dart_out=grpc:${dart_out_dir}"
  "-I" "$proto_import_dir"
)
protoc_args+=("${proto_files[@]}")

echo "$self: protoc -> $dart_out_dir (${#proto_files[@]} file(s))" >&2
protoc "${protoc_args[@]}"
