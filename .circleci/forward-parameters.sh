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
  "_action": "$ACTION",
  "_generate_snapshots": $GEN_SNAP,
  "_generate_revenuecatui_snapshots": $GEN_RCUI_SNAP,
  "_generate_swiftinterface": $GEN_SWIFT
}
EOF
