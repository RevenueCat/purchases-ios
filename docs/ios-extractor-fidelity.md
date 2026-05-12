# iOS Paywall Extractor — Fidelity Notes

> **Extractor:** `PaywallAccessibilityTreeTests` in `PaywallsTesterUITests`  
> **Current schema version:** 2.4.0  
> **Last updated:** 2026-05-12

---

## Overview

The iOS paywall extractor reads the **XCUITest / UIAccessibility tree** of a live running paywall, not the JSON model that was used to build it. This means it sees UIKit/SwiftUI accessibility nodes — not the raw JSON component graph. The mapping is generally faithful, but a handful of systematic differences exist between the source `offerings.json` and the extractor output.

This document classifies each known difference as a **bug** (fixed or unfixed), **by-design**, or **intentional-but-undocumented**, and points to the exact code path responsible.

---

## Fidelity summary table

| Finding | Symptom | Classification | Fixed in |
|---|---|---|---|
| H1: child IDs replaced by parent stack ID | Keys `<id>_0`, `<id>_1`, … in output for the same source stack ID | Bug | 2.1.0 / `StackComponentView` |
| H1 deeper: nested stack propagation | Inner stacks inside a `.contain` container still propagate their IDs to leaf children | SwiftUI limitation | Open |
| H2a: package sub-stack children missing | Package inner components not present as separate entries | By design | — |
| H2b: sticky footer children missing | Footer inner components not present as separate entries | By design | — |
| H2c: purchase button IDs missing (potential) | `FSIUNamEVS`/`lqDNuRK2mb`-style IDs absent or with `_N` suffix | Extractor gap | Pending (re-verify after H1 fix) |
| H2d: overlay components missing (header, close button) | Components with negative root-relative y absent from output | Bug | 2.2.0 / extractor frame guard |
| H3a: `paywall_0`…`paywall_N` synthetic keys | Navigation sentinel leaks into component dictionary | Bug | 2.1.0 / extractor filter |
| H3b: off-paywall scaffolding element | 0×0 or 0-height element in output | Bug | 2.1.0 / extractor frame guard |
| H4: `_N` suffix order is traversal-dependent | `id_0` / `id_1` assignment depends on DFS order, differs across platforms | Bug | 2.2.0 / spatial sort |
| H5: direct-child text components silently dropped | Text components that are direct children of the root stack (no `.contain` barrier) receive the `"paywall"` sentinel identifier via UIKit propagation → filtered by `collectIdedSnapshots` | Bug | 2.3.0 / add `.contain` to "paywall" VStack |
| `ImageComponent` IDs not captured | Images never appear by their source component ID | Model gap | Open — `ImageComponent` has no `id` field |
| Type change: `stack`→`button` | Source JSON type `stack`; export type `button` | Intentional | — |
| Type change: `package`→`button` | Source JSON type `package`; export type `button` | Intentional | — |

---

## H1 — Child IDs replaced by parent stack IDs

### Symptom

The source `offerings.json` defines a stack with `"id": "7iXVpvNvpH"`. In a pre-2.1.0 extractor output this stack does not appear; instead, eight keys `7iXVpvNvpH_0` through `7iXVpvNvpH_7` appear, each pointing to a different leaf element inside the stack (icons, text labels, etc.) — all with `componentId: "7iXVpvNvpH"`.

### Root cause

`StackComponentView.make(style:)` applies `.accessibilityIdentifier` on the container view **without** `.accessibilityElement(children: .contain)`:

```swift
// StackComponentView.swift (pre-fix)
.applyIf(accessibilityLabelOverride != nil || accessibilityIdentifierOverride != nil) { view in
    view
        .accessibilityLabel(accessibilityLabelOverride ?? "")
        .accessibilityIdentifier(accessibilityIdentifierOverride ?? "")
    // No .accessibilityElement(children: .contain)
}
```

Without `.accessibilityElement(children: .contain)`, SwiftUI treats the container as **accessibility-transparent**. UIKit propagates the identifier value downward to every leaf child element. XCUITest then sees each leaf carrying the parent stack's identifier, not its own.

