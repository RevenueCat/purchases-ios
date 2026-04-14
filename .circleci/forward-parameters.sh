#!/usr/bin/env bash
set -euo pipefail

# Derives boolean flags from the public "action" enum and writes them
# to the continuation parameters file. The "action" parameter itself is
# forwarded implicitly by CircleCI, so it is not included here.

ACTION="$1"
OUTPUT="$2"

GEN_SNAP=false
GEN_RCUI_SNAP=false
GEN_SWIFT=false

case "$ACTION" in
  generate_snapshots)            GEN_SNAP=true ;;
  generate_revenuecatui_snapshots) GEN_RCUI_SNAP=true ;;
  generate_swiftinterface)       GEN_SWIFT=true ;;
esac

cat > "$OUTPUT" << EOF
{
  "internal_generate_snapshots": $GEN_SNAP,
  "internal_generate_revenuecatui_snapshots": $GEN_RCUI_SNAP,
  "internal_generate_swiftinterface": $GEN_SWIFT
}
EOF
