# Where to test behavior

- **PerformanceTests (memory)**: Memory regressions and changes to memory-sensitive SDK paths. Use `Tests/PerformanceTests/` and the [memory baseline instructions](../AGENTS.md#performance-tests).
- **Workflow CPU benchmark**: CPU regressions during workflow presentation and navigation. Use the [workflow benchmark instructions](#workflow-cpu-benchmark).
- **Unit tests**: Logic, state changes, and serialization. Use `Tests/UnitTests/` for the core SDK, `Tests/StoreKitUnitTests/` for StoreKit, and `Tests/RevenueCatUITests/` for RevenueCatUI logic.
- **PaywallFixtures**: Paywall UI behavior with fixed data and no backend dependency. Examples include carousel pages across tabs, package selection, gestures, and accessibility. Add fixtures in `Tests/TestingApps/PaywallFixtures/` and XCUITests in `Tests/TestingApps/PaywallFixturesUITests/`.
- **Maestro**: Complete app flows, such as purchases, entitlement updates, and workflow navigation. Use the app and YAML flows in `Projects/AutomatedSDKTestsApp/`.
- **Snapshot tests**: Visual appearance, such as layout, colors, and text styles. Use the snapshot tests in `Tests/RevenueCatUITests/`.
- **Manual checks**: Behavior that the automated tests cannot verify, such as actual VoiceOver speech and focus order.

## Workflow CPU benchmark

This benchmark measures sampled main-thread CPU during workflow presentation and two forward actions. Each measurement starts when Maestro begins the tap and ends when Maestro confirms that the destination screen is visible. Use it to compare CPU use before and after an SDK change. It does not measure memory, UI latency, blocked time, or frame delivery.

The fixture uses the published configuration for `default_workflows` from the AutomatedSDK project in `AutomatedSDKTestsApp`. The Maestro flow is `Projects/AutomatedSDKTestsApp/maestro/performance/default_workflows.yaml`. It advances through three screens and stops before purchase. Ordinary Maestro tests verify that a flow works. This benchmark adds Instruments captures and a CPU comparison.

### Run locally

The benchmark needs macOS, Xcode with Instruments, the repository tools and Ruby dependencies, Maestro, and an iOS simulator. See [development setup](DEVELOPMENT.md) for the repository tools.

1. Set `REVENUECAT_API_KEY` in the repository's `Local.xcconfig` to the AutomatedSDK Test Store key (`test_...`). Keep this file out of Git.
2. Generate the workspace from the repository root:

   ```sh
   bundle install
   tuist install
   TUIST_RC_XCODE_PROJECT=true tuist generate AutomatedSDKTestsApp
   ```

3. Disable Reduce Motion on the simulator. The lane selects the iPhone 17 simulator with iOS 27.0 by default. To select another simulator, add `device:<UDID>` to both commands below.

4. Record a local baseline before the SDK change:

   ```sh
   bundle exec fastlane ios workflow_trace output:/tmp/workflow-baseline
   ```

5. Apply the SDK change. Run the comparison on the same machine and simulator:

   ```sh
   bundle exec fastlane ios workflow_trace output:/tmp/workflow-change baseline:/tmp/workflow-baseline
   ```

Each command builds the app with Release optimization and DEBUG helpers, then captures six iterations. Each iteration includes a warm-up journey and an app restart before capture. Each run needs a new output directory. A different environment or workflow configuration prevents comparison. A local run needs a local baseline, not a CI baseline.

### Read the results

`comparison.txt` reports the total CPU change and its 99% bootstrap confidence interval. `summary.json` contains the measurements and configuration. The run saves the debug symbols in `symbols/`. Each iteration saves an Instruments trace, action offsets, and a manifest.

The app loads workflow data before capture. The runner checks that the full first-screen context build occurs between the start of the “Present Paywall” tap and confirmation that the first screen is visible.

The total CPU across the three actions controls the result. Individual action medians help locate the change.

| Result | Condition | CI result |
| --- | --- | --- |
| Regression | The entire interval exceeds the larger of 10% of baseline CPU or 10 ms. | Fail |
| Improvement | The entire interval is below the negative threshold. | Pass |
| Unchanged | The entire interval is within the positive and negative thresholds. | Pass |
| Inconclusive | The interval crosses a threshold. | Fail, without proof of a regression |

For a baseline of 719.5 ms, the threshold is 71.95 ms. The median change alone does not determine the result. A missing or incompatible baseline also fails a comparison run.

To repeat the numerical comparison without new captures:

```sh
bundle exec ruby fastlane/workflow_metrics.rb /tmp/workflow-change/summary.json /tmp/workflow-baseline/summary.json
```

The Ruby command returns 1 for regression, 2 for inconclusive, and 0 for improvement or unchanged. Fastlane fails for regression or inconclusive results.

### Run in CI and update the baseline

The `workflow-instruments` job runs automatically only on `main`. For an on-demand comparison, set `requested_jobs=workflow-instruments` when you start a CircleCI pipeline. On a PR, comment `@RCGitBot please test workflow-instruments`.

The benchmark also compares the CircleCI resource class, the reported CPU model, and the logical CPU count. Record a new baseline if an older baseline lacks these fields.

Record a fresh baseline for metric v2. Metric v1 counted CPU only during each tap command.

For the first baseline or an intentional fixture or environment change, start a pipeline on `main` with `requested_jobs=record-workflow-performance-baseline`. Use this record mode again if the shared cache expires. Do not replace the baseline to hide a regression.

| Run | Compares with the shared baseline? | Updates the shared baseline? |
| --- | --- | --- |
| Normal run on `main` | Yes | Yes, after success |
| Record mode on `main` | No | Yes, after success |
| Normal run on a PR branch | Yes | No |
| Record mode on a PR branch | No | No |

For a trial capture on a PR, comment `@RCGitBot please test record-workflow-performance-baseline`. This validates capture but does not seed the shared baseline.

CircleCI stores the shared numerical baseline in its cache. On `main`, jobs that update the baseline use the same queue. A run can replace a baseline from its own commit or an ancestor.

Traces, numerical results, and the comparison baseline remain CI artifacts. The job does not commit results to Git. After a failure, check `comparison.txt` and the iteration artifacts before a new run. If `comparison.txt` is absent, check the job log and iteration manifests.

### Check the benchmark code

The Ruby tests verify trace analysis, comparison decisions, and the Fastlane integration. They do not build the app or capture a real workflow. Run them on macOS:

```sh
bundle exec ruby fastlane/workflow_trace_test.rb
bundle exec ruby fastlane/workflow_metrics_test.rb
```

The regular PR `lint` job and the benchmark job run both test files. Only the benchmark job captures the workflow in Instruments.
