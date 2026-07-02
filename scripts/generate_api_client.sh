#!/usr/bin/env bash
# Regenerate the OpenAPI spec from backend annotations and the Dart client from the spec.
#
# Usage (from any cwd):
#   /path/to/repo/scripts/generate_api_client.sh
#
# Pipeline: backend @OpenApi annotations -> (javalin-openapi annotation processor, compile time)
#   -> spec/openapi.json -> (space_gen) -> client/ Dart package.
# Requires: a JDK for gradle, dart on PATH; space_gen comes from frontend dev_dependencies.
set -euo pipefail

self=$(basename "$0")
readonly self

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

echo "$self: exporting spec/openapi.json from backend annotations" >&2
(cd "$root/backend" && ./gradlew exportOpenApi --quiet)

echo "$self: generating client/ with space_gen" >&2
(cd "$root/frontend" && dart run space_gen -i "$root/spec/openapi.json" -o "$root/client")

(cd "$root/client" && dart pub get --no-example >/dev/null)
