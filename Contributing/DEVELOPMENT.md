# Working with Tuist

We're migrating development to Tuist-generated workspaces. The legacy `RevenueCat.xcworkspace` still works today, but prefer Tuist for new work so you stay aligned with the current structure.

Tuist is used to generate the Xcode workspaces and projects in this repository. By default, Tuist resolves the `RevenueCat` and `RevenueCatUI` packages from the local checkout.

## Installing Tuist

Follow the official installation guide at [tuist.io](https://docs.tuist.dev/en/guides/quick-start/get-started) to install Tuist, then verify the install with `tuist version`.

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

## Working in a git worktree

Each `git worktree` is its own checkout, so the gitignored, per-worktree bits (`Local.xcconfig`, the generated `RevenueCat-Tuist.xcworkspace`, `Derived/`) don't carry over and have to be set up again. The Tuist binary cache in `~/.cache/tuist` is content-addressed, so it's shared across worktrees for free, but the workspace still needs generating per worktree.

To handle the per-worktree boilerplate in one command:

```bash
mise trust          # each worktree's mise.toml is untrusted until you trust it
mise run setup-worktree
```

`setup-worktree` links `Local.xcconfig` from your primary checkout (so you don't re-enter the API key per worktree) and runs `tuist install`. Then generate whatever you need as usual:

```bash
tuist generate PaywallsTester
```

> Note: because `Local.xcconfig` is a symlink to the primary checkout, it's shared across worktrees. If you need a per-worktree key or bundle ID (e.g. `TUIST_RC_API_KEY` / `TUIST_PAYWALLS_TESTER_BUNDLE_ID` to test against another project), replace the symlink with a real file in that worktree first, otherwise generation writes the override into the shared config.

## Troubleshooting

- **Missing files after generation**  
  Run a clean install sequence before generating:

  ```bash
  tuist clean
  tuist install
  tuist generate
  ```

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
