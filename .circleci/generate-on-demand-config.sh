#!/usr/bin/env bash
set -euo pipefail

REQUESTED_JOBS="$1"
CONFIG=".circleci/continue_config.yml"

JOBS=$(echo "$REQUESTED_JOBS" | tr ',' ' ' | xargs)

ALLOWED="lint danger api-tests check-api-changes pod-lib-lint
  spm-receipt-parser spm-revenuecat-ui-ios-15 spm-revenuecat-ui-ios-16
  run-revenuecat-ui-ios-18-and-17 run-revenuecat-ui-ios-26
  spm-revenuecat-ui-watchos run-test-tvos-and-macos run-test-ios-26
  run-test-ios-18-and-17 run-test-ios-16 run-test-ios-15-and-14
  run-test-watchos build-tv-watch-mac-and-visionos
  backend-integration-tests-SK1 backend-integration-tests-SK2
  backend-integration-tests-other backend-integration-tests-offline
  backend-integration-tests-custom-entitlements
  run-all-maestro-e2e-tests installation-tests-all-but-carthage
  installation-tests-carthage revenuecat-admob-tests
  emerge_purchases_ui_snapshot_tests emerge_binary_size_analysis
  docs-build generate-swiftinterface
  record-and-push-paywall-template-screenshots
  integration-tests-all loadshedder-integration-tests-old-major"

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
head -n "$WF_LINE" "$CONFIG" > /tmp/on-demand-config.yml

{
  echo "  on-demand-jobs:"
  echo "    jobs:"
  for JOB in $JOBS; do
    echo "      - ${JOB}:"
    echo "          context:"
    echo "            - slack-secrets"
  done
} >> /tmp/on-demand-config.yml
