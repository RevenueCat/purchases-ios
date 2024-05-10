#!/bin/sh

#  Preprocessor.sh
#  PaywallsTester
#
#  Created by James Borthwick on 2024-05-08.
#

# Intended to be run via the scheme's pre-actions build phase
#
# This script searches up from ${PROJECT_DIR} to locate the RevenueCatUI directory.
# Once found, it searches through all `.swift` files starting from that base directory.
# It finds occurrences of `//@PublicForExternalTesting` and modifies the subsequent class, struct,
# func, init, and enum declaration to make it public.

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

echo "Starting script to make items annotated with \`\/\/ @PublicForExternalTesting\` public."

base_directory=$(find_dir "${PROJECT_DIR}" "RevenueCatUI")

if [[ -z "$base_directory" ]]; then
  echo "Error: RevenueCatUI not found in the current directory or any parent directory."
  exit 1
fi

echo "Starting at: $base_directory"

# debug log
log_file="preprocess_log.txt"
echo "Starting log at $(date)" > "$log_file"

# Find all .swift files recursively from the base directory
find "$base_directory" -type f -name "*.swift" | while read -r file; do

    if grep -q '// @PublicForExternalTesting' "$file"; then
        # Backup original file
        backup_file="${file}.orig"
        cp "$file" "$original_file"

        # Find //@PublicForExternalTesting and replace it with public before declarations
        sed -i.orig -E \
        '/\/\/ @PublicForExternalTesting[[:space:]]*$/{
        N
        s/\/\/ @PublicForExternalTesting[[:space:]]*\n[[:space:]]*(static[[:space:]]+)?(struct|class|final[[:space:]]+class|enum|init|convenience[[:space:]]+init|func|var|let|typealias)/public \1\2/
        }' "$file"

        # Log changes made to the file
        diff_output=$(diff "$backup_file" "$file")
        if [[ -n "$diff_output" ]]; then
            echo "Changes made in file: $file" | tee -a "$log_file"
            echo "$diff_output" | tee -a "$log_file"
        fi

    fi
done

echo "Processing completed." | tee -a "$log_file"
