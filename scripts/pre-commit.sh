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
SHOULD_FAIL_PRECOMMIT=0

# Run SwiftLint for given filename
run_swiftlint() {
  local filename="${1}"
  if [[ "${filename##*.}" == "swift" ]]; then
    if [[ "${filename#*.}" != "generated.swift" ]]; then
    ${SWIFT_LINT} --strict "${filename}"
    retVal=$?
    if [ $retVal -ne 0 ]; then
      SHOULD_FAIL_PRECOMMIT=$retVal
    fi

    ${SWIFT_LINT} --autocorrect --strict "${filename}"
    fi
  fi
}

verify_no_included_apikeys() {
  # readlink -f follows the link from .git/hooks/pre-commit back to scripts/pre-commit.sh
  # if executed through there. If not it returns the same file.
  SCRIPT_DIR=$(cd $(dirname $(readlink -f "${BASH_SOURCE[0]}")) && pwd)
  FILES_TO_CHECK=(
    "${SCRIPT_DIR}/../Tests/BackendIntegrationTests/Constants.swift"
    "${SCRIPT_DIR}/../Examples/MagicWeather/MagicWeather/Constants.swift"
    "${SCRIPT_DIR}/../Examples/MagicWeatherSwiftUI/Shared/Constants.swift"
  )
  PATTERN="\"REVENUECAT_API_KEY\""

  for i in "${FILES_TO_CHECK[@]}" 
  do
    grep -q $PATTERN $i
    FOUND=$?
    if [ $FOUND -ne 0 ]; then
      echo "Leftover API Key found in '$(basename $i)'. Please remove."
      exit $FOUND
    fi
  done
}

if [[ -e "${SWIFT_LINT}" ]]; then
  echo "SwiftLint version: $(${SWIFT_LINT} version)"
  # Run only if not merging
  if ! git rev-parse -q --verify MERGE_HEAD; then 
    # Run for just staged files
    while IFS= read -r -d '' file; do
      run_swiftlint "${file}"
    done < <(git diff --cached --name-only -z)
  fi
else
  echo "${SWIFT_LINT} is not installed. Please install it via: fastlane setup_dev"
  exit -1
fi

END_DATE=$(date +"%s")

DIFF=$(($END_DATE - $START_DATE))
echo "SwiftLint took $(($DIFF / 60)) minutes and $(($DIFF % 60)) seconds to complete."

if [ $SHOULD_FAIL_PRECOMMIT -ne 0 ]; then
  echo "😵 Found formatting errors, some might have been autocorrected."
  echo ""
  echo "⚠️  Please run '${SWIFT_LINT} --autocorrect --strict' then check the changes were made and commit them. ⚠️"

  exit $SHOULD_FAIL_PRECOMMIT
else
  verify_no_included_apikeys
fi