#!/usr/bin/env node
"use strict";

const fs = require("fs");

const CONFIG = ".circleci/default_config.yml";
const OUTPUT = "/tmp/requested-jobs-config.yml";

// Allowlist of jobs that can be triggered on-demand, mapped to the CircleCI contexts
// each job needs. Contexts must match what the job is declared with in default_config.yml,
// so the on-demand run has access to the same secrets as the regular run.
// Release/deployment jobs are intentionally excluded.
const JOBS = {
  "api-tests": ["slack-secrets"],
  "backend-integration-tests-SK1": ["slack-secrets"],
  "backend-integration-tests-SK2": ["slack-secrets"],
  "backend-integration-tests-custom-entitlements": ["slack-secrets"],
  "backend-integration-tests-offline": ["slack-secrets"],
  "backend-integration-tests-other": ["slack-secrets"],
  "build-tv-watch-mac-and-visionos": ["slack-secrets"],
  "check-api-changes-revenuecat": ["slack-secrets-ios"],
  "check-api-changes-revenuecatui": ["slack-secrets-ios"],
  "docs-build": ["slack-secrets"],
  "emerge_binary_size_analysis": ["slack-secrets"],
  "emerge_purchases_ui_snapshot_tests": ["slack-secrets"],
  "generate-swiftinterface": ["slack-secrets-ios"],
  "installation-tests-all-but-carthage": ["slack-secrets"],
  "installation-tests-carthage": ["slack-secrets"],
  "integration-tests-all": ["slack-secrets"],
  "lint": [],
  "pod-lib-lint": ["slack-secrets"],
  "revenuecat-admob-tests": ["slack-secrets"],
  "run-all-maestro-e2e-tests": ["e2e-tests", "slack-secrets"],
  "run-revenuecat-ui-ios-18-and-17": ["slack-secrets"],
  "run-revenuecat-ui-ios-26": ["slack-secrets"],
  "run-test-ios-15-and-14": ["slack-secrets"],
  "run-test-ios-16": ["slack-secrets"],
  "run-test-ios-18-and-17": ["slack-secrets"],
  "run-test-ios-26": ["slack-secrets"],
  "run-test-tvos-and-macos": ["slack-secrets"],
  "run-test-watchos": ["slack-secrets"],
  "spm-receipt-parser": ["slack-secrets"],
  "spm-revenuecat-ui-ios-15": ["slack-secrets"],
  "spm-revenuecat-ui-ios-16": ["slack-secrets"],
  "spm-revenuecat-ui-watchos": ["slack-secrets"],
};

const requestedJobs = (process.env.REQUESTED_JOBS || "").trim().split(/\s+/).filter(Boolean);

if (requestedJobs.length === 0) {
  console.error("ERROR: No jobs specified.");
  process.exit(1);
}

for (const job of requestedJobs) {
  if (!(job in JOBS)) {
    console.error(`ERROR: '${job}' is not allowed for on-demand triggering.`);
    console.error(`Allowed jobs:\n  ${Object.keys(JOBS).join("\n  ")}`);
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
  .map((job) => {
    const contexts = JOBS[job];
    if (contexts.length === 0) {
      return `      - ${job}`;
    }
    const contextLines = contexts.map((ctx) => `            - ${ctx}`).join("\n");
    return `      - ${job}:\n          context:\n${contextLines}`;
  })
  .join("\n");

const output = `${header}\n  on-demand-jobs:\n    jobs:\n${workflow}\n`;

fs.writeFileSync(OUTPUT, output);
console.log(`Generated ${OUTPUT} with jobs: ${requestedJobs.join(", ")}`);
