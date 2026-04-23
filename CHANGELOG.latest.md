## RevenueCat SDK
### 🐞 Bugfixes
* Resolve the issue around tab control context identity (PWENG-31) (#6634) via Alexander Repty (@alexrepty)

### 🔄 Other Changes
* Add opt-in bump_with_fallback_pr_lookup CircleCI parameter (#6669) via Antonio Pallares (@ajpallares)
* Bump fastlane-plugin-revenuecat_internal from `b822f01` to `d24ab26` (#6670) via dependabot[bot] (@dependabot[bot])
* AdMob SSV: add `@_spi(Internal)` poll endpoint on `Purchases` (#6641) via Pol Miro (@polmiro)
* Skip CI on auto-generated snapshot branches (#6633) via Rick (@rickvdl)
* Add TUIST_LAUNCH_ARGUMENTS env var for injecting launch arguments at generation time (#6664) via Facundo Menzella (@facumenzella)
* Add workflow to re-run Danger on PR label change (#6660) via Rick (@rickvdl)
* Fix rcgitbot_please_test token permissions for PR comments (#6655) via Antonio Pallares (@ajpallares)
* Fall back to getCustomerInfo when posting unfinished receipt fails (#6650)

* Fall back to getCustomerInfo when posting unfinished receipt fails

* Stub getCustomerInfo failure in diagnostics-with-failure test

* Silence function_body_length lint on getCustomerInfoData

* Drive delegate test through real receipt post + backend rejection

* Log and document receipt-post fallback to getCustomerInfo

* Test fallback fires when first of multiple unfinished posts fails via Rick
* Add pr:other label to auto-generated snapshot PRs (#6631)

* Add pr:other label to auto-generated snapshot PRs

* Also ignore auto-generated snapshot PRs from changelog via Rick
* Add legacy paywall component_name for iOS (#6662) via Monika Mateska
* Add TUIST_SWIFT_CONDITIONS for injecting compiler flags at project generation time (#6661)

* Add TUIST_SWIFT_CONDITIONS env var for injecting compiler flags at generation time

Introduces a generic mechanism to pass arbitrary Swift active compilation
conditions when generating Xcode projects via Tuist. Any target generated
through the Tuist Xcode project mode (TUIST_RC_XCODE_PROJECT=true) will
pick up the flags automatically.

Usage:
  TUIST_RC_XCODE_PROJECT=true TUIST_SWIFT_CONDITIONS="MY_FLAG" tuist generate PaywallsTester
  TUIST_RC_XCODE_PROJECT=true TUIST_SWIFT_CONDITIONS="FLAG_A FLAG_B" tuist generate

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>

* Rename appendingExtraSwiftConditions to appendingTuistSwiftConditions

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>

---------

Co-authored-by: Claude Sonnet 4.6 <noreply@anthropic.com> via Facundo Menzella
* Defer paywall dismissal after purchase callbacks (#6621)

Delay paywall dismissal until purchase completion callbacks have run by moving dismissal into a DispatchQueue.main.async helper (dismissAfterPurchaseCompletionCallbacks) in LoadedOfferingPaywallView and PaywallsV2View. This ensures onPurchaseCompleted handlers and related state propagate to parent modifiers before invoking onRequestedDismissal or automatic dismissal. Adds a unit test to verify onPurchaseCompleted is called before requested dismissal. via Jacob Rakidzich
* Skip SPM Release Build steps during snapshot-generation pipelines (#6659)

* Skip SPM Release Build step in run-test-ios-15-and-14 on snapshot pipelines

No snapshots depend on the SPM release build, and the step can take up
to 30 minutes. Skipping it on `generate_snapshots` pipelines shortens
snapshot-generation wall time without losing coverage — normal CI runs
still exercise the release build unchanged.

Made-with: Cursor

* Drop redundant comment on skipped SPM Release Build step

Made-with: Cursor

* Skip all SPM Release Build steps on matching snapshot pipelines

Extends the previous skip from `run-test-ios-15-and-14` to every other
SPM release build step that runs inside a job invoked by a
snapshot-generation workflow. No snapshots depend on the SPM release
builds, so running them during snapshot pipelines is useless CI work.

Mapping:
- `generate-snapshot` workflow (`generate_snapshots`) → steps in
  `run-test-ios-26`, `run-test-ios-18-and-17`, `run-test-ios-16`, and
  `run-test-ios-15-and-14`.
- `generate_revenuecatui_snapshots` workflow → steps in
  `spm-revenuecat-ui-ios-16`, `run-revenuecat-ui-ios-18-and-17`, and
  `run-revenuecat-ui-ios-26`.

Normal CI runs are unchanged. SPM release builds in jobs that are never
invoked by a snapshot-generation workflow (`revenuecat-admob-tests`,
`spm-receipt-parser`) are left untouched.

Made-with: Cursor via Antonio Pallares
* Fix iOS 15 snapshot-generation job hanging indefinitely (#6658)

* Skip StoreKit tests on iOS 15 when generating snapshots

During snapshot-generation pipelines, `run-test-ios-15-and-14` has been
observed to sometimes run indefinitely in an infinite loop: the first
test from a `StoreKitConfigTestCase`-derived class stalls inside
`setUp`, hits the test plan's 180s `maximumTestExecutionTimeAllowance`,
and xcodebuild's built-in runner-crash recovery then retries the same
tests and stalls again.

Skipping SK tests on iOS 15 in this mode costs no snapshot coverage:
the only snapshot-producing test in the StoreKit test target is
`DebugViewSwiftUITests`, which is `@available(iOS 16.0, *)` and is
recorded by the iOS 16+ jobs.

Made-with: Cursor

* [TEMP] Log skip_sk_tests resolution in test_ios

Temporary debug logging to verify that the CircleCI pipeline parameter
`<< pipeline.parameters.generate_snapshots >>` is correctly interpolated
into `skip_sk_tests` and coerced to a Ruby boolean by Fastlane's CLI
parser. To be reverted once verified.

Made-with: Cursor

* [TEMP] Only run run-test-ios-15-and-14 in generate-snapshot workflow

Temporarily disable the other jobs in the `generate-snapshot` workflow
so snapshot-generation pipelines only trigger `run-test-ios-15-and-14`,
letting us verify the `skip_sk_tests` fix without paying for the full
snapshot matrix. To be reverted once verified.

Made-with: Cursor

* Revert "[TEMP] Only run run-test-ios-15-and-14 in generate-snapshot workflow"

This reverts commit a1232661755b3ba9569204b3ea7c2b3dc6c2e19c.

* Revert "[TEMP] Log skip_sk_tests resolution in test_ios"

This reverts commit 5cfeb3aafda107ffd733ea37e5525b0dcd60c136.

* Add 10-minute hard timeout to iOS 15 tests step

Defensive safety net in case an infinite-retry scenario ever recurs:
`no_output_timeout` does not fire there because xcodebuild keeps
emitting output every retry. A shell-level `timeout 10m` guarantees
the step fails within 10 minutes instead of consuming the full 5h
CircleCI job timeout.

Made-with: Cursor

* Revert "Add 10-minute hard timeout to iOS 15 tests step"

This reverts commit 315c8022162d6d3165e78dd9696c3d5c98acdf20. via Antonio Pallares
* Clip carousel pages to prevent neighbor paint bleed (PWENG-36) (#6657) via Monika Mateska
* Add workflows network layer for multipage paywalls (#6557)

* Add workflows network layer for multipage paywalls

- Add `getWorkflows` and `getWorkflow` endpoint paths
- Add `WorkflowsListResponse` and `PublishedWorkflow` response models
- Add `WorkflowDetailProcessor` to handle `inline`/`use_cdn` response actions
- Add `WorkflowCdnFetcher` protocol and `DirectWorkflowCdnFetcher` implementation
- Add `GetWorkflowsOperation` and `GetWorkflowOperation` cacheable network operations
- Add `WorkflowsAPI` facade and wire into `Backend`
- Add unit tests for all new components

iOS equivalent of https://github.com/RevenueCat/purchases-android/pull/3300

Made-with: Cursor

* fix xcodeproj

* reset Package.resolved

* Update WorkflowStep models to match actual backend response

- Add WorkflowTrigger struct (name, type, action_id, component_id)
- Add triggers, outputs, and metadata fields to WorkflowStep
- Add metadata field to PublishedWorkflow
- Remove value field from WorkflowTriggerAction (backend uses step_id only)

Made-with: Cursor

* Update WorkflowResponseTests to match updated models

- Replace value/resolvedTargetStepId assertions with stepId
- Remove testDecodeWorkflowTriggerActionValueTakesPrecedence (value field removed)
- Add testDecodeWorkflowTrigger for new WorkflowTrigger struct
- Add testDecodePublishedWorkflowWithMetadata
- Update testDecodeWorkflowStepDefaults to cover triggers, outputs, metadata
- Add testDecodeWorkflowStepMatchingActualBackendResponse with real backend payload

Made-with: Cursor

* Disable file_length lint rule in HTTPRequestPath.swift

Made-with: Cursor

* Fix GetWorkflowOperation to compute result once before distributing to callbacks

CDN fetch and JSON decoding were running once per deduplicated callback.
Compute the Result<WorkflowFetchResult, BackendError> once outside the
performOnAllItemsAndRemoveFromCache loop, matching the pattern used by
GetOfferingsOperation and other operations in the codebase.

Made-with: Cursor

* Fix CDN fetcher: use URLSession instead of Data(contentsOf:), classify errors correctly

- Replace Data(contentsOf:) with URLSession.shared.dataTask + DispatchSemaphore
  in DirectWorkflowCdnFetcher; gets URLSession timeout, HTTP status validation,
  and proper network stack semantics
- Add WorkflowDetailProcessingError.cdnFetchFailed typed error so CDN I/O
  failures are distinguishable from envelope parsing failures
- Catch cdnFetchFailed in GetWorkflowOperation and map to NetworkError.networkError
  instead of NetworkError.decoding, fixing misleading error classification
- Update WorkflowDetailProcessorTests to assert the typed error is thrown

Made-with: Cursor

* Replace semaphore CDN fetch with async/await using withCheckedThrowingContinuation

- Make WorkflowCdnFetcher.fetchCompiledWorkflowData async throws; use
  withCheckedThrowingContinuation to bridge URLSession.dataTask into async,
  avoiding any thread-blocking
- Make WorkflowDetailProcessor.process async throws to propagate async
- Bridge into async in GetWorkflowOperation via Task {}; completion() is
  called inside the Task after CDN fetch and decoding complete
- Update WorkflowDetailProcessorTests to async throws with await

Made-with: Cursor

* Make CDN fetcher and processor completion-handler based for consistency

Avoids Task{} in GetWorkflowOperation and keeps all operations calling
completion() synchronously from within the HTTP callback, matching every
other operation in the codebase.

- WorkflowCdnFetcher.fetchCompiledWorkflowData now takes a completion handler;
  DirectWorkflowCdnFetcher uses URLSession.dataTask (non-blocking, no semaphore)
- WorkflowDetailProcessor.process now takes a completion handler; inline action
  completes synchronously, use_cdn fans out to the fetcher callback
- GetWorkflowOperation splits into getWorkflow/handleResponse/backendResult/
  distribute helpers to stay within line-length limits
- WorkflowDetailProcessorTests updated to use waitUntilValue pattern

Made-with: Cursor

* Fix ambiguous cache key delimiter in GetWorkflowOperation

Space-separated appUserID+workflowId could collide (e.g. user 'a b' + workflow 'c'
== user 'a' + workflow 'b c'). Use newline as delimiter, matching the precedent
set by GetWebBillingProductsOperation.

Made-with: Cursor

* PR comments

* remove cdn fetcher

* fix response in BackendGetWorkflowsTests.swift

* fix WorkflowResponseTests

* fix error

* [skip ci] Generating new test snapshots (#6584)

* [skip ci] Generating new test snapshots (#6585)

* [skip ci] Generating new test snapshots (#6586)

* [skip ci] Generating new test snapshots (#6587)

* [skip ci] Generating new test snapshots (#6588)

* [skip ci] Generating new test snapshots (#6589)

* [skip ci] Generating new test snapshots (#6590)

* Test CDN mock is not re-assignable per test

* [skip ci] Generating new test snapshots (#6597)

* [skip ci] Generating new test snapshots (#6598)

* [skip ci] Generating new test snapshots (#6599)

* [skip ci] Generating new test snapshots (#6600)

* [skip ci] Generating new test snapshots (#6601)

* [skip ci] Generating new test snapshots (#6602)

* [skip ci] Generating new test snapshots (#6603)

* getWorkflow is signed

* add type parameter

* add response verification for CDN response

* remove workflows list

* add value to WorkflowTriggerAction

* step id

* hash and filerepo

* missingCdnHash

* linter and project

* fix project

* revert Package.resolved

* @unchecked Sendable

* use hash in generateOrGetCachedFileURL

* fix compilation

* skip responseVerificationMode in cdn

* change basePath of caches

* remove reserialization

* Use explicit type in GetWorkflowOperation.createFactory for greppability

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>

* Fix swiftlint identifier_name violation in WorkflowDetailProcessorTests

Rename short variable `d` to `doubleValue` in two `if case .double(let d)`
patterns to satisfy the identifier_name rule requiring names >= 3 characters.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>

* remove default FileRepositoryType

* fix project

* fix test

* test preserves camel case

* Generating new test snapshots for `feat/workflows-network-layer` - ios-15 (#6654)

* Generating new test snapshots for `feat/workflows-network-layer` - ios-14 (#6656)

---------

Co-authored-by: RevenueCat Git Bot <72824662+RCGitBot@users.noreply.github.com>
Co-authored-by: Facundo Menzella <facumenzella@gmail.com>
Co-authored-by: Claude Sonnet 4.6 <noreply@anthropic.com>
Co-authored-by: Facundo Menzella <facumenzella@users.noreply.github.com> via Cesar de la Vega
* Bump fastlane-plugin-revenuecat_internal from `e348913` to `b822f01` (#6651)

Bumps [fastlane-plugin-revenuecat_internal](https://github.com/RevenueCat/fastlane-plugin-revenuecat_internal) from `e348913` to `b822f01`.
- [Release notes](https://github.com/RevenueCat/fastlane-plugin-revenuecat_internal/releases)
- [Commits](https://github.com/RevenueCat/fastlane-plugin-revenuecat_internal/compare/e3489134d424f8bea249ddc78d5f1e4b2801b302...b822f01c0ed359a9592c088def3ef3a4a3447045)

---
updated-dependencies:
- dependency-name: fastlane-plugin-revenuecat_internal
  dependency-version: b822f01c0ed359a9592c088def3ef3a4a3447045
  dependency-type: direct:production
...

Signed-off-by: dependabot[bot] <support@github.com>
Co-authored-by: dependabot[bot] <49699333+dependabot[bot]@users.noreply.github.com> via dependabot[bot]
* Use env-var interpolation in rcgitbot_please_test workflow (#6649)

* Use env-var interpolation in rcgitbot_please_test workflow

Made-with: Cursor

* Simplify author_association gate and add curl timeout

Made-with: Cursor

* Add deny-all workflow-level permissions baseline

Made-with: Cursor

* Simplify comments

* Don't log COMMENT_USER value on validation failure

Made-with: Cursor

* Drop redundant org-membership curl in favor of author_association gate

Made-with: Cursor via Antonio Pallares
* Expose `apiKey` on `Purchases` via `@_spi(Internal)` (#6635)

Adapter modules that import the SDK with `@_spi(Internal) import RevenueCat`
(e.g. `RevenueCatAdMob`) need to read the configured public API key when
constructing payloads such as the AdMob SSV `customRewardString`.

- Store the API key on `SystemInfo` and wire it through `Purchases` init.
- Add `@_spi(Internal) public var apiKey: String` on `Purchases`.
- Add a Swift API tester case so any future signature change is caught.
- Add a unit test verifying the accessor returns the configured key.

The key is already public plaintext in the app binary, so exposing it as SPI
does not introduce any new security risk. via Pol Miro
* Replace fatalError with assertionFailure + throw for fallbackHeader in ViewModelFactory (#6636)

fatalError would crash production apps if the filter ever fails. assertionFailure
catches the invariant violation in debug/tests while TemplateError.unexpectedComponent
allows the paywall to fail gracefully in release builds.

Co-authored-by: Claude Sonnet 4.6 <noreply@anthropic.com> via Facundo Menzella
* Bump fastlane from 2.232.2 to 2.233.0 (#6639)

Bumps [fastlane](https://github.com/fastlane/fastlane) from 2.232.2 to 2.233.0.
- [Release notes](https://github.com/fastlane/fastlane/releases)
- [Changelog](https://github.com/fastlane/fastlane/blob/master/CHANGELOG.latest.md)
- [Commits](https://github.com/fastlane/fastlane/compare/fastlane/2.232.2...fastlane/2.233.0)

---
updated-dependencies:
- dependency-name: fastlane
  dependency-version: 2.233.0
  dependency-type: direct:production
  update-type: version-update:semver-minor
...

Signed-off-by: dependabot[bot] <support@github.com>
Co-authored-by: dependabot[bot] <49699333+dependabot[bot]@users.noreply.github.com> via dependabot[bot]
* Bump fastlane-plugin-revenuecat_internal from `a1eed48` to `e348913` (#6638)

Bumps [fastlane-plugin-revenuecat_internal](https://github.com/RevenueCat/fastlane-plugin-revenuecat_internal) from `a1eed48` to `e348913`.
- [Release notes](https://github.com/RevenueCat/fastlane-plugin-revenuecat_internal/releases)
- [Commits](https://github.com/RevenueCat/fastlane-plugin-revenuecat_internal/compare/a1eed48467a057a8bbdac5a0587e3653a541a46b...e3489134d424f8bea249ddc78d5f1e4b2801b302)

---
updated-dependencies:
- dependency-name: fastlane-plugin-revenuecat_internal
  dependency-version: e3489134d424f8bea249ddc78d5f1e4b2801b302
  dependency-type: direct:production
...

Signed-off-by: dependabot[bot] <support@github.com>
Co-authored-by: dependabot[bot] <49699333+dependabot[bot]@users.noreply.github.com> via dependabot[bot]
* Add @RCGitBot please test <job-name> on-demand job trigger (#6607)

* Migrate CircleCI to dynamic configuration

Split config.yml into a setup config (config.yml) and a continuation
config (continue_config.yml). The setup config runs on a lightweight
Linux executor, forwards all pipeline parameters, then continues to
the full config. This enables path-based filtering for future jobs.

Requires enabling "Dynamic Configuration" in CircleCI project settings.

Made-with: Cursor

* Add @RCGitBot please test <job-name> on-demand job trigger

Extend the dynamic config setup to support running individual CircleCI
jobs on-demand via PR comments. When someone comments
"@RCGitBot please test <job-name>" on a PR:

1. GitHub Action verifies org membership, parses the job name, and
   triggers a CircleCI pipeline with the requested_job parameter.
2. The setup config validates the job exists in continue_config.yml,
   generates a minimal continuation config with only that job, and
   continues the pipeline.
3. A comment is posted with a link to the triggered pipeline.

The existing "@RCGitBot please test" (no job name) behavior for
approving the full test suite is unchanged.

Made-with: Cursor

* Declare requested_job parameter in continue_config.yml

CircleCI validates pipeline parameters against both the setup and
continuation configs. When requested_job is passed via the API, the
continuation config must also declare it or CircleCI rejects it with
"Unexpected argument(s): requested_job".

Made-with: Cursor

* Simplify on-demand job trigger: support multiple jobs, add blocklist

- Replace Python script with plain shell for on-demand config generation
- Replace Python parameter forwarding with a JSON heredoc
- Support multiple jobs separated by spaces or commas
- Add blocklist for release/deployment jobs
- Rename requested_job parameter to requested_jobs
- Update GitHub Action to parse and pass multiple job names

Made-with: Cursor

* Remove mirrored parameters from setup config to fix API trigger conflict

Pipeline parameters declared in both config.yml and continue_config.yml
cause a "Conflicting pipeline parameters" error when triggered via API
with non-default values. Since continue_config.yml declares them, they
flow through automatically — no need to mirror or forward them.

Made-with: Cursor

* Extract on-demand job logic to external script with allowlist

Move the on-demand config generation from inline in config.yml to
.circleci/generate-on-demand-config.sh. Switch from a blocklist to
a conservative allowlist of jobs that can be triggered on-demand.

Made-with: Cursor

* Redesign pipeline parameters: public in config.yml, internal in continue_config.yml

config.yml now owns all API/UI-facing parameters:
- action enum (expanded with generate_snapshots, generate_revenuecatui_snapshots,
  generate_swiftinterface cases)
- GHA_* strings (accepted for GitHub Action triggers, not forwarded)

continue_config.yml uses internal _ prefixed parameters (_action,
_generate_snapshots, etc.) to avoid "Conflicting pipeline parameters"
errors when API-triggered values differ from defaults.

A new forward-parameters.sh script maps the public action enum to
the internal parameters, deriving booleans from action cases.

Made-with: Cursor

* Rename internal pipeline parameters from _ to internal_ prefix

The _ prefix may cause issues with CircleCI's parameter handling.
Renaming to internal_ for clarity and compatibility.

Made-with: Cursor

* Declare public parameters in continue_config.yml for API passthrough

CircleCI forwards all API-triggered parameters to the continuation
config. Without matching declarations, the continuation is rejected
with "Unexpected argument(s)". These parameters are not referenced
by any workflow — only the internal_* versions are used.

Made-with: Cursor

* Remove internal_action, use action parameter directly

CircleCI implicitly forwards API-triggered parameters to the
continuation config, so action can be used directly (as type: string)
instead of maintaining a separate internal_action mapping.
forward-parameters.sh now only outputs the derived boolean flags.

Made-with: Cursor

* Remove unused tuist action enum case

Made-with: Cursor

* Unify pipeline parameters across setup and continuation configs

All parameters are now declared identically in both config.yml and
continue_config.yml, relying on CircleCI's implicit forwarding.
This eliminates the need for forward-parameters.sh and the
internal_* naming indirection.

The setup job now simply continues to continue_config.yml with no
explicit parameter passing.

Made-with: Cursor

* Rename on-demand config script to generate-requested-jobs-config

Made-with: Cursor

* Sort allowed jobs list alphabetically, one per line

Made-with: Cursor

* Update comments to reflect unified parameter setup

Made-with: Cursor

* Fix actionlint: pass comment body via env var to avoid script injection

Made-with: Cursor

* Rename approve_full_tests.yml to rcgitbot_please_test.yml

Made-with: Cursor

* Update workflow name to match new filename

Made-with: Cursor

* Apply main branch changes to continue_config.yml

- Remove create_snapshots_repo_pr calls (moved to create_snapshot_pr)
- Add record-and-upload-paywalls-v1-snapshots job and workflow entries
- Rename run_maestro_e2e_tests to run_maestro_e2e_tests_ios

Made-with: Cursor

* Rename continue_config.yml to default_config.yml

Made-with: Cursor

* Move requested jobs script into when block

The script only needs to run when requested_jobs is set, which is
already gated by the when condition at config compilation time.

Made-with: Cursor

* Remove requested_jobs parameter from default_config.yml

This parameter is only needed for the on-demand job trigger feature
(PR #6607), not for the base dynamic config migration.

Made-with: Cursor

* Add requested_jobs parameter to default_config.yml

Required for CircleCI implicit parameter forwarding when
the on-demand job trigger is used via config.yml.

Made-with: Cursor

* Restore original GHA_* parameters comment with marketplace link

Made-with: Cursor

* Remove run-manual-tests action

run-all-tests already triggers on every PR branch push, and
release-or-main covers main/release branches. The run-manual-tests
action provided no unique functionality.

Made-with: Cursor

* Make GHA comment and parameter ordering consistent across configs

Made-with: Cursor

* Review fixes: trim comment check, update allowlist, add e2e-tests context

- Trim comment body before exact match in approve-full-tests to
  prevent edge case where trailing whitespace triggers both jobs
- Remove loadshedder-integration-tests-old-major (requires parameter)
  and record-and-push-paywall-template-screenshots from allowlist
- Add e2e-tests context alongside slack-secrets for on-demand jobs

Made-with: Cursor

* Revert trim() — not a valid GitHub Actions expression function

Made-with: Cursor

* Remove danger from on-demand jobs allowlist

Made-with: Cursor

* Remove comma support from requested jobs parsing

Only spaces are allowed as job name separators for simplicity.

Made-with: Cursor

* Fix outdated comment referencing comma-separated jobs

Made-with: Cursor

* Pass requested_jobs via environment variable to prevent shell injection

CircleCI does raw text substitution of pipeline parameters before
bash parses the command. Passing through an environment block ensures
the value is treated as data, not shell syntax.

Made-with: Cursor

* Rewrite generate-requested-jobs-config in JavaScript

Easier to read and maintain than the shell version. The cimg/base
executor includes Node.js, so no additional setup is needed.

Made-with: Cursor

* Use cimg/node:current for setup job

The JS script requires Node.js, which is available in cimg/node.

Made-with: Cursor

* Add tag filter to setup workflow to fix release deployments

Without explicit tag filters, CircleCI skips workflows on tag pushes.
This would prevent the setup job from running on release tags,
breaking the entire deploy-tag workflow in default_config.yml.

Made-with: Cursor

* TEMPORARY: Add test-tag workflow to verify tag propagation

Will be removed before merging.

Made-with: Cursor

* Remove temporary test-tag workflow and alias

Tag propagation through dynamic config verified successfully.

Made-with: Cursor

* Map each on-demand job to the contexts it needs

Replace the flat allowlist with a map of job name to required CircleCI
contexts, so each on-demand run gets the same contexts as the regular
run in default_config.yml (no more, no less).

Made-with: Cursor

* Make YAML indentation visible in the source

Use multi-line template literals so the generated YAML structure is
readable in the source code.

Made-with: Cursor

* Revert multi-line template literals

Made-with: Cursor

* Lowercase comment before stripping prefix to match GHA startsWith case-insensitivity

Made-with: Cursor via Antonio Pallares
* Migrate CircleCI to dynamic configuration (#6605)

* Migrate CircleCI to dynamic configuration

Split config.yml into a setup config (config.yml) and a continuation
config (continue_config.yml). The setup config runs on a lightweight
Linux executor, forwards all pipeline parameters, then continues to
the full config. This enables path-based filtering for future jobs.

Requires enabling "Dynamic Configuration" in CircleCI project settings.

Made-with: Cursor

* Redesign pipeline parameters: public in config.yml, internal in continue_config.yml

config.yml now owns all API/UI-facing parameters:
- action enum (expanded with generate_snapshots, generate_revenuecatui_snapshots,
  generate_swiftinterface cases)
- GHA_* strings (accepted for GitHub Action triggers, not forwarded)

continue_config.yml uses internal _ prefixed parameters (_action,
_generate_snapshots, etc.) to avoid "Conflicting pipeline parameters"
errors when API-triggered values differ from defaults.

A new forward-parameters.sh script maps the public action enum to
the internal parameters, deriving booleans from action cases.

Made-with: Cursor

* Rename internal pipeline parameters from _ to internal_ prefix

The _ prefix may cause issues with CircleCI's parameter handling.
Renaming to internal_ for clarity and compatibility.

Made-with: Cursor

* Declare public parameters in continue_config.yml for API passthrough

CircleCI forwards all API-triggered parameters to the continuation
config. Without matching declarations, the continuation is rejected
with "Unexpected argument(s)". These parameters are not referenced
by any workflow — only the internal_* versions are used.

Made-with: Cursor

* Remove internal_action, use action parameter directly

CircleCI implicitly forwards API-triggered parameters to the
continuation config, so action can be used directly (as type: string)
instead of maintaining a separate internal_action mapping.
forward-parameters.sh now only outputs the derived boolean flags.

Made-with: Cursor

* Remove unused tuist action enum case

Made-with: Cursor

* Unify pipeline parameters across setup and continuation configs

All parameters are now declared identically in both config.yml and
continue_config.yml, relying on CircleCI's implicit forwarding.
This eliminates the need for forward-parameters.sh and the
internal_* naming indirection.

The setup job now simply continues to continue_config.yml with no
explicit parameter passing.

Made-with: Cursor

* Update comments to reflect unified parameter setup

Made-with: Cursor

* Apply main branch changes to continue_config.yml

- Remove create_snapshots_repo_pr calls (moved to create_snapshot_pr)
- Add record-and-upload-paywalls-v1-snapshots job and workflow entries
- Rename run_maestro_e2e_tests to run_maestro_e2e_tests_ios

Made-with: Cursor

* Rename continue_config.yml to default_config.yml

Made-with: Cursor

* Remove requested_jobs parameter from default_config.yml

This parameter is only needed for the on-demand job trigger feature
(PR #6607), not for the base dynamic config migration.

Made-with: Cursor

* Restore original GHA_* parameters comment with marketplace link

Made-with: Cursor

* Remove run-manual-tests action

run-all-tests already triggers on every PR branch push, and
release-or-main covers main/release branches. The run-manual-tests
action provided no unique functionality.

Made-with: Cursor

* Make GHA comment and parameter ordering consistent across configs

Made-with: Cursor

* Add tag filter to setup workflow to fix release deployments

Without explicit tag filters, CircleCI skips workflows on tag pushes.
This would prevent the setup job from running on release tags,
breaking the entire deploy-tag workflow in default_config.yml.

Made-with: Cursor

* TEMPORARY: Add test-tag workflow to verify tag propagation

Will be removed before merging.

Made-with: Cursor

* Remove temporary test-tag workflow and alias

Tag propagation through dynamic config verified successfully.

Made-with: Cursor via Antonio Pallares
* Bump fastlane from 2.229.1 to 2.232.2 and fix Mac Catalyst archive export (#6370)

* Bump fastlane from 2.229.1 to 2.232.2

Bumps [fastlane](https://github.com/fastlane/fastlane) from 2.229.1 to 2.232.2.
- [Release notes](https://github.com/fastlane/fastlane/releases)
- [Changelog](https://github.com/fastlane/fastlane/blob/master/CHANGELOG.latest.md)
- [Commits](https://github.com/fastlane/fastlane/compare/fastlane/2.229.1...fastlane/2.232.2)

---
updated-dependencies:
- dependency-name: fastlane
  dependency-version: 2.232.2
  dependency-type: direct:production
  update-type: version-update:semver-minor
...

Signed-off-by: dependabot[bot] <support@github.com>

* fix: add explicit catalyst_platform to fix Mac Catalyst archive export

Fastlane 2.230.0 (via fastlane/fastlane#22145) changed gym's runner
to use complementary building_for_ipa?/building_for_pkg? checks instead
of the non-complementary building_for_ios?/building_for_mac?. This forces
Mac Catalyst builds without an explicit catalyst_platform into the IPA
export path, causing "No signing certificate Mac Installer Distribution
found" errors.

Fix by explicitly passing catalyst_platform: "macos" to gym and
additional_cert_types: "mac_installer_distribution" to match for
the catalyst build.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

---------

Signed-off-by: dependabot[bot] <support@github.com>
Co-authored-by: dependabot[bot] <49699333+dependabot[bot]@users.noreply.github.com>
Co-authored-by: Antonio Pallares <antonio.pallares@revenuecat.com>
Co-authored-by: Claude Opus 4.6 <noreply@anthropic.com> via dependabot[bot]
* Add automated GitHub releases for purchases-ios-admob (#6537)

* Add automated GitHub releases for purchases-ios-admob

Add a new `admob_github_release` Fastlane lane that generates a changelog
filtered by the `pr:admob` label and creates a GitHub release on the
purchases-ios-admob repository.

Wire it into the CI release workflow as a new `make-admob-release` job
that runs after `deploy-to-purchases-ios-admob`.

* Update fastlane plugin to main and use new filter_labels/exclude_labels API

- Point fastlane-plugin-revenuecat_internal to main (branch merged)
- Rename filter_label to filter_labels (array) for admob changelog
- Exclude pr:admob PRs from purchases-ios changelog via exclude_labels

* fix: remove deploy-to-purchases-ios-admob from make-release requires

The main SDK release should not be gated on the admob adapter deployment.

* Resolve correct commitish from purchases-ios-admob for GitHub release

Fetch the tag's commit SHA from purchases-ios-admob via the GitHub API
and pass it as commitish, instead of using the local purchases-ios HEAD
which doesn't exist in that repo.

* test: temporary CI workflow to validate admob release lane

* Revert "test: temporary CI workflow to validate admob release lane"

This reverts commit 2edfdccb952e181a8fdc21cf502bd67c87c7af6c.

* ci: run make-admob-release on ruby docker executor

Co-authored-by: Pol Miro <polmiro@users.noreply.github.com>

* Include pr:admob entries in main changelog generation.

Removes the bump lane exclusion so admob-labeled PRs remain visible in purchases-ios release notes for traceability.

* Use cross-repo PR references in admob release changelog.

Passes purchases-ios as the PR reference source so changelog links in purchases-ios-admob releases resolve to the correct repository.

---------

Co-authored-by: Cursor Agent <cursoragent@cursor.com>
Co-authored-by: Pol Miro <polmiro@users.noreply.github.com> via Pol Miro
* Move RevenueCatUIDev.xctestplan out of RevenueCatUI target to fix SPM unhandled-file warning (#6625) via Rick
* Add missing source files to RevenueCat.xcodeproj (#6624)

* Add missing source files to RevenueCat.xcodeproj

* Move ButtonComponentViewModelInteractionTests to RevenueCatUITestsDev target via Rick
* Update backend integration test snapshots (#6632)

* Placeholder: combine backend integration test snapshot updates

* [skip ci] Generating new test snapshots (#6626)

* [skip ci] Generating new test snapshots (#6627)

* [skip ci] Generating new test snapshots (#6628)

* [skip ci] Generating new test snapshots (#6629)

* [skip ci] Generating new test snapshots (#6630)

---------

Co-authored-by: RevenueCat Git Bot <72824662+RCGitBot@users.noreply.github.com> via Rick
* UI events for paywall component interactions (#6523)

* Initial setup for paywall control interaction events for v2 paywalls (PWENG-9)

* Use tabs container name for component_name and tab name for component_value (PWENG-9)

* Use tabs container name for tab and toggle control interaction (PWENG-9)

* Introduce paywall control interaction events for legacy paywalls (PWENG-9)

* Align documented code (PWENG-9)

* Fix tvOS 13 build by replacing TapGesture with onTapGesture in FooterView (PWENG-9)

* Fix RevenueCatUITests build by inlining JSON in ToPresentedOverridesTests (PWENG-9)

* Nest paywall control interaction type as PaywallEvent.ControlType (PWENG-9)

* Add componentURL to paywall control interaction events (PWENG-9)

* Add text control type for paywall markdown link analytics (PWENG-9)

* Only track carousel interactions for user drags (PWENG-9)

* Open footer links via OpenURLAction with Link on macOS (PWENG-9)

* Updated documentation for the tab control type (PWENG-9)

* Omit nil name/transition when encoding ButtonComponent (PWENG-9)

* Fix lint errors (PWENG-9)

* Track footer restore tap before restore interceptor (PWENG-9)

* Add CodingKeys for componentUrl in control interaction events (PWENG-9)

* Revert "Add CodingKeys for componentUrl in control interaction events (PWENG-9)"

This reverts commit 57a7525ccabfcd42bca5550b80bff8a060133c29.

* Update the control type as a stand-alone enum (PWENG-9)

* Remove trivial unit tests (PWENG-9)

* Update baseline swiftinterface files for `monika/UI-events/paywall-control-interaction` (#6528)

* Remove trivial unit tests (PWENG-9)

* [skip ci] Update baseline swiftinterface files

---------

Co-authored-by: Monika Mateska <monika.mateska@revenuecat.com>
Co-authored-by: Monika Mateska <45938914+MonikaMateska@users.noreply.github.com>

* Use a fitting parameter name (PWENG-9)

* Track navigation metadata for control interactions

Add navigation metadata (originIndex, destinationIndex, originContextName, destinationContextName, defaultIndex) to paywall control interactions and propagate them through the codebase. Updated PurchaseHandler.trackControlInteraction signature and PaywallEvent.ControlInteractionData to include the new fields and include them in event serialization (FeatureEventsRequest, FeatureEvent map). Updated UI components to populate navigation info: Carousel now reports origin/destination/default page indices and page context names; Tabs now carries tab names/context mapping, initial/default index and reports origin/destination info on selection. Paywall component models now include optional `name` for StackComponent and Tab. Tests and swiftinterface API files were updated accordingly.

* Add PaywallEventTracker and control logger

Introduce PaywallEventTracker to centralize paywall event tracking and provide a lightweight ControlInteractionLogger environment key for views. Refactor PurchaseHandler to delegate event logic to PaywallEventTracker and wire the controlInteractionLogger into paywall views and components (replacing direct PurchaseHandler calls). Update event discriminator from "paywall_control_interaction" to "paywall_component_interacted" and adjust related networking and event mapping. Add unit/UI tests for PaywallEventTracker and ControlInteractionLogger and remove redundant control-interaction tests from PurchaseHandlerTests. Includes background event dispatcher wiring and minor view adjustments to use the new logger.

* Rename control interaction to component interaction

Replace "control"-centric interaction names with "component"-centric ones across the paywall UI and event pipeline. This updates types, methods, environment keys and loggers (e.g. ControlInteraction -> ComponentInteraction), event payload fields and networking mapping, and updates all unit/UITests to match. This standardizes terminology for component interactions (tabs, carousels, buttons, text links) and adjusts the event tracking surface accordingly — note this is a breaking rename for any external API/consumers referencing the old identifiers.

* Rename ControlInteraction to ComponentInteraction

Rename PaywallEvent control interaction API: replace case `controlInteraction` with `componentInteraction`, `ControlInteractionData` with `ComponentInteractionData`, and the `controlInteractionData` property with `componentInteractionData` across platform swiftinterface files (iOS, macOS, tvOS, visionOS, watchOS and their simulators). Updates equality, codable/sendable conformance and encoder/decoder signatures to match the new type name for consistency and clearer naming.

* Use shared PaywallEventTracker instance

Add a private PaywallEventTracker property to PaywallView and PaywallsV2View and pass its componentInteractionLogger into the environment instead of creating a new PaywallEventTracker inline. This ensures a single tracker instance is used for component interaction logging within each view, avoiding ephemeral tracker creation and keeping tracking state consistent.

* Use shared PaywallEventTracker & inject tracker

Add a singleton PaywallEventTracker.shared and wire it into UI and purchasing code. Replace local tracker instances in paywall views with PaywallEventTracker.shared.componentInteractionLogger, and update PurchaseHandler to accept an injectable PaywallEventTracker (defaulting to .shared). Update test helpers and mocks to construct and pass explicit eventTracker instances, adjust LoadingPaywallView test setup to provide a dedicated tracker, and add new source/test files to the Xcode project file. These changes allow deterministic event-tracking in tests and avoid duplicated tracker instances at runtime.

* Remove convenience trackComponentInteraction overload

Remove the parameter-based convenience overload of PaywallEventTracker.trackComponentInteraction and consolidate usage to the single method that accepts PaywallEvent.ComponentInteractionData. Update unit tests to construct ComponentInteractionData via its initializer and call trackComponentInteraction(data) accordingly. This removes duplicated API surface and centralizes event construction.

* Remove EventDispatcher from PurchaseHandler

Remove the EventDispatcher abstraction and related properties from PurchaseHandler: delete the EventDispatcher typealias, backgroundEventDispatcher and testEventDispatcher, and the eventDispatcher stored property and init parameter. Update mapping helpers to stop propagating an eventDispatcher. Update tests and test helpers to pass inline Task { await work() } closures where needed. Files changed: PurchaseHandler.swift, PurchaseHandler+TestData.swift, and related tests in Tests/RevenueCatUITests/Purchasing.

* add name to stack partial

* Update PaywallAPI.swift

* Add testEventDispatcher back to tests

Introduce PaywallEventTracker.testEventDispatcher that uses Task { } (non-detached) so test events inherit caller context and aren't deprioritized by Task.detached(priority: .background) on iOS 26+ CI. Update PurchaseHandler test data and unit tests to pass this test dispatcher when constructing the event tracker to ensure prompt event delivery in tests.

* Add plan-selection metadata to paywall component interaction events

* Add package-selection sheet tracking (PWENG-15)

* [skip ci] Update baseline swiftinterface files (#6564)

* Route paywall control analytics through ComponentInteractionData factories (PWENG-15)

* [skip ci] Update baseline swiftinterface files (#6565)

* Make PaywallEventTracker thread-safe with locked state (PWENG-15)

* Clarify unknown button action telemetry as diagnostics (PWENG-15)

* Isolate paywall analytics state per session in shared tracker (PWENG-15)

* Fix swiftlint issues (PWENG-15)

* Prune PaywallEventTracker session state (PWENG-15)

* Fix ) SPM RevenueCatUl Tests

* Move paywall test event dispatcher out of RevenueCatUI production code (PWENG-15)

* Add purchase button interaction tracking (#6575)

* Add purchase button interaction tracking

Add tracking for purchase button taps: introduce ComponentInteractionType.purchaseButton and a paywallPurchaseButtonAction factory that captures componentName, componentValue, componentURL, currentPackageIdentifier and currentProductIdentifier. Expose componentName and customWebCheckoutUrl on the PurchaseButton view model and log the interaction from PurchaseButtonComponentView before initiating the purchase. Extend PurchaseButtonComponent to include an optional name and make Method conform to CustomStringConvertible to provide stable string values for logging. Update previews to include the new name field where applicable.

Co-Authored-By: Monika Mateska <45938914+MonikaMateska@users.noreply.github.com>

* Use context-aware web checkout URL

Replace direct use of viewModel.customWebCheckoutUrl with viewModel.urlForWebCheckout(packageContext: packageContext)?.url when logging the purchase button interaction. This ensures the logged componentURL is derived using the current package context (if available) and pulls the URL from the computed web checkout result rather than the raw custom value.

Co-Authored-By: Monika Mateska <45938914+MonikaMateska@users.noreply.github.com>

* Add tests for purchase button interactions

Add comprehensive tests covering paywall purchase button behavior across components and tracking.

- Tests/RevenueCatUITests/Purchasing/ControlInteractionLoggerTests.swift: add factory tests for PaywallEvent.ComponentInteractionData.paywallPurchaseButtonAction (componentType, name, value, URL, current package/product identifiers, and fully-populated case).
- Tests/RevenueCatUITests/Purchasing/PaywallEventTrackerTests.swift: add tracker tests to ensure component interaction events include purchase button metadata and handle nil name/no-package cases.
- Tests/UnitTests/Paywalls/Components/PurchaseButtonComponentTests.swift: add decoding tests for name present/absent, include name:nil in expected models, add Method.description tests and ComponentInteractionType raw value test.

These tests validate decoding, description strings, raw values, and that tracking records the expected purchase button metadata.

Co-Authored-By: Monika Mateska <45938914+MonikaMateska@users.noreply.github.com>

* Include name in PurchaseButtonComponent eq/hash

Add `name` to the PurchaseButtonComponent Hashable and Equatable implementations. This ensures instances with different `name` values produce distinct hashes and are not considered equal, preventing incorrect comparisons or collection behavior.

Co-Authored-By: Monika Mateska <45938914+MonikaMateska@users.noreply.github.com>

* [skip ci] Update baseline swiftinterface files (#6577)

---------

Co-authored-by: Monika Mateska <45938914+MonikaMateska@users.noreply.github.com>
Co-authored-by: RevenueCat Git Bot <72824662+RCGitBot@users.noreply.github.com>

* Route paywall component interaction logger through PurchaseHandler (PWENG-15)

* Log V1 purchase button component interactions (PWENG-30)

* Consolidate ComponentInteractionData factory extensions (PWENG-15)

* Defer Paywalls V2 purchase button analytics until checkout is resolved (PWENG-30)

* Fix lint issue (PWENG-15)

* Use NSLock.withLock instead of custom perform (PWENG-15)

* Fix failing test (PWENG-15)

* Fix failing tests (PWENG-15)

* Log Paywalls V2 purchase button interaction before purchase gate (PWENG-15)

* Fallback tier selector interaction value to tier id (PWENG-15)

* Record paywall_close before session reset on UIKit dismiss (PWENG-15)

* Fix lint issues (PWENG-15)

* Expose tier selector interaction value for tests (PWENG-15)

* correct modifers

* Emit paywall close after exit offer dismiss (PWENG-15)

* Consolidate PaywallsV2 impression tracking and eligibility in addPaywallModifiers (PWENG-15)

* Derive tab toggle from selectedTabId to avoid sync race (PWENG-15)

* Fix lint issue (PWENG-15)

* Fix lint issue (PWENG-15)

* Clear tab package selection when user picks a root-only package (PWENG-15)

* Fix Swift 5.8 compile error in purchase button method description (PWENG-15)

---------

Co-authored-by: RevenueCat Git Bot <72824662+RCGitBot@users.noreply.github.com>
Co-authored-by: Alexander Repty <alexander.repty@mac.com>
Co-authored-by: Jacob Rakidzich <Jacob@JacobZivanDesign.com>
Co-authored-by: Alexander Repty <alex.repty@revenuecat.com> via Monika Mateska
* Run record-and-upload-paywalls-v1-snapshots on main and release branches (#6620) via Rick
* fix(ads): remove mistake masking behavior (#6613) via Peter Porfy
* Preparing for next version (#6619) via RevenueCat Git Bot
* [AUTOMATIC] Release/5.68.0 (#6617)

* Version bump for 5.68.0

* Revert PaywallsV2 header component addition

Revert addition of PaywallsV2 header component and update related entries.

* Update CHANGELOG.md

---------

Co-authored-by: Cesar de la Vega <664544+vegaro@users.noreply.github.com> via RevenueCat Git Bot
* Use shared run_maestro_e2e_tests action from fastlane plugin (#6616)

* Use shared run_maestro_e2e_tests action from fastlane plugin

Replace inline Maestro retry logic and postprocess_maestro_junit_report
with the new run_maestro_e2e_tests action from the fastlane plugin,
passing environment_name for JUnit report postprocessing.

Made-with: Cursor

* Update Gemfile.lock with path resolution fix from plugin

Made-with: Cursor

* Point fastlane plugin to main branch

The maestro retry action has been merged to main.

Made-with: Cursor

* Add temporary maestro-only workflow for debugging

Trigger with: action=run-maestro-only

Made-with: Cursor

* Fix infinite recursion: lane name shadows plugin action

The lane `run_maestro_e2e_tests` has the same name as the plugin action
`RunMaestroE2eTestsAction`. Fastlane resolves lane names before action
names, causing infinite recursion. Call the action class directly to
bypass lane resolution.

Made-with: Cursor

* Rename lane to avoid shadowing plugin action

Rename `run_maestro_e2e_tests` lane to `run_maestro_e2e_tests_ios` so
it no longer shadows the `run_maestro_e2e_tests` plugin action, which
was causing infinite recursion.

Made-with: Cursor

* Remove temporary maestro-only workflow

Made-with: Cursor via Antonio Pallares
* Bump fastlane-plugin-revenuecat_internal from `20911d1` to `a1eed48` (#6618)

Bumps [fastlane-plugin-revenuecat_internal](https://github.com/RevenueCat/fastlane-plugin-revenuecat_internal) from `20911d1` to `a1eed48`.
- [Release notes](https://github.com/RevenueCat/fastlane-plugin-revenuecat_internal/releases)
- [Commits](https://github.com/RevenueCat/fastlane-plugin-revenuecat_internal/compare/20911d1ac54e7cdcf339bc094b75f928e46d7be0...a1eed48467a057a8bbdac5a0587e3653a541a46b)

---
updated-dependencies:
- dependency-name: fastlane-plugin-revenuecat_internal
  dependency-version: a1eed48467a057a8bbdac5a0587e3653a541a46b
  dependency-type: direct:production
...

Signed-off-by: dependabot[bot] <support@github.com>
Co-authored-by: dependabot[bot] <49699333+dependabot[bot]@users.noreply.github.com> via dependabot[bot]
