#!/bin/bash
#
# Installs a simulator runtime with timeout detection and retry logic.
# Designed to run in the background while other CI steps proceed.
#
# Uses sudo bash -c to capture the actual child PID (not the sudo wrapper),
# since sudo on CI exits immediately while the child runs as root.
#
# Usage:
#   ./install-ios-runtime.sh <runtime-name> [log-file] [ready-file] [failed-file]
#
# Example:
#   ./install-ios-runtime.sh "iOS 14.5" /tmp/runtime_install.log /tmp/runtime_ready /tmp/runtime_failed

set -uo pipefail

RUNTIME="${1:?Usage: $0 <runtime-name> [log-file] [ready-file] [failed-file]}"
LOG="${2:-/tmp/runtime_install.log}"
READY_FILE="${3:-/tmp/runtime_ready}"
FAILED_FILE="${4:-/tmp/runtime_failed}"
CHILD_PID_FILE="/tmp/runtime_child_pid"

MAX_RETRIES=3
INSTALL_TIMEOUT=180

echo "=== Available runtimes ===" > "$LOG"
xcodes runtimes >> "$LOG" 2>&1

ATTEMPT=1
while [ "$ATTEMPT" -le "$MAX_RETRIES" ]; do
  echo "=== Installing $RUNTIME (attempt $ATTEMPT/$MAX_RETRIES) ===" >> "$LOG"

  # Clean up root-owned PID file from previous attempt
  sudo rm -f "$CHILD_PID_FILE"

  # Launch via sudo bash -c to capture the actual child PID.
  # The sudo wrapper exits immediately on CI, so $! is unreliable.
  # Use positional args to avoid fragile quote-splicing.
  sudo bash -c 'echo $$ > "$1"; shift; exec "$@"' -- \
    "$CHILD_PID_FILE" xcodes runtimes install "$RUNTIME" >> "$LOG" 2>&1 &
  SUDO_PID=$!

  # Wait for the child PID file to be written
  for i in $(seq 1 10); do
    [ -f "$CHILD_PID_FILE" ] && break
    sleep 0.5
  done

  if [ -f "$CHILD_PID_FILE" ]; then
    CHILD_PID=$(cat "$CHILD_PID_FILE")
  else
    CHILD_PID=""
  fi

  # Monitor the actual child process, not the sudo wrapper
  MONITOR_PID="${CHILD_PID:-$SUDO_PID}"
  ELAPSED=0
  TIMED_OUT=false

  while sudo kill -0 "$MONITOR_PID" 2>/dev/null; do
    if [ "$ELAPSED" -ge "$INSTALL_TIMEOUT" ]; then
      echo "Install hung after ${INSTALL_TIMEOUT}s — killing process tree (attempt $ATTEMPT)" >> "$LOG"
      # Kill the entire process tree: find all descendants and kill them
      DESCENDANTS=$(ps -eo pid,ppid | awk -v root="$MONITOR_PID" '
        BEGIN { pids[root]=1 }
        { parent[$1]=$2 }
        END {
          changed=1
          while(changed) {
            changed=0
            for(p in parent) {
              if((parent[p] in pids) && !(p in pids)) {
                pids[p]=1
                changed=1
              }
            }
          }
          for(p in pids) print p
        }
      ')
      for PID_TO_KILL in $DESCENDANTS; do
        sudo kill -9 "$PID_TO_KILL" 2>/dev/null || true
      done
      TIMED_OUT=true
      break
    fi
    sleep 10
    ELAPSED=$((ELAPSED + 10))
  done

  # Reap the sudo wrapper.
  # Note: the sudo wrapper's exit code is unreliable since sudo exits
  # immediately on CI while the child continues. Instead, verify the
  # runtime was actually installed.
  wait "$SUDO_PID" 2>/dev/null

  if [ "$TIMED_OUT" = false ]; then
    # The child exited on its own — verify the runtime is now available.
    # Convert "iOS 14.5" to the format simctl uses (e.g., "iOS 14.5").
    if xcrun simctl list runtimes 2>/dev/null | grep -q "$RUNTIME"; then
      echo "Runtime $RUNTIME installed successfully" >> "$LOG"
      touch "$READY_FILE"
      exit 0
    fi
    echo "Child exited but runtime not found — treating as failure" >> "$LOG"
  fi

  echo "Attempt $ATTEMPT failed (timed_out=$TIMED_OUT)" >> "$LOG"
  ATTEMPT=$((ATTEMPT + 1))
  [ "$ATTEMPT" -le "$MAX_RETRIES" ] && sleep 10
done

echo "Failed to install $RUNTIME after $MAX_RETRIES attempts" >> "$LOG"
touch "$FAILED_FILE"
exit 1
