# Design: Haptic feedback for package/tab selection (Paywalls V2)

## Motivation

[Issue #6559](https://github.com/RevenueCat/purchases-ios/issues/6559): native iOS selectors/switches
give haptic feedback on selection change; RevenueCat paywalls don't, which makes multi-package
paywalls feel slightly out of place. Scope is limited to **Paywalls V2** (component-based paywalls).
V1 templates and `WatchTemplateView` are explicitly out of scope for this change.

The haptic is also made **editor-configurable per component** (default-on), since the dashboard
Paywall Builder team wants the ability to disable it for specific paywalls/components.

## Architecture

### 1. Haptic wrapper (`RevenueCatUI/Purchasing/PaywallEventTracker.swift`)

Mirrors the existing `ComponentInteractionLogger` shape (same file, lines 230-259): a struct
wrapping a closure, injected via `EnvironmentKey`.

```swift
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PackageSelectionHapticFeedback {

    private let action: () -> Void

    init(action: @escaping () -> Void = Self.defaultAction) {
        self.action = action
    }

    func callAsFunction() {
        self.action()
    }

    private static func defaultAction() {
        #if canImport(UIKit) && os(iOS)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
    // Once the deployment target reaches iOS 17, this can be replaced by the SwiftUI-native
    // `.sensoryFeedback(.selection, trigger:)` modifier attached directly at each call site,
    // dropping this imperative UIKit path.
}

struct PackageSelectionHapticFeedbackKey: EnvironmentKey {
    static let defaultValue: PackageSelectionHapticFeedback = .init()
}

extension EnvironmentValues {
    var packageSelectionHapticFeedback: PackageSelectionHapticFeedback {
        get { self[PackageSelectionHapticFeedbackKey.self] }
        set { self[PackageSelectionHapticFeedbackKey.self] = newValue }
    }
}
```

No `@MainActor`/`Sendable` annotations, matching `ComponentInteractionLogger`'s existing closure
signature — the project does not build under Swift 6 strict concurrency, and both are only ever
invoked synchronously from SwiftUI `Button` actions/`Binding` setters, which already run on the
main actor. Verify this compiles cleanly (`swift build` / `tuist generate` + build) since inline
`UISelectionFeedbackGenerator()` construction under newer SDKs may warrant a second look; if the
compiler objects, fall back to marking the closure `@MainActor @Sendable`.

### 2. Schema: per-component opt-out field

Add `public let hapticFeedbackEnabled: Bool?` to three component config classes.
`nil`/absent means **enabled** — the field exists so the dashboard editor can turn haptics *off*
per component, not so authors must opt in.

- **`PackageComponent`** (`Sources/Paywalls/Components/PaywallPackageComponent.swift:20-72`, plus
  `CodingKeys` at `:93-106`): explicit `CodingKeys` enum exists. Add `case hapticFeedbackEnabled`
  (no custom raw value — the project's `JSONDecoder.default`/`JSONEncoder.default` already apply
  `.convertFromSnakeCase`/`.convertToSnakeCase`, confirmed in
  `Sources/LocalReceiptParsing/DataConverters/Codable+Extensions.swift:98`, so a JSON key of
  `haptic_feedback_enabled` matches automatically, same as the existing `isSelectedByDefault`
  case). Touch points: stored property, `init` param (`= nil`), `hash(into:)`, `==`, `CodingKeys`.
- **`TabControlButtonComponent`** (`Sources/Paywalls/Components/PaywallTabsComponent.swift:19-46`):
  no explicit `CodingKeys` (relies on synthesized `Codable` + the global snake_case conversion
  strategy) — adding the property is sufficient for decoding; still needs manual `hash(into:)`/`==`
  updates since those are hand-rolled. Touch points: property, `init` param, `hash(into:)`, `==`.
- **`TabControlToggleComponent`** (same file, `:48-88`): same 4 touch points. Leave the existing
  unused `defaultValue: Bool` init parameter alone — pre-existing, unrelated oddity.
- `PaywallComponentBase`'s shared `init(from:)`/`encode(to:)` dispatcher
  (`Sources/Paywalls/Components/Common/PaywallComponentBase.swift`) needs no changes — it already
  routes `.package`/`.tabControlButton`/`.tabControlToggle` to each type's own `Codable`
  conformance.

Wire JSON key for all three: `haptic_feedback_enabled`.

### 3. View model wiring

- `PackageComponentViewModel` (`RevenueCatUI/Templates/V2/Components/Packages/Package/PackageComponentViewModel.swift:22-57`)
  flattens component fields into its own properties. Add
  `let hapticFeedbackEnabled: Bool` set as `component.hapticFeedbackEnabled ?? true` in `init`.
- `TabControlButtonComponentViewModel` / `TabControlToggleComponentViewModel` already keep a raw
  `component` reference — no view model change needed; views read
  `viewModel.component.hapticFeedbackEnabled ?? true` directly.

### 4. Call sites — gated by an actual-change check, not just the tap

**`PackageComponentView.swift`**: the flag has to be threaded through the private
`packageSelectorIfNeeded(...)` view modifier and `PackageSelectorIfNeeded` struct
(`:81-152`), which currently take `packageContext`/`package`/`componentName`/`hasPurchaseButton`
but not view-model-level flags. Add a `hapticFeedbackEnabled: Bool` param to both, passed from
`PackageComponentView.body` (`:81-86`) as `hapticFeedbackEnabled: self.viewModel.hapticFeedbackEnabled`.

Inside the `Button` action (`:128-146`), the haptic fires **inside the existing**
`if origin?.identifier != self.package.identifier` **guard** (`:132-133`) that already scopes the
analytics call — this guard is the "did selection actually change" check; re-tapping the
already-selected package must stay silent (no haptic), same as native controls.

```swift
let origin = self.packageContext.package
if origin?.identifier != self.package.identifier {
    self.componentInteractionLogger(...)
    if self.hapticFeedbackEnabled {
        self.hapticFeedback()
    }
}
self.packageContext.update(...)
```

**`TabControlButtonComponentView.swift:53-68`**: unlike the package selector, there is currently
**no** origin/destination guard here — `trackTabcomponentInteraction` fires even when tapping the
already-selected tab. For the haptic specifically, add a new guard so re-tapping the same tab
doesn't buzz (this does not change existing analytics behavior, only scopes the new haptic call):

```swift
Button {
    let originTabId = self.tabControlContext.selectedTabId
    let destinationTabId = self.viewModel.component.tabId

    self.tabControlContext.selectedTabId = destinationTabId
    self.trackTabcomponentInteraction(originTabId: originTabId, destinationTabId: destinationTabId)
    if originTabId != destinationTabId, self.viewModel.component.hapticFeedbackEnabled ?? true {
        self.hapticFeedback()
    }
}
```

**`TabControlToggleComponentView.swift:46-65`**: the `Binding<Bool>` setter is only invoked when
the toggle's `isOn` actually flips (driven by `configuration.isOn.toggle()` in the custom
`ToggleStyle`), so no extra change-guard is needed here:

