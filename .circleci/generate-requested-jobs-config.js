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
  "check-app-extension-safe-api-usage": ["slack-secrets"],
  "build-checkpoint-tester": ["slack-secrets"],
  "build-tv-watch-mac-and-visionos": ["slack-secrets"],
  "check-api-changes": ["slack-secrets-ios", "slack-secrets"],
  "docs-build": ["slack-secrets"],
  "binary_size_analysis": ["slack-secrets", "sentry"],
  "emerge_purchases_ui_snapshot_tests": ["slack-secrets"],
  "generate-swiftinterface": ["slack-secrets-ios"],
  "installation-tests-all-but-carthage": ["slack-secrets"],
  "installation-tests-carthage": ["slack-secrets"],
  "installation-tests-carthage-xcode-27": ["slack-secrets"],
  "integration-tests-all": ["slack-secrets"],
  "lint": ["slack-secrets"],
  "pod-lib-lint": ["slack-secrets"],
  "remote-config-production-tests": ["config-endpoint-tests", "slack-secrets"],
  "revenuecat-admob-tests": ["slack-secrets"],
  "run-all-maestro-e2e-tests": ["e2e-tests", "slack-secrets"],
  "run-paywall-accessibility-ui-tests": [],
  "run-workflow-maestro-tests": ["e2e-tests", "slack-secrets"],
  "run-revenuecat-ui-ios-18-and-17": ["slack-secrets"],
  "run-revenuecat-ui-ios-26": ["slack-secrets"],
  "run-revenuecat-ui-ios-27": ["slack-secrets"],
  "run-test-ios-15-and-14": ["slack-secrets"],
  "run-test-ios-16": ["slack-secrets"],
  "run-test-ios-18-and-17": ["slack-secrets"],
  "run-test-ios-26": ["slack-secrets"],
  "run-test-ios-27": ["slack-secrets"],
  "run-test-tvos-and-macos": ["slack-secrets"],
  "run-test-watchos": ["slack-secrets"],
  "spm-receipt-parser": ["slack-secrets"],
  "spm-revenuecat-ui-ios-15": ["slack-secrets"],
  "spm-revenuecat-ui-ios-16": ["slack-secrets"],
  "spm-revenuecat-ui-macos": ["slack-secrets"],
  "spm-revenuecat-ui-watchos": ["slack-secrets"],
};

// Some allowlisted entries are parameterized variants of an underlying job rather
// than standalone jobs. They map to the real job name plus the parameters to pass,
// matching how they're invoked in default_config.yml's workflows.
const PARAMETERIZED_JOBS = {
  "installation-tests-carthage-xcode-27": {
    job: "installation-tests-carthage",
    parameters: { xcode_version: "27.0.0" },
  },
};

// Allowlisted names that trigger several jobs at once, for jobs that depend on each other's
// output and can't run standalone. Each entry mirrors how the job is invoked in
// default_config.yml's workflows.
const JOB_GROUPS = {
  "run-sdk-update-test": [
    { job: "build-sdk-update-test-apps", contexts: ["e2e-tests"] },
    {
      job: "run-sdk-update-test",
      name: "run-sdk-update-test-anonymous-user",
      parameters: { test_case: "anonymous_user" },
      requires: ["build-sdk-update-test-apps"],
    },
    {
      job: "run-sdk-update-test",
      name: "run-sdk-update-test-logged-in-user",
      parameters: { test_case: "logged_in_user" },
      requires: ["build-sdk-update-test-apps"],
    },
  ],
};

const requestedJobs = (process.env.REQUESTED_JOBS || "").trim().split(/\s+/).filter(Boolean);

if (requestedJobs.length === 0) {
  console.error("ERROR: No jobs specified.");
  process.exit(1);
}

for (const job of requestedJobs) {
  if (!(job in JOBS) && !(job in JOB_GROUPS)) {
    console.error(`ERROR: '${job}' is not allowed for on-demand triggering.`);
    console.error(`Allowed jobs:\n  ${[...Object.keys(JOBS), ...Object.keys(JOB_GROUPS)].join("\n  ")}`);
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
const toWorkflowEntries = (job) => {
  if (job in JOB_GROUPS) {
    return JOB_GROUPS[job];
  }
  const variant = PARAMETERIZED_JOBS[job];
  if (variant) {
    return [{ job: variant.job, name: job, parameters: variant.parameters, contexts: JOBS[job] }];
  }
  return [{ job, contexts: JOBS[job] }];
};

const renderWorkflowEntry = (entry) => {
  const { job, name } = entry;
  const parameters = Object.entries(entry.parameters ?? {});
  const contexts = entry.contexts ?? [];
  const requires = entry.requires ?? [];

  if (!name && parameters.length === 0 && contexts.length === 0 && requires.length === 0) {
    return `      - ${job}`;
  }

  const lines = [`      - ${job}:`];
  if (name) {
    lines.push(`          name: ${name}`);
  }
  for (const [key, value] of parameters) {
    lines.push(`          ${key}: "${value}"`);
  }
  if (contexts.length > 0) {
    lines.push("          context:");
    for (const ctx of contexts) {
      lines.push(`            - ${ctx}`);
    }
  }
  if (requires.length > 0) {
    lines.push("          requires:");
    for (const requirement of requires) {
      lines.push(`            - ${requirement}`);
    }
  }
  return lines.join("\n");
};

const workflow = requestedJobs.flatMap(toWorkflowEntries).map(renderWorkflowEntry).join("\n");

const output = `${header}\n  on-demand-jobs:\n    jobs:\n${workflow}\n`;

fs.writeFileSync(OUTPUT, output);
console.log(`Generated ${OUTPUT} with jobs: ${requestedJobs.join(", ")}`);