The extractor's `collectIdedSnapshots` collects all of these, and the two-pass deduplication in `buildComponents` emits `<parent_id>_0`, `<parent_id>_1`, … for every occurrence.

### Fix (applied in 2.1.0)

`StackComponentView.swift` — add `.accessibilityElement(children: .contain)` to the `applyIf` block in `body`:

```swift
.applyIf(accessibilityLabelOverride != nil || accessibilityIdentifierOverride != nil) { view in
    view
        .accessibilityLabel(accessibilityLabelOverride ?? "")
        .accessibilityIdentifier(accessibilityIdentifierOverride ?? "")
        .accessibilityElement(children: .contain)   // ← added
}
```

The stack now owns its identifier as a single accessibility node. Its children are still reachable via the `.contain` mode and will surface with their own identifiers if they carry them.

### Known limitation: nested `.contain` containers (open)

SwiftUI/UIKit does not reliably create nested accessibility container nodes. When an inner stack is inside an outer `.contain` container, the inner stack's identifier still propagates to its leaf children — they appear as `<inner_id>_0`, `<inner_id>_1`, etc. rather than as a single container node. This is a SwiftUI framework constraint; no workaround is currently applied.

---

## H2 — Missing component IDs

### H2a / H2b: Package and sticky-footer children (by design)

`ComponentsView.swift` applies `.accessibilityElement(children: .contain)` on the `.package` and `.stickyFooter` cases:

```swift
case .package(let viewModel):
    PackageComponentView(...)
        .accessibilityLabel(viewModel.componentName ?? "package")
        .accessibilityIdentifier(viewModel.componentId ?? "package")
        .accessibilityElement(children: .contain)   // ← intentional

case .stickyFooter(let viewModel):
    StickyFooterComponentView(...)
        .accessibilityLabel("sticky_footer")
        .accessibilityIdentifier(viewModel.component.id ?? "sticky_footer")
        .accessibilityElement(children: .contain)   // ← intentional
```

This collapses the entire subtree into a single accessible unit. Price labels, sub-stacks, and other children inside a package or footer do not appear as individual nodes in the XCUITest tree. This is the correct accessibility behavior — a package card is a single interactive unit for VoiceOver users.

**Consequence for the extractor:** the package or footer ID appears once in the output; its children are not individually listed. This is expected and correct.

### H2c: Purchase button IDs (extractor gap, pending verification)

`PurchaseButtonComponentView.swift` sets `.accessibilityIdentifier` on the `AsyncButton` without `.accessibilityElement(children: .contain)`. Before the H1 fix, the button's identifier was propagated to its inner label stack, causing it to appear as `<buttonId>_0`, `<buttonId>_1`, etc. After the H1 fix, the label stack claims its own node, and the button itself should surface as a single node with its own identifier.

**Action required:** Re-run the extractor after applying the H1 fix and verify purchase button IDs appear correctly. If they are still missing or duplicated, add `.accessibilityElement(children: .contain)` to the `AsyncButton` in `PurchaseButtonComponentView`.

### H2d: Overlay components with negative root-relative y (bug, fixed in 2.2.0)

Header images and close buttons are rendered **above** the paywall content root in the safe-area region. With `rootFrame.y ≈ 62`, an element at screen-level y ≈ 3 translates to root-relative y = 3 − 62 = −59. The 2.1.0 guard `frame.y < -10` was incorrectly removing these legitimate paywall components.

**Fix (2.2.0):** The negative-y guard has been removed. Only zero-dimension elements are filtered:

```swift
// buildComponents — 2.2.0
if frame.width == 0 || frame.height == 0 {
    continue
}
```

Stack components that wrap header images (e.g. `GsnRWJndVY`) and button components for close actions (e.g. `U5Ly30gKVP`) now appear in the output with correct negative-y frames.

### `ImageComponent` IDs — model gap (open)

