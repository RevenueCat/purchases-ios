# Fallback Paywall Background Image Removal Plan

## Goal

Remove the legacy fallback paywall background image (`background.jpg`) while wiring in the new fallback UI, without breaking RevenueCatUI behavior, tests, or CI snapshot workflows.

## Scope

- Replace the old fallback paywall presentation path with the new `DefaultPaywallView`.
- Remove fallback dependence on `background.jpg`.
- Update snapshots in both locations where baselines live.
- Keep diffs staged safely to minimize CI instability in the PR stack.

## Current Impact Map

### Runtime paths currently tied to `background.jpg`

- `RevenueCatUI/Helpers/PaywallData+Default.swift`
  - `PaywallData.createDefault(...)` hardcodes `background: "background.jpg"`.
- `RevenueCatUI/PaywallView.swift`
  - Fallback/default paywall is created via `PaywallData.createDefault(...)`.
- `RevenueCatUI/Data/PaywallData+Validation.swift`
  - Invalid/missing paywalls fall back to `createDefault(...)`.
- `RevenueCatUI/Views/LoadingPaywallView.swift`
  - Uses `Self.defaultPaywall.backgroundImageURL` in `TemplateBackgroundImageView`.
- `RevenueCatUI/Views/TemplateBackgroundImageView.swift`
  - Central renderer for background image display (blur, opacity, safe area behavior).

### Template usage

- `RevenueCatUI/Templates/Template2View.swift`
- `RevenueCatUI/Templates/Template4View.swift`
- `RevenueCatUI/Templates/Other platforms/WatchTemplateView.swift`

All three include `TemplateBackgroundImageView` and can surface fallback background behavior.

### Packaging/bundling references to remove eventually

- `Package.swift`
- `Package@swift-5.8.swift`
- `RevenueCatUI.podspec`
- `RevenueCat.xcodeproj/project.pbxproj`

Each explicitly includes `RevenueCatUI/Resources/background.jpg`.

### Test references

- `Tests/RevenueCatUITests/ImageLoaderTests.swift`
  - `createValidResponse` depends on `PaywallData.createDefault(...).backgroundImageURL` being a local file.
- `Tests/RevenueCatUITests/Data/__Snapshots__/PaywallDataValidationTests/*`
  - JSON snapshots currently include `"background": "background.jpg"` for fallback validation output.
- `Tests/UnitTests/Paywalls/PaywallDataTests.swift`
- `Tests/UnitTests/Networking/Responses/Fixtures/PaywallData-Sample1.json`
  - Fixture-level references to `"background.jpg"` (not necessarily fallback-specific behavior).

### Additional test resource coupling

- `Tests/RevenueCatUITests/Helpers/DataExtensions.swift`
  - `withLocalImages` sets `background: "background.heic"`.
- `Tests/RevenueCatUITests/Resources/background.heic`
  - Widely used by template snapshot tests that call `.withLocalImages`.
- `Projects/PaywallValidationTester/Project.swift`
  - Includes `Tests/RevenueCatUITests/Resources/background.heic`.

## Snapshot Architecture (Where Baselines Live)

### In `purchases-ios` (this repo)

- JSON snapshots:
  - `Tests/RevenueCatUITests/Data/__Snapshots__/...`
- Includes many symlinks (for older OS baselines) pointing to iOS18 files in the same directory.

### In `purchases-ios-snapshots` (external repo)

- Image snapshots:
  - `Tests/purchases-ios-snapshots/Templates/__Snapshots__/...`
- Linked into this repo via:
  - `Tests/RevenueCatUITests/Templates/__Snapshots__ -> ../../purchases-ios-snapshots/Templates/__Snapshots__`
- Pin controlled by:
  - `Tests/purchases-ios-snapshots-commit`

## CI / Fastlane Snapshot Flow

- `.circleci/config.yml` sets:
  - `CIRCLECI_TESTS_GENERATE_REVENUECAT_UI_SNAPSHOTS`
  - `CIRCLECI_TESTS_GENERATE_SNAPSHOTS`
