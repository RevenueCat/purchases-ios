// Detects file changes between HEAD~1 and HEAD and emits
// /tmp/default-config-parameters.json with path-based pipeline parameters that
// the setup config forwards to default_config.yml via continuation/continue.
//
// To add a new path-based parameter:
//   1. Declare the parameter in default_config.yml (NOT in config.yml,
//      otherwise continuation/continue may raise "Conflicting pipeline
//      parameters" when the pipeline is API-triggered with a non-default value).
//   2. Add an entry below mapping the parameter name to its path prefixes.
//   3. Gate the relevant workflow/job on the parameter in default_config.yml.

const { execSync } = require("child_process");
const fs = require("fs");

const PATH_BASED_PARAMETERS = {
  run_deploy_paywalls_tester: [
    "RevenueCatUI/",
    "Tests/TestingApps/PaywallsTester/",
  ],
};

const OUTPUT_PATH = "/tmp/default-config-parameters.json";

function getChangedFiles() {
  try {
    execSync("git rev-parse HEAD~1", { stdio: "ignore" });
  } catch {
    console.log("No parent commit found (initial commit?), skipping path check");
    return [];
  }
  return execSync("git diff HEAD~1 --name-only", { encoding: "utf8" })
    .split("\n")
    .filter(Boolean);
}

const changed = getChangedFiles();
const params = {};
for (const [name, prefixes] of Object.entries(PATH_BASED_PARAMETERS)) {
  const matches = changed.filter((f) => prefixes.some((p) => f.startsWith(p)));
  params[name] = matches.length > 0;
  console.log(
    `${name} = ${params[name]}${matches.length ? ` (${matches.length} matching file(s))` : ""}`
  );
  matches.forEach((f) => console.log(`  ${f}`));
}

fs.writeFileSync(OUTPUT_PATH, JSON.stringify(params));
console.log(`\nWrote ${OUTPUT_PATH}:\n${fs.readFileSync(OUTPUT_PATH, "utf8")}`);