`PaywallComponent.ImageComponent` has no `id` or `name` fields. Images are also explicitly hidden from the accessibility tree via `.accessibilityHidden(true)` in `ImageComponentView.renderImage` (marked "WIP: Fix this later"). As a result, image component source IDs are never surfaced in the extractor output. Parent containers (stacks, buttons) that wrap the image component DO appear with their own IDs.

To fix this in the future:
1. Add `id: String?` and `name: String?` to `PaywallComponent.ImageComponent` and `PartialImageComponent`.
2. Add `componentId` / `componentName` computed properties to `ImageComponentViewModel`.
3. In `ComponentsView`, add `.accessibilityLabel(viewModel.componentName ?? "").accessibilityIdentifier(viewModel.componentId ?? "image").accessibilityElement(children: .ignore)` to the `.image` case.
4. Remove or conditionalize the `.accessibilityHidden(true)` in `ImageComponentView.renderImage`.

---

## H3 — Synthetic IDs in output

### H3a: `paywall_0` … `paywall_N` (bug, fixed in 2.1.0)

`PaywallsV2View.addPaywallModifiers` applies `.accessibilityIdentifier("paywall")` on its outer `VStack`. This string is not a component ID — it is a **navigation sentinel** used by `navigateToLivePaywall` to detect when the paywall is on screen via `waitForExistence`:

```swift
// PaywallsV2View.swift
VStack { ... }
    .accessibilityIdentifier("paywall")
```

The outer `VStack` has no `.accessibilityElement(children: .contain)`, so `"paywall"` propagates to any leaf children inside that wrapper that do not carry their own identifier. The extractor previously collected all of them, producing `paywall_0` through `paywall_N`.

**Fix (2.1.0):** `collectIdedSnapshots` now skips any element whose identifier is `"paywall"`:

```swift
let id = snapshot.identifier
if !id.isEmpty && id != "paywall" {
    pairs.append((id, snapshot))
}
```

The sentinel is still present in the live accessibility tree (so `navigateToLivePaywall` continues to work); it is simply excluded from the extractor's output dictionary.

### H3b: Off-paywall scaffolding element (bug, fixed in 2.1.0 / tightened in 2.2.0)

UIKit navigation-bar or status-bar artefacts were occasionally included in the output. In 2.1.0 these were caught by `frame.y < -10 || (frame.width == 0 && frame.height == 0)`. This was tightened in 2.2.0 to `frame.width == 0 || frame.height == 0` (using `||` rather than `&&`) after observing a 402×0 artefact (`YNbDUWF20g`) that slipped through the `&&` guard. Simultaneously the `y < -10` clause was removed because it incorrectly excluded legitimate overlay components (see H2d).

---

## H4 — `_N` suffix ordering is traversal-dependent (bug, fixed in 2.2.0)

### Symptom

When multiple elements share the same component ID (e.g. repeated icon rows), the 2.1.0 extractor assigned `_0`, `_1`, … in DFS traversal order. iOS DFS walks the SwiftUI view tree in source-declaration order; Android may use a different order. This meant `4yksGLf4K5_0` on iOS could correspond to `4yksGLf4K5_1` on Android.

### Fix (2.2.0)

Before assigning suffixes, occurrences of each duplicate ID are **sorted by on-screen position** (y ascending, then x ascending). The suffix index is then the rank in this spatial ordering rather than the DFS visit order:

```swift
let sorted = occurrences.sorted {
    let a = $0.snapshot.frame, b = $1.snapshot.frame
    if abs(a.minY - b.minY) > 1 { return a.minY < b.minY }
    return a.minX < b.minX
}
```

Elements that appear higher on screen get lower suffix indices. Ties (elements on the same horizontal row) are broken by left-to-right order. This produces a stable, position-based numbering that is independent of tree traversal order.

**Note:** This change alters the suffix assignment for any offering that had duplicate IDs in 2.1.0 output. Re-export reference snapshots when upgrading.

---

## Coordinate normalization (added in 2.4.0)

