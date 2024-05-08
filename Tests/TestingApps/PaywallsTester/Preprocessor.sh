#!/bin/sh

#  Preprocessor.sh
#  PaywallsTester
#
#  Created by James Borthwick on 2024-05-08.
#

# This script searches up from ${PROJECT_DIR} to locate the RevenueCat.xcworkspace directory.
# Once found, it searches through all `.swift` files starting from that base directory.
# It finds occurances of `//@PublicForExternalTesting` and modifies the subsequent class, struct,
# func, init and enum declaration to make it public.

# directory containing RevenueCat.xcworkspace
find_xcworkspace_dir() {
  local dir="$1"
  while [[ "$dir" != "/" ]]; do
    if [[ -e "$dir/RevenueCat.xcworkspace" ]]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")  # go up one level
  done
  return 1  # RevenueCat.xcworkspace not found :'(
}

echo "Starting script to make items annotated with \`\\\\@PublicForExternalTesting\` public."

echo "PWD is ${PROJECT_DIR}"

base_directory=$(find_xcworkspace_dir ${PROJECT_DIR})

if [[ -z "$base_directory" ]]; then
  echo "Error: RevenueCat.xcworkspace not found in the current directory or any parent directory."
  exit 1
fi

echo "Starting at: $base_directory"

# debug log
log_file="preprocess_log.txt"
echo "Starting log at $(date)" > "$log_file"

# Find all .swift files recursively from the base directory
find "$base_directory" -type f -name "*.swift" | while read -r file; do

    if grep -q '//@PublicForExternalTesting' "$file"; then
        # Backup original file
        original_file="${file}.orig"
        cp "$file" "$original_file"

        # Find //@PublicForExternalTesting and replace it with public before declarations
        sed -i.bak -E \
        '/\/\/@PublicForExternalTesting[[:space:]]*$/{
        N
        s/\/\/@PublicForExternalTesting[[:space:]]*\n[[:space:]]*(static[[:space:]]+)?(struct|class|final[[:space:]]+class|enum|init|func)/public \1\2/
        }' "$file"

        # Log changes made to the file
        diff_output=$(diff "$original_file" "$file")
        if [[ -n "$diff_output" ]]; then
            echo "Changes made in file: $file" | tee -a "$log_file"
            echo "$diff_output" | tee -a "$log_file"
        fi

        # Remove the backup file
        rm -f "$original_file" "${file}.bak"
    fi
done

echo "Processing completed." | tee -a "$log_file"

