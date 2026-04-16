#!/usr/bin/env node
"use strict";

const fs = require("fs");

const CONFIG = ".circleci/default_config.yml";
const OUTPUT = "/tmp/requested-jobs-config.yml";

const ALLOWED = [
  "api-tests",
  "backend-integration-tests-SK1",
  "backend-integration-tests-SK2",
  "backend-integration-tests-custom-entitlements",
  "backend-integration-tests-offline",
  "backend-integration-tests-other",
  "build-tv-watch-mac-and-visionos",
  "check-api-changes",
  "docs-build",
  "emerge_binary_size_analysis",
  "emerge_purchases_ui_snapshot_tests",
  "generate-swiftinterface",
  "installation-tests-all-but-carthage",
  "installation-tests-carthage",
  "integration-tests-all",
  "lint",
  "pod-lib-lint",
  "revenuecat-admob-tests",
  "run-all-maestro-e2e-tests",
  "run-revenuecat-ui-ios-18-and-17",
  "run-revenuecat-ui-ios-26",
  "run-test-ios-15-and-14",
  "run-test-ios-16",
  "run-test-ios-18-and-17",
  "run-test-ios-26",
  "run-test-tvos-and-macos",
  "run-test-watchos",
  "spm-receipt-parser",
  "spm-revenuecat-ui-ios-15",
  "spm-revenuecat-ui-ios-16",
  "spm-revenuecat-ui-watchos",
];

const requestedJobs = (process.env.REQUESTED_JOBS || "").trim().split(/\s+/).filter(Boolean);

if (requestedJobs.length === 0) {
  console.error("ERROR: No jobs specified.");
  process.exit(1);
}

for (const job of requestedJobs) {
  if (!ALLOWED.includes(job)) {
    console.error(`ERROR: '${job}' is not allowed for on-demand triggering.`);
    console.error(`Allowed jobs:\n  ${ALLOWED.join("\n  ")}`);
    process.exit(1);
  }
}

const configContent = fs.readFileSync(CONFIG, "utf-8");
const lines = configContent.split("\n");
const workflowsIndex = lines.findIndex((line) => line === "workflows:");

if (workflowsIndex === -1) {
  console.error(`ERROR: 'workflows:' not found in ${CONFIG}`);
  process.exit(1);
}

const header = lines.slice(0, workflowsIndex + 1).join("\n");
const workflow = requestedJobs
  .map(
    (job) =>
      `      - ${job}:\n          context:\n            - e2e-tests\n            - slack-secrets`
  )
  .join("\n");

const output = `${header}\n  on-demand-jobs:\n    jobs:\n${workflow}\n`;

fs.writeFileSync(OUTPUT, output);
console.log(`Generated ${OUTPUT} with jobs: ${requestedJobs.join(", ")}`);
