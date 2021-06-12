#!/bin/bash

# Figure out where swiftlint is
HOMEBREW_BINARY_DESTINATION="/opt/homebrew/bin"
SWIFT_LINT="${HOMEBREW_BINARY_DESTINATION}/swiftlint"

if ! test -d $HOMEBREW_BINARY_DESTINATION; then
  # X86_64 macs have this destination
  SWIFT_LINT="/usr/local/bin/swiftlint"
fi

# Start timer
START_DATE=$(date +"%s")

# Run SwiftLint for given filename
run_swiftlint() {
  local filename="${1}"
  echo "File is: ${filename}"
  echo "File with previous extension is: ${filename#*.}"
    if [[ "${filename##*.}" == "swift" ]]; then
      if [[ "${filename#*.}" != "generated.swift" ]]; then
      echo "Autocorrecting..."
      ${SWIFT_LINT} --fix --path "${filename}"
      ${SWIFT_LINT} lint --path "${filename}"
      fi
    fi
}

if [[ -e "${SWIFT_LINT}" ]]; then
  echo "SwiftLint version: $(${SWIFT_LINT} version)"
  # Run only if not merging
  if ! git rev-parse -q --verify MERGE_HEAD; then 
    # Run for just staged files
    git diff --cached --name-only | while read filename; do run_swiftlint "${filename}"; done
  fi
else
  echo "${SWIFT_LINT} is not installed. Please install it via: fastlane setup_dev"
  exit -1
fi

END_DATE=$(date +"%s")

DIFF=$(($END_DATE - $START_DATE))
echo "SwiftLint took $(($DIFF / 60)) minutes and $(($DIFF % 60)) seconds to complete."
