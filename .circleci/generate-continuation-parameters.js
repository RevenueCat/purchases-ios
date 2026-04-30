#!/usr/bin/env node
"use strict";

const fs = require("fs");
const { execSync } = require("child_process");

const OUTPUT = "/tmp/continuation-parameters.json";

// Runs a git command and returns its trimmed stdout, or null if the command fails.
// stderr is discarded so callers don't need to redirect it themselves.
function tryGit(args) {
  try {
    return execSync(`git ${args}`, {
      encoding: "utf-8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
  } catch {
    return null;
  }
}

// True if the triggering commit modified `.version`. Used to gate the
// `snapshot-bump` workflow so it only runs on commits that actually changed
// the version (release commits and SNAPSHOT-bump merges) and not on every
// unrelated commit landing on main.
function versionFileChanged() {
  if (tryGit("rev-parse --verify HEAD^") === null) {
    return false;
  }
  const diff = tryGit("diff --name-only HEAD^ HEAD -- .version");
  if (diff === null) {
    return false;
  }
  return diff.split("\n").some((line) => line.trim() === ".version");
}

const parameters = {
  version_file_changed: versionFileChanged(),
};

fs.writeFileSync(OUTPUT, `${JSON.stringify(parameters, null, 2)}\n`);

for (const [key, value] of Object.entries(parameters)) {
  console.log(`${key}=${value}`);
}
console.log(`Wrote ${OUTPUT}`);
