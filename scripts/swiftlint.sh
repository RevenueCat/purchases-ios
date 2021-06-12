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
  config_path="${script_path}/../.swiftlint.yml"
  source_path="${script_path}/../"
  swiftlint_path="$(which swiftlint)"
  echo "linter path:"
  echo $swiftlint_path

  # Want different options for just your environment? Create a `.swiftlint.options.local` file in the same directory as
  # `.swiftlint.yml` to override options. Leave the file empty to suppress default options.
  options_path="${script_path}/../.swiftlint.options.local"
  options=""

  # Use --strict if you want warnings to be errors... it's kinda aggressive, I wouldn't.
  # strict_option="--strict"
  strict_option=""

  # If the `.swiftlint.options.local` file exists, check to see if the options are supported in it.
  if [[ -f "$options_path" ]]; then
    if grep -- "$strict_option" "$options_path" > /dev/null 2>&1; then
      options="$options $strict_option"
    fi
  # Otherwise set the default options.
  else
    options="$strict_option"
  fi

  lint_command="${swiftlint_path} lint ${options} --config ${config_path} ${source_path}"
  echo "linter command: ${lint_command}"
  $lint_command
else
  echo "error: SwiftLint not installed in ${HOMEBREW_BINARY_DESTINATION}, download from https://github.com/realm/SwiftLint"
fi
