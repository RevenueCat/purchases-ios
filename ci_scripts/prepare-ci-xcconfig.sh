#!/usr/bin/env bash
set -euo pipefail

# Output XCConfig file path (change if you like)
output_file="CI.xcconfig"

# Start fresh
: > "$output_file"

# Header
{
  echo "// Auto-generated. Do not commit to VCS if it contains secrets."
  echo "// Generated on $(date)"
  echo
} >> "$output_file"

# Collect names for summary
vars=()

# Get exported env var names that start with REVENUECAT_, sorted for determinism
while IFS= read -r name; do
  # Skip empty just in case
  [[ -z "$name" ]] && continue

  # Pull the value from the current environment
  value="${!name-}"

  # Remove quotes entirely (no escaping needed)
  # But trim trailing newlines just in case
  value_clean="$(echo -n "$value")"

  # Write: NAME = value
  echo "${name} = ${value_clean}" >> "$output_file"

  vars+=("$name")
done < <(env | grep -E '^REVENUECAT_[A-Z0-9_]*=' | cut -d= -f1 | sort -u)

# Summary (names only)
echo "✅ Wrote ${#vars[@]} variables to $output_file:"
for v in "${vars[@]}"; do
  echo "  - $v"
done