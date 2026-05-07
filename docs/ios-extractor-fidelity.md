# iOS Paywall Extractor — Fidelity Notes

> **Extractor:** `PaywallAccessibilityTreeTests` in `PaywallsTesterUITests`  
> **Current schema version:** 2.1.0  
> **Last updated:** 2026-04-29

---

## Overview

The iOS paywall extractor reads the **XCUITest / UIAccessibility tree** of a live running paywall, not the JSON model that was used to build it. This means it sees UIKit/SwiftUI accessibility nodes — not the raw JSON component graph. The mapping is generally faithful, but a handful of systematic differences exist between the source `offerings.json` and the extractor output.

This document classifies each known difference as a **bug** (fixed or unfixed), **by-design**, or **intentional-but-undocumented**, and points to the exact code path responsible.

---

## Fidelity summary table

| Finding | Symptom | Classification | Fixed in |
|---|---|---|---|
| H1: child IDs replaced by parent stack ID | Keys `<id>_0`, `<id>_1`, … in output for the same source stack ID | Bug | 2.1.0 / `StackComponentView` |
| H2a: package sub-stack children missing | Package inner components not present as separate entries | By design | — |
| H2b: sticky footer children missing | Footer inner components not present as separate entries | By design | — |
| H2c: purchase button IDs missing (potential) | `FSIUNamEVS`/`lqDNuRK2mb`-style IDs absent or with `_N` suffix | Extractor gap | Pending (re-verify after H1 fix) |
| H3a: `paywall_0`…`paywall_N` synthetic keys | Navigation sentinel leaks into component dictionary | Bug | 2.1.0 / extractor filter |
| H3b: off-paywall scaffolding element | 0×0 element at negative y in output | Bug | 2.1.0 / extractor frame guard |
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

`StackComponentView.swift` — add `.accessibilityElement(children: .contain)` to the `applyIf` block:

```swift
.applyIf(accessibilityLabelOverride != nil || accessibilityIdentifierOverride != nil) { view in
    view
        .accessibilityLabel(accessibilityLabelOverride ?? "")
        .accessibilityIdentifier(accessibilityIdentifierOverride ?? "")
        .accessibilityElement(children: .contain)   // ← added
}
```

The stack now owns its identifier as a single accessibility node. Its children are still reachable via the `.contain` mode and will surface with their own identifiers if they carry them.

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

### H3b: Off-paywall scaffolding element (bug, fixed in 2.1.0)

A 0×0 element at approximately y = –62 in the paywall's coordinate space (a UIKit navigation-bar or status-bar artefact) was occasionally included in the output. After coordinate translation it appears with a negative y, indicating it lives above the paywall root.

**Fix (2.1.0):** `buildComponents` now skips any element whose translated frame is too far above the root or is zero-sized:

```swift
if frame.y < -10 || (frame.width == 0 && frame.height == 0) {
    continue
}
```

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
| 2.1.0 | Fix H1 (`StackComponentView` + `.accessibilityElement(children: .contain)`); filter `"paywall"` sentinel; skip off-paywall zero-size scaffolding elements |