All frame values (`x`, `y`, `width`, `height`), `rootFrame`, `viewport.width`, `viewport.height`, and every entry of `safeAreaInsets` are emitted as **JSON integers**. The raw `CGFloat` values from `XCUIElementSnapshot.frame` are rounded with banker's rounding (Swift's `Double.rounded()` default — round-half-to-even).

This eliminates sub-pixel layout noise (values like `824.3333333333333` or `15.666666666666629`), makes byte-level diffs across runs meaningful, and makes the duplicate-ID spatial sort (H4) trivially correct without a tolerance window.

**Cross-platform note:** the web extractor still emits fractional coordinates as of this writing. Downstream tooling that compares iOS and web outputs should round web values to integers before diffing, or pin the comparison to integer precision. Aligning the web side is a follow-up.

**`scale`** in `viewport` is intentionally **not** an integer — it's the physical-pixel scale factor (e.g. `3.0` on Retina iPhones), not a coordinate.

---

## Safe-area insets in metadata (added in 2.4.0)

`metadata.safeAreaInsets` carries the SwiftUI `safeAreaInsets` reported by `GeometryReader` inside the running paywall:

```json
"safeAreaInsets": {
  "top": 47,
  "bottom": 34,
  "leading": 0,
  "trailing": 0
}
```

**How it works.** When `SCREENSHOT_MODE=1` is active, `PaywallsV2View.safeAreaProbe` injects a hidden accessibility element with identifier `__safe_area_insets` whose `accessibilityValue` is a comma-separated `top,bottom,leading,trailing` string. The XCUITest reads the value after `app.snapshot()` and parses it into the metadata. In every other build the probe returns `EmptyView` so production paywalls carry no extra accessibility node.

`safeAreaInsets` is omitted from the JSON for V1 paywalls or any path where the probe isn't present.

The `__safe_area_insets` identifier is excluded from the `components` dictionary by `buildComponents` so it never appears as a "component" in the output.

---

## Hermetic local-offering loading (added in 2.4.0)

The test can now run without an RC API key. Set `TEST_RUNNER_LOCAL_OFFERINGS_PATH=/path/to/offerings.json` and `TEST_RUNNER_OFFERING_ID=<id>`. The PaywallsTester app loads the offering via `LocalOfferingLoader` (in `Tests/TestingApps/PaywallsTester/PaywallsTester/Config/`), bypassing `Purchases.shared.offerings()`.

**Asset URL rewriting.** Remote asset references are rewritten to `file://` URLs adjacent to the JSON:

- `https://assets.pawwalls.com/...` → `<offerings.json dir>/pawwalls/assets/...`
- `https://icons.pawwalls.com/...`  → `<offerings.json dir>/pawwalls/icons/...`

Missing local assets fail to render silently — the accessibility tree is still captured. The fixture directory convention matches `Tests/paywall-preview-resources/resources/`.

**Mock packages.** The loader injects a standard set of `$rc_lifetime` / `$rc_annual` / `$rc_six_month` / `$rc_three_month` / `$rc_two_month` / `$rc_monthly` / `$rc_weekly` packages backed by `PreviewMock.Product` so any V2 component referencing a standard `package_id` resolves cleanly.

---

## Single-device parameterization (added in 2.4.0)