```swift
set: { newValue in
    let tabIds = self.tabControlContext.tabIds
    guard tabIds.count >= 2 else { return }

    self.tabControlContext.selectedTabId = newValue ? tabIds[1] : tabIds[0]
    _ = self.componentInteractionLogger(...)
    if self.viewModel.component.hapticFeedbackEnabled ?? true {
        self.hapticFeedback()
    }
}
```

All three views gain `@Environment(\.packageSelectionHapticFeedback) private var hapticFeedback`.

### 5. Out of scope

V1 templates (`Template2/4/5/7View.swift`), `WatchTemplateView.swift` (separate `WKInterfaceDevice`
API), `CarouselComponentView.swift` (generic pager, not inherently a package selector). Dashboard
editor UI work is a separate repo — this PR's job ends at correctly decoding and honoring the new
field.

## Testing

No existing Codable/equality unit tests cover `PackageComponent`, `TabControlButtonComponent`, or
`TabControlToggleComponent` today (confirmed: nothing under `Tests/UnitTests/Paywalls/Components/`
references them). New test files following the existing `ImageComponentTests.swift` pattern
(JSON fixture + `JSONDecoder.default` decode + `encodeAndDecode()` round trip + equality):

- `Tests/UnitTests/Paywalls/Components/PackageComponentTests.swift` +
  `Tests/UnitTests/Paywalls/Components/JSON/PackageComponent.json` — cover
  `haptic_feedback_enabled` present-true / present-false / absent (decodes to `nil`).
- `Tests/UnitTests/Paywalls/Components/TabsComponentTests.swift` +
  corresponding JSON fixtures for `TabControlButtonComponent` / `TabControlToggleComponent` —
  same three cases.

View-level tests (in or near `Tests/RevenueCatUITests/PaywallsV2/PackageComponentViewTests.swift`
and a new equivalent for the tab views) inject a spy `PackageSelectionHapticFeedback` via
`.environment(\.packageSelectionHapticFeedback, ...)` and assert:
- Fires exactly once when selection actually changes (flag `true`/absent).
- Does **not** fire when the flag is explicitly `false`.
- Does **not** fire when tapping the already-selected package/tab again.

New test files are picked up automatically by both SPM (`swift test`) and the Tuist-generated
workspace (glob-based `Project.swift` sources) — no manual project file editing expected, but run
`tuist generate` before building after adding files, and confirm `swift build`/`swift test` still
pass.

## Editor / dashboard coordination

Out of this repo's control. Hand off to the dashboard team: a new optional
`haptic_feedback_enabled: boolean` field on `package`, `tab_control_button`, and
`tab_control_toggle` component JSON; omitted/`null` means on.
