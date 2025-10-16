# Working with Tuist

We're migrating development to Tuist-generated workspaces. The legacy `RevenueCat.xcworkspace` still works today, but prefer Tuist for new work so you stay aligned with the current structure.

Tuist is used to generate the Xcode workspaces and projects in this repository. By default, Tuist resolves the `RevenueCat` and `RevenueCatUI` packages from the local checkout.

## Installing Tuist

Follow the official installation guide at [tuist.io](https://docs.tuist.io/tutorial/get-started) to install Tuist, then verify the install with `tuist version`.

## Generating Workspaces

### Generate every target

Use this when you want the full workspace with all targets.

```bash
tuist generate
```

### Generate a subset of targets

> Important: `tuist generate` accepts only target names or tags—projects

> Tip: If you plan to run tests, be sure to generate the corresponding test targets.

```bash
tuist generate <TargetName>
tuist generate RevenueCat
tuist generate RevenueCatUI

tuist generate PaywallsTester
tuist generate MagicWeather
tuist generate PurchaseTester

tuist generate UnitTests
tuist generate RevenueCatUITests
tuist generate StoreKitUnitTests
tuist generate BackendIntegrationTests

tuist generate tag:<TagName>
tuist generate tag:APITester
tuist generate tag:RevenueCatTests

tuist generate Maestro  # Generates the Maestro example app
```

When you generate a specific target (for example, `tuist generate RevenueCat`), Tuist only includes the files necessary to work on that target locally. This keeps the workspace lightweight and focused on what you need.

## Using Remote RevenueCat / RevenueCatUI Checkouts

Set the `TUIST_RC_LOCAL` environment variable to `false` to resolve `RevenueCat` and `RevenueCatUI` from their remote sources instead of the local checkout.

```bash
TUIST_RC_LOCAL=false tuist generate
```

## Troubleshooting

- **Missing files after generation**  
  Run a clean install sequence before generating:

  ```bash
  tuist clean
  tuist install
  tuist generate
  ```

## Running Backend Integration Tests

These tests talk to the live RevenueCat backend, so they need valid API keys and a generated workspace.

1. Generate the project with Tuist (only needs to be done once per clean checkout):  
   `tuist generate`  
   For a lighter workspace you can scope it to the test target:  
   `tuist generate BackendIntegrationTests --no-open`
2. Export the required secrets in your shell session (values are in 1Password):  
   `export REVENUECAT_API_KEY=...`  
   `export REVENUECAT_LOAD_SHEDDER_API_KEY=...`  
   `export REVENUECAT_CUSTOM_ENTITLEMENT_COMPUTATION_API_KEY=...`  
   `export REVENUECAT_PROXY_URL=...` *(optional; leave empty to hit production)*
3. Run the tests through Fastlane so the credentials get injected:  
   `bundle exec fastlane ios backend_integration_tests`

Pass a different test plan if you only need a subset, e.g.  
`bundle exec fastlane ios backend_integration_tests test_plan:BackendIntegrationTests-Offline`

## Known Gaps

The following Tuist projects or test plans are not yet represented:

- Additional test plans under `Tests/TestPlans`
- `SampleCat`
- `InstallationTests`
- CI workflows that use Tuist
- Cleanup of the existing Xcode workspace (only public content should remain)

## Adding a New Project

1. Create a folder inside `Projects/` that matches the new project name.
2. Add a `Project.swift` inside that folder describing the project.
3. Update the projects array in `Workspace.swift` to include the new project path.
4. Run `tuist generate <TargetName>` to create the workspace for the new project.
