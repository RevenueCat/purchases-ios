#!/usr/bin/env bash
set -euo pipefail

REQUESTED_JOBS="$1"
CONFIG=".circleci/default_config.yml"

JOBS=$(echo "$REQUESTED_JOBS" | tr ',' ' ' | xargs)

ALLOWED="
  api-tests
  backend-integration-tests-SK1
  backend-integration-tests-SK2
  backend-integration-tests-custom-entitlements
  backend-integration-tests-offline
  backend-integration-tests-other
  build-tv-watch-mac-and-visionos
  check-api-changes
  danger
  docs-build
  emerge_binary_size_analysis
  emerge_purchases_ui_snapshot_tests
  generate-swiftinterface
  installation-tests-all-but-carthage
  installation-tests-carthage
  integration-tests-all
  lint
  loadshedder-integration-tests-old-major
  pod-lib-lint
  record-and-push-paywall-template-screenshots
  revenuecat-admob-tests
  run-all-maestro-e2e-tests
  run-revenuecat-ui-ios-18-and-17
  run-revenuecat-ui-ios-26
  run-test-ios-15-and-14
  run-test-ios-16
  run-test-ios-18-and-17
  run-test-ios-26
  run-test-tvos-and-macos
  run-test-watchos
  spm-receipt-parser
  spm-revenuecat-ui-ios-15
  spm-revenuecat-ui-ios-16
  spm-revenuecat-ui-watchos
"

for JOB in $JOBS; do
  FOUND=false
  for A in $ALLOWED; do
    if [ "$JOB" = "$A" ]; then FOUND=true; break; fi
  done
  if [ "$FOUND" = false ]; then
    echo "ERROR: '$JOB' is not allowed for on-demand triggering."
    echo "Allowed jobs: $(echo $ALLOWED | tr ' ' '\n' | sort | tr '\n' ' ')"
    exit 1
  fi
done

WF_LINE=$(grep -n '^workflows:' "$CONFIG" | head -1 | cut -d: -f1)
head -n "$WF_LINE" "$CONFIG" > /tmp/requested-jobs-config.yml

{
  echo "  on-demand-jobs:"
  echo "    jobs:"
  for JOB in $JOBS; do
    echo "      - ${JOB}:"
    echo "          context:"
    echo "            - slack-secrets"
  done
} >> /tmp/requested-jobs-config.yml
