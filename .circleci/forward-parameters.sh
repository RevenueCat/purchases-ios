#!/usr/bin/env bash
set -euo pipefail

ACTION="$1"
OUTPUT="$2"

GEN_SNAP=false
GEN_RCUI_SNAP=false
GEN_SWIFT=false

case "$ACTION" in
  generate_snapshots)
    GEN_SNAP=true
    ACTION=default
    ;;
  generate_revenuecatui_snapshots)
    GEN_RCUI_SNAP=true
    ACTION=default
    ;;
  generate_swiftinterface)
    GEN_SWIFT=true
    ACTION=default
    ;;
esac

cat > "$OUTPUT" << EOF
{
  "internal_action": "$ACTION",
  "internal_generate_snapshots": $GEN_SNAP,
  "internal_generate_revenuecatui_snapshots": $GEN_RCUI_SNAP,
  "internal_generate_swiftinterface": $GEN_SWIFT
}
EOF