- `fastlane/Fastfile` lane `test_revenuecatui`:
  - always runs `fetch_snapshots`
  - uses `CI-Snapshots` test plan when snapshot generation is enabled, else `CI-RevenueCatUI`.
- Snapshot generation workflow:
  - `generate_revenuecatui_snapshots` runs RevenueCatUI jobs across OS versions.
  - `create_snapshot_pr` can open PRs in `purchases-ios`.
  - `create_snapshots_repo_pr` can open PRs in `purchases-ios-snapshots`.
- After external snapshot PR merges:
  - update `Tests/purchases-ios-snapshots-commit` (e.g. via `fastlane ios update_snapshots_repo`).

## Phased Rollout Plan

## Phase 1: Plug in new fallback UI first (no asset deletion yet)

### Changes

- Wire `DefaultPaywallView` into fallback full-screen presentation path in `RevenueCatUI/PaywallView.swift`.
- Preserve footer/condensed-footer fallback behavior initially to reduce blast radius.
- Localize fallback button labels in `DefaultPaywallView`:
  - `Purchase`
  - `Restore Purchases`
- Make `PaywallWarning.bodyText` deterministic:
  - replace nondeterministic `Set.joined(...)` with sorted output.

### Why first

- Decouples behavior migration from resource deletion.
- Reduces ambiguity in snapshot diffs and CI failures.

### Expected snapshot changes

- Primarily image snapshots in `OtherPaywallViewTests` (external snapshots repo).

## Phase 2: Remove fallback dependency on background image

### Changes

- Update `PaywallData+Default` so fallback no longer sets a bundled background image.
- Update `LoadingPaywallView` to avoid dependence on fallback `backgroundImageURL`.
- Refactor `ImageLoaderTests` to use a dedicated test image resource instead of fallback default paywall image.

### Snapshot/test updates

- Regenerate JSON snapshots in:
  - `Tests/RevenueCatUITests/Data/__Snapshots__/PaywallDataValidationTests`
- Regenerate image snapshots in external snapshots repo for loading/fallback cases.

## Phase 3: Delete asset and cleanup package references

### Changes

- Delete `RevenueCatUI/Resources/background.jpg`.
- Remove all packaging references:
  - `Package.swift`
  - `Package@swift-5.8.swift`
  - `RevenueCatUI.podspec`
  - `RevenueCat.xcodeproj/project.pbxproj`
- Update debug/sample data still assuming bundled fallback image where needed (for previews/tests/examples).

### Validation

- `swift build` for `RevenueCatUI` target.
- Relevant RevenueCatUI tests.
- Snapshot verification in both repos.

## Snapshot Update Checklist (Two-Repo Sync)

1. Generate/update affected RevenueCatUI snapshots.
2. Commit JSON snapshot changes in `purchases-ios` (if changed).
3. Commit image snapshot changes in `purchases-ios-snapshots`.
4. Merge snapshots repo PR.
5. Update `Tests/purchases-ios-snapshots-commit` in `purchases-ios`.
6. Re-run CI (`run-revenuecat-ui-ios-26` and related jobs) to verify clean baseline alignment.

## Risks and Mitigations

- **Risk:** Snapshot baselines split across two repos can drift.
  - **Mitigation:** Treat snapshot updates + commit pin bump as one coordinated delivery unit.
- **Risk:** Flaky snapshot diffs from nondeterministic warning text.
  - **Mitigation:** Sort set values before joining.
- **Risk:** Hidden dependencies on fallback image in tests.
  - **Mitigation:** Replace fallback-derived fixtures with explicit test resources.
- **Risk:** Large PR diff obscures regressions.
  - **Mitigation:** Keep phased PRs narrowly scoped.

## Recommended PR Stack Shape

1. **PR A:** Fallback UI wiring + localization + deterministic warning text.
2. **PR B:** Remove fallback image dependency + test refactors + snapshot updates.
3. **PR C:** Delete `background.jpg` and remove package/project references + final cleanup.

This structure keeps behavior changes understandable and makes CI triage straightforward at each stage.
