#!/bin/sh

#  Preprocessor.sh
#  PaywallsTester
#
#  Created by James Borthwick on 2024-05-08.
#

# Intended to be run via the scheme's post-actions build phase
#
# This script undoes the changes made by "Preprocessor.sh" so that they don't
# end up accidentally checked in.


echo "Starting undo process."

find_dir() {
  local dir="$1"
  local target_dir="$2"
  while [[ "$dir" != "/" ]]; do
    if [[ -e "$dir/$target_dir" ]]; then
      echo "$dir/$target_dir"
      return 0
    fi
    dir=$(dirname "$dir")  # go up one level
  done
  return 1  # Target directory not found
}

base_directory=$(find_dir "${PROJECT_DIR}" "RevenueCatUI")

if [[ -z "$base_directory" ]]; then
  echo "Error: RevenueCatUI not found in the current directory or any parent directory."
  exit 1
fi

echo "Starting at: $base_directory"

# debug log
log_file="undo_log.txt"
echo "Starting log at $(date)" > "$log_file"

# Find all .orig files and restore them
find "$base_directory" -type f -name "*.swift.orig" | while read -r backup_file; do
  original_file="${backup_file%.orig}"
  cp "$backup_file" "$original_file"
  rm -f "$backup_file"

  echo "Restored: $original_file" | tee -a "$log_file"
done

echo "Undo process completed." | tee -a "$log_file"
