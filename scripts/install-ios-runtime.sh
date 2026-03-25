#!/bin/bash
#
# Installs a simulator runtime with timeout detection and retry logic.
# Designed to run in the background while other CI steps proceed.
#
# Usage:
#   ./install-runtime.sh <runtime-name> [log-file] [ready-file] [failed-file]
#
# Example:
#   ./install-runtime.sh "iOS 14.5" /tmp/runtime_install.log /tmp/runtime_ready /tmp/runtime_failed

set -euo pipefail

RUNTIME="${1:?Usage: $0 <runtime-name> [log-file] [ready-file] [failed-file]}"
LOG="${2:-/tmp/runtime_install.log}"
READY_FILE="${3:-/tmp/runtime_ready}"
FAILED_FILE="${4:-/tmp/runtime_failed}"

MAX_RETRIES=3
INSTALL_TIMEOUT=180

echo "=== Available runtimes ===" > "$LOG"
xcodes runtimes >> "$LOG" 2>&1

ATTEMPT=1
while [ "$ATTEMPT" -le "$MAX_RETRIES" ]; do
  echo "=== Installing $RUNTIME (attempt $ATTEMPT/$MAX_RETRIES) ===" >> "$LOG"

  sudo xcodes runtimes install "$RUNTIME" >> "$LOG" 2>&1 &
  INSTALL_PID=$!
  ELAPSED=0

  while kill -0 "$INSTALL_PID" 2>/dev/null; do
    if [ "$ELAPSED" -ge "$INSTALL_TIMEOUT" ]; then
      echo "Install hung after ${INSTALL_TIMEOUT}s — killing process (attempt $ATTEMPT)" >> "$LOG"
      sudo kill -9 "$INSTALL_PID" 2>/dev/null
      wait "$INSTALL_PID" 2>/dev/null
      break
    fi
    sleep 10
    ELAPSED=$((ELAPSED + 10))
  done

  if wait "$INSTALL_PID" 2>/dev/null; then
    echo "Runtime $RUNTIME installed successfully" >> "$LOG"
    touch "$READY_FILE"
    exit 0
  fi

  echo "Attempt $ATTEMPT failed" >> "$LOG"
  ATTEMPT=$((ATTEMPT + 1))
  [ "$ATTEMPT" -le "$MAX_RETRIES" ] && sleep 10
done

echo "Failed to install $RUNTIME after $MAX_RETRIES attempts" >> "$LOG"
touch "$FAILED_FILE"
exit 1
