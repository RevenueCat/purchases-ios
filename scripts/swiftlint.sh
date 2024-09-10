#!/usr/bin/env bash

# Arm64 macs have this destination.
HOMEBREW_BINARY_DESTINATION="/opt/homebrew/bin"
if ! test -d $HOMEBREW_BINARY_DESTINATION; then
  # X86_64 macs have this destination
  HOMEBREW_BINARY_DESTINATION="/usr/local/bin"
fi

echo "Adding homebrew bin folder to PATH (${HOMEBREW_BINARY_DESTINATION})"
PATH="${HOMEBREW_BINARY_DESTINATION}:${PATH}"

if which swiftlint >/dev/null; then
  script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
  source_path="${script_path}/../"
  swiftlint_path="$(which swiftlint)"

  echo "linter path:"
  echo $swiftlint_path

  lint_command="${swiftlint_path} lint"
  echo "linter command: ${lint_command}"
  
  pushd "${source_path}"
  # Run swiftlint but filter out "Linting ..." to clean up output
  $lint_command 2>&1 | grep -v 'Linting '
  popd
else
  echo "Warning: SwiftLint not installed in ${HOMEBREW_BINARY_DESTINATION}, download from https://github.com/realm/SwiftLint"
fi

