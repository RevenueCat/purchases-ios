#!/bin/bash

# =============================================================================
# SwiftLint Pre-Commit Hook
# =============================================================================
# Flow:
#   1. Collect all staged Swift files (batch processing)
#   2. Run autocorrect quietly
#   3. Re-stage any files that were modified
#   4. Run lint to check for remaining violations
#   5. Show clear summary of what needs manual attention
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Figure out where swiftlint is
HOMEBREW_BINARY_DESTINATION="/opt/homebrew/bin"
SWIFT_LINT="${HOMEBREW_BINARY_DESTINATION}/swiftlint"

if ! test -d $HOMEBREW_BINARY_DESTINATION; then
  # X86_64 macs have this destination
  SWIFT_LINT="/usr/local/bin/swiftlint"
fi

# Start timer
START_DATE=$(date +"%s")

# Helper functions
print_header() {
  echo -e "${BLUE}${BOLD}$1${NC}"
}

print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
  echo -e "${RED}✗ $1${NC}"
}

verify_no_included_apikeys() {
  # readlink -f follows the link from .git/hooks/pre-commit back to scripts/pre-commit.sh
  # if executed through there. If not it returns the same file.
  SCRIPT_DIR=$(cd $(dirname $(readlink -f "${BASH_SOURCE[0]}")) && pwd)
  FILES_TO_CHECK=(
    "${SCRIPT_DIR}/../Tests/BackendIntegrationTests/Constants.swift"
    "${SCRIPT_DIR}/../Examples/MagicWeather/MagicWeather/Constants.swift"
    "${SCRIPT_DIR}/../Examples/MagicWeatherSwiftUI/Shared/Constants.swift"
    "${SCRIPT_DIR}/../Tests/TestingApps/PurchaseTesterSwiftUI/Core/Constants.swift"
    "${SCRIPT_DIR}/../Tests/TestingApps/PaywallsTester/PaywallsTester/Config/Constants.swift"
    "${SCRIPT_DIR}/../Examples/SampleCat/SampleCat/Constants.swift"
  )
  FILES_STAGED=$(git diff --cached --name-only)
  PATTERN="\"REVENUECAT_API_KEY\""

  for staged_file in $FILES_STAGED
  do
    absolute_staged_file=$(realpath "$staged_file")
    for api_file in "${FILES_TO_CHECK[@]}"
    do
      absolute_api_file=$(realpath "$api_file")
      if [ -n "$absolute_staged_file" ] && [ -n "$absolute_api_file" ] && [ "$absolute_staged_file" = "$absolute_api_file" ] && ! grep -q "$PATTERN" "$absolute_staged_file"; then
        echo "Leftover API Key found in '$(basename $absolute_staged_file)'. Please remove."
        exit 1
      fi
    done
  done
}

# Check if SwiftLint is installed
if [[ ! -e "$SWIFT_LINT" ]]; then
  print_error "$SWIFT_LINT is not installed. Please install it via: fastlane setup_dev"
  exit 1
fi

# Skip if merging
if git rev-parse -q --verify MERGE_HEAD; then
  print_warning "Merge in progress, skipping SwiftLint"
  exit 0
fi

# =============================================================================
# Step 1: Collect all staged Swift files (batch processing)
# =============================================================================
SWIFT_FILES=()
    while IFS= read -r -d '' file; do
  # Skip generated files
  if [[ "${file#*.}" == "generated.swift" ]]; then
    continue
  fi
      # Get file status from git status --porcelain
      status=$(git status --porcelain -- "$file" | cut -c1-2)
  # Skip deleted files
      if [[ "$status" != "D " ]]; then
    SWIFT_FILES+=("$file")
      fi
    done < <(git diff --cached --name-only -z -- '*.swift')

