#!/bin/bash
#
# Waits for a background runtime installation to complete, streaming the install log.
#
# Usage:
#   ./wait-for-runtime.sh [log-file] [ready-file] [failed-file] [max-wait]
#
# Example:
#   ./wait-for-runtime.sh /tmp/runtime_install.log /tmp/runtime_ready /tmp/runtime_failed 1800

set -euo pipefail

LOG="${1:-/tmp/runtime_install.log}"
READY_FILE="${2:-/tmp/runtime_ready}"
FAILED_FILE="${3:-/tmp/runtime_failed}"
MAX_WAIT="${4:-1800}"

LINES_SHOWN=0
ELAPSED=0

while [ ! -f "$READY_FILE" ] && [ ! -f "$FAILED_FILE" ]; do
  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
    echo "Timed out after ${MAX_WAIT}s waiting for runtime installation."
    exit 1
  fi
  NEW_LINES=$(tail -n +$((LINES_SHOWN + 1)) "$LOG" 2>/dev/null | wc -l)
  if [ "$NEW_LINES" -gt 0 ]; then
    tail -n +$((LINES_SHOWN + 1)) "$LOG" 2>/dev/null
    LINES_SHOWN=$((LINES_SHOWN + NEW_LINES))
  fi
  sleep 10
  ELAPSED=$((ELAPSED + 10))
done

# Print any remaining lines
tail -n +$((LINES_SHOWN + 1)) "$LOG" 2>/dev/null

if [ -f "$FAILED_FILE" ]; then
  exit 1
fi