Each test invocation runs against one simulator (chosen by the caller's `xcodebuild -destination`). Three env vars configure per-run characteristics; the resulting JSON records each:

| Env var | JSON `metadata` field | Default |
|---|---|---|
| `TEST_LOCALE` | `locale` (e.g. `en_US`) | `en_US` |
| `DEVICE_ORIENTATION` (`portrait` / `landscape`) | `orientation` | `portrait` |
| `COLOR_SCHEME` (`light` / `dark`) | `colorScheme` | `light` |
| `DEVICE_CLASS` (free-text e.g. `tablet`, `mini`) | `deviceClass` (optional) | — |

Locale is applied via `-AppleLanguages`/`-AppleLocale` launch arguments; orientation via `XCUIDevice.shared.orientation`; color scheme via `.preferredColorScheme(...)` in `PaywallPresenter`. Cross-device matrices are intended to be driven by an outer script that invokes `xcodebuild test` once per (device, locale, orientation, color scheme) combination.

---

## Artifact location (changed in 2.4.0)

Output files (`paywall-tree-<id>-<ts>.json` + `.png`) now write to:

1. `$TEST_ARTIFACTS_DIR/` (if set)
2. `<host-project-dir>/fastlane/test_output/xctest/paywall-accessibility-tree/` (default; `<host-project-dir>` resolved from `HOST_PROJECT_DIR` or `SIMULATOR_HOST_HOME`)
3. `/tmp/` (fallback only when no host hint is available)

`DEV_DESKTOP_COPY=1` opts back into the previous `~/Desktop` copy for local development convenience.

Both files are always attached to the `.xcresult` bundle via `XCTAttachment` — that's the canonical CI extraction path and is independent of the on-disk write location.

---

## H5 — Direct-child text components silently dropped (bug, fixed in 2.3.0)

### Symptom

A `TextComponent` that is a direct child of the root stack appears in the rendered screenshot but is absent from the extractor JSON output. Example: `1OTK5qjUm9` ("Unlock access to all recipes" headline) is visible in the PNG but missing from `components` in the JSON.

### Root cause

`PaywallsV2View.addPaywallModifiers` applies `.accessibilityIdentifier("paywall")` to the outer `VStack` **without** `.accessibilityElement(children: .contain)`:

```swift
// PaywallsV2View.swift (pre-fix)
content
    ...
    .accessibilityIdentifier("paywall")   // no .contain
```

Without `.contain`, UIKit treats the VStack as accessibility-transparent and **propagates the `"paywall"` identifier downward** to leaf accessible descendants that do not have their own `.contain` barrier. `TextComponentView` sets `.accessibilityIdentifier(viewModel.componentId)` on its text node but does not add `.accessibilityElement(children: .contain)`, so it provides no such barrier. UIKit overwrites the text node's identifier with `"paywall"`.

`collectIdedSnapshots` then encounters the node with `identifier == "paywall"` and drops it:

```swift
if !id.isEmpty && id != "paywall" {
    pairs.append((id, snapshot))   // "paywall" is filtered out
}
```

The component is in the tree but its real ID is never seen by the extractor.

Most other components are unaffected because they are nested inside `.accessibilityElement(children: .contain)` barriers (stacks, packages, sticky footer) that prevent propagation.

### What triggered the regression

The `.statusBar(hidden: isScreenshotMode)` modifier was added to `PaywallPresenter` (commit `2423d00d9`). Hiding the status bar changes the safe-area geometry, which altered the UIKit accessibility tree layout enough to start triggering the "paywall" propagation for direct-child text nodes where it had not been triggered previously.

### Fix (2.3.0)

`PaywallsV2View.swift` — add `.accessibilityElement(children: .contain)` before `.accessibilityIdentifier("paywall")` in `addPaywallModifiers`:

```swift
// PaywallsV2View.swift (fix)
.accessibilityElement(children: .contain)   // ← added
.accessibilityIdentifier("paywall")
```

With `.contain`, the `"paywall"` identifier is locked to the VStack container node and is **not** propagated to any descendant. Every child (including direct-child text nodes) retains its own identifier. The `navigateToLivePaywall` UITest sentinel (`waitForExistence` on `identifier == "paywall"`) continues to work because the container node itself still carries the identifier.

---

## Test-mode rendering toggles (added in 2.2.0)

Cross-platform comparison (iOS extractor vs. web extractor) revealed three rendering discrepancies caused by test-environment setup, not by the paywall code itself. The following toggles align the iOS test render with the web baseline.

### T1: Intro-offer eligibility

**Problem:** In the simulator, StoreKit defaults to "eligible for intro offer", so the paywall renders intro-offer pricing (e.g. "Try free for 1 week") instead of the regular price the web extractor sees.

**Fix:** `PaywallPresenter.swift` — when `SCREENSHOT_MODE=1`, a `#if DEBUG` code path passes `.producing(eligibility: .ineligible)` to the `@_spi(Internal)` `PaywallView(offering:useDraftPaywall:introEligibility:)` init, forcing the regular-price render. Outside screenshot mode the live StoreKit eligibility is used as before.

### T2: Sheet vs. full-screen presentation

**Problem:** The `OFFERING_ID` UITest hook in `APIKeyDashboardList.swift` always assigned `presentedPaywall` (→ `.sheet`). The web extractor renders the paywall full-screen. The sheet chrome (rounded corners, partial backdrop) shifts component frames relative to a full-screen render.

**Fix:** `APIKeyDashboardList.swift` — when `SCREENSHOT_MODE=1`, the hook assigns `presentedPaywallCover` (→ `.fullScreenCover`) and sets `mode: .fullScreen`, producing frames that match the web extractor baseline.

### T3: Discount badge formatting fallback

**Problem:** `VariableHandlerV2.productRelativeDiscount` returned `""` when the UIConfig localizations did not include a `"percent"` key for the resolved locale (e.g., `en_DE` resolving to an `en` payload that omitted the key). The badge template `"{{ product.relative_discount }} OFF"` then rendered as `" OFF"`.

**Fix:** `VariableHandlerV2.swift` — a fallback `"%d%%"` format string is used when the `"percent"` key is absent. The formatted percentage is now always emitted when a discount ratio is available.

---

## PNG export (added in 2.2.0)

Each extractor run now writes a `paywall-tree-<offering-id>-<timestamp>.png` file alongside the `.json` file. The PNG is a full-app screenshot captured via `XCUIApplication.screenshot()` at the moment the tree snapshot was taken. Both files are written to `/tmp/`, copied to `~/Desktop/` when the host home is discoverable, and attached to the `.xcresult` bundle under `XCTAttachment`.

---

## Type changes — intentional

When a `StackComponent` or `PackageComponent` is rendered inside a `ButtonComponentView`, SwiftUI wraps the entire content in a `Button`. UIKit reports the accessible element's type as `XCUIElement.ElementType.button`, which the extractor maps to `"button"` in the semantic type field. The source JSON may say `"stack"` or `"package"`, but the rendered element is genuinely interactive — the type change is correct.

| Source JSON type | Exported type | Reason |
|---|---|---|
| `stack` | `button` | Stack rendered inside a `ButtonComponentView` |
| `package` | `button` | Package rendered inside a `ButtonComponentView` |

---

## Extractor version history

| Version | Changes |
|---|---|
| 1.0.0 | Recursive text dump (tree format), no coordinates |
| 2.0.0 | Flat component dictionary; coordinates translated to paywall-root space; `rootFrame` in metadata |
| 2.1.0 | Fix H1 (`StackComponentView` + `.accessibilityElement(children: .contain)`); filter `"paywall"` sentinel; skip off-paywall zero-size/zero-height scaffolding elements |
| 2.2.0 | Fix H2d (remove `y < -10` guard — overlay components now included); Fix H4 (spatial sort for `_N` suffix stability); PNG export alongside JSON |
| 2.3.0 | Fix H5 (add `.accessibilityElement(children: .contain)` to "paywall" VStack — direct-child text components now captured with correct IDs) |
| 2.4.0 | Hermetic local-offering loading via `LOCAL_OFFERINGS_PATH` (no API key required); single-device parameterization (`DEVICE_CLASS` / `DEVICE_ORIENTATION` / `COLOR_SCHEME` / `TEST_LOCALE`); artifact output moved to `fastlane/test_output/xctest/paywall-accessibility-tree/`; `metadata.safeAreaInsets` populated from a SwiftUI safe-area probe; **all coordinate values normalized to integers**; per-run metadata (`deviceClass`, `colorScheme`, `orientation`) added |