# If no Swift files staged, we're done
if [[ ${#SWIFT_FILES[@]} -eq 0 ]]; then
  verify_no_included_apikeys
  exit 0
fi

print_header "SwiftLint v$("$SWIFT_LINT" version)"
echo "Checking ${#SWIFT_FILES[@]} Swift file(s)..."
echo ""

# =============================================================================
# Step 2: Store checksums before autocorrect (using temp file for compatibility)
# =============================================================================
CHECKSUM_FILE=$(mktemp)
trap 'rm -f $CHECKSUM_FILE' EXIT

for file in "${SWIFT_FILES[@]}"; do
  if [[ -f "$file" ]]; then
    checksum=$(md5 -q "$file" 2>/dev/null || md5sum "$file" | cut -d' ' -f1)
    echo "$file:$checksum" >> "$CHECKSUM_FILE"
  fi
done

# =============================================================================
# Step 3: Run autocorrect quietly on all files
# =============================================================================
"$SWIFT_LINT" --fix --quiet "${SWIFT_FILES[@]}" 2>/dev/null

# =============================================================================
# Step 4: Re-stage any files that were modified by autocorrect
# =============================================================================
FIXED_FILES=()
for file in "${SWIFT_FILES[@]}"; do
  if [[ -f "$file" ]]; then
    checksum_after=$(md5 -q "$file" 2>/dev/null || md5sum "$file" | cut -d' ' -f1)
    checksum_before=$(grep "^$file:" "$CHECKSUM_FILE" | cut -d':' -f2-)
    if [[ "$checksum_before" != "$checksum_after" ]]; then
      FIXED_FILES+=("$file")
      git add "$file"
    fi
  fi
done

# Report auto-fixed files
if [[ ${#FIXED_FILES[@]} -gt 0 ]]; then
  print_success "Auto-fixed and re-staged ${#FIXED_FILES[@]} file(s):"
  for file in "${FIXED_FILES[@]}"; do
    echo "    $file"
  done
  echo ""
fi

# =============================================================================
# Step 5: Run lint to check for remaining violations
# =============================================================================
# Capture lint output
LINT_OUTPUT=$("$SWIFT_LINT" --strict "${SWIFT_FILES[@]}" 2>&1)
LINT_EXIT_CODE=$?

# =============================================================================
# Step 6: Show clear summary
# =============================================================================
END_DATE=$(date +"%s")
DIFF=$((END_DATE - START_DATE))

if [[ $LINT_EXIT_CODE -eq 0 ]]; then
  # All good!
  if [[ ${#FIXED_FILES[@]} -gt 0 ]]; then
    print_success "All issues were auto-fixed and re-staged!"
  else
    print_success "No violations found"
  fi
  echo "Completed in ${DIFF}s"
  echo ""
  verify_no_included_apikeys
  exit 0
else
  # There are violations that need manual attention
  echo ""
  print_error "Violations require manual fixes:"
  echo ""
  
  # Parse and display violations more clearly
  # Filter out noise, show only error lines
  echo "$LINT_OUTPUT" | grep -E "^/.+:[0-9]+:[0-9]+: (error|warning):" | while read -r line; do
    # Extract components
    file_path=$(echo "$line" | sed -E 's/^(.+):[0-9]+:[0-9]+:.*/\1/')
    line_col=$(echo "$line" | sed -E 's/^.+:([0-9]+:[0-9]+):.*/\1/')
    severity=$(echo "$line" | sed -E 's/^.+:[0-9]+:[0-9]+: (error|warning):.*/\1/')
    message=$(echo "$line" | sed -E 's/^.+:[0-9]+:[0-9]+: (error|warning): (.+)/\2/')
    
    # Extract rule name from parentheses at end of message, e.g., (function_body_length)
    rule_name=$(echo "$message" | sed -E 's/.*\(([a-z_]+)\)$/\1/')
    # Remove the rule name from message for cleaner display
    clean_message=$(echo "$message" | sed -E 's/ \([a-z_]+\)$//')
    
    # Get relative path
    rel_path="${file_path#"$(pwd)/"}"
    
    if [[ "$severity" == "error" ]]; then
      echo -e "  ${RED}error${NC} ${rel_path}:${line_col}"
    else
      echo -e "  ${YELLOW}warning${NC} ${rel_path}:${line_col}"
    fi
    echo -e "        ${clean_message}"
    echo -e "        ${DIM}Disable:${NC} ${CYAN}// swiftlint:disable:next ${rule_name}${NC}"
    echo ""
  done
  
  # Count violations
  ERROR_COUNT=$(echo "$LINT_OUTPUT" | grep -c ": error:")
  WARNING_COUNT=$(echo "$LINT_OUTPUT" | grep -c ": warning:")
  
  echo ""
  echo -e "${BOLD}Summary:${NC}"
  if [[ ${#FIXED_FILES[@]} -gt 0 ]]; then
    print_success "${#FIXED_FILES[@]} file(s) auto-fixed and re-staged"
  fi
  if [[ $ERROR_COUNT -gt 0 ]]; then
    print_error "$ERROR_COUNT error(s) require manual fixes"
  fi
  if [[ $WARNING_COUNT -gt 0 ]]; then
    print_warning "$WARNING_COUNT warning(s)"
  fi
  echo ""
  echo "Completed in ${DIFF}s"
  echo ""
  print_error "Please fix the above violations and try again."
  exit 1
fi
