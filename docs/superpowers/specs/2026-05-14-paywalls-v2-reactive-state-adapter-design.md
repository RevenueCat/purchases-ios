# Paywalls V2 Reactive State Adapter Design

## Summary

Paywalls V2 should preserve the current backend JSON format while gaining a reactive, state-driven runtime. The first implementation will add an adapter inside RevenueCatUI that projects existing Paywalls V2 components, overrides, and runtime inputs into scoped state slots. Component views will subscribe to the fields they render instead of asking their view models to recompute whole style objects from broad environment changes.

This design follows the architecture demonstrated by `ios-state-example`: state mutations are requested, optionally gated by the consuming app, committed into keyed state slots, and published as resolved events. It also borrows the POC repository's idea of independent state cells driving view content, styles, and effects. Unlike the POC, this first implementation does not require new server-rendered `state`, `controls`, or `effects` fields in Paywalls V2 JSON.

## Context

Current Paywalls V2 rendering builds an immutable view-model tree once in `PaywallsV2View.createPaywallState(...)`. Each component then calls a `styles(...)` function that merges base component properties with applicable overrides using inputs such as `ComponentViewState`, `ScreenCondition`, selected package ID, intro or promo offer eligibility, countdown time, and custom variables.

This works functionally, but it makes state changes coarse-grained. For example, package selection updates `PackageContext`, and many views can re-evaluate their entire style even if only one field changed. The target architecture is a finer-grained adapter where `selected_package_id`, component visibility, text, color, padding, and similar fields are independent observable values.

## Goals

- Preserve the existing Paywalls V2 JSON payload and decoding behavior for the first implementation.
- Introduce a RevenueCatUI-internal reactive state store that can serve many paywall instances at once.
- Scope all state by paywall instance so copied paywalls with identical component IDs do not affect each other.
- Let consuming applications optionally observe committed paywall state events.
- Let consuming applications optionally gate, reject, or replace proposed paywall state mutations.
- Migrate behavior incrementally, starting with package selection and a small set of component fields.
- Keep existing override semantics as the compatibility source of truth during the migration.

## Non-goals

- Do not add new Paywalls V2 JSON fields in the first implementation.
- Do not require backend, dashboard, or schema changes.
- Do not replace all component view models in one pass.
- Do not make a breaking public API change.
- Do not introduce a global state store shared across unrelated paywall instances without explicit scoping.

## Architecture

### Paywall instance scope

Each `PaywallsV2View` instance creates a `PaywallStateScope` when it is initialized. The scope identifies the runtime paywall instance, not just the server paywall definition.

Suggested fields:

```swift
struct PaywallStateScope: Hashable, Sendable {
    let instanceID: UUID
    let paywallID: String?
    let offeringIdentifier: String
    let paywallRevision: Int?
    let workflowPageID: String?
}
```

`paywallID` comes from `PaywallComponentsData.id`. It should be part of the observable identity because copied paywalls receive a different paywall ID while retaining identical component IDs. `instanceID` remains the runtime collision boundary for the less common but still valid case where the same paywall is rendered more than once at the same time. `offeringIdentifier`, `paywallRevision`, and `workflowPageID` make observation payloads understandable and help consumers distinguish events, but they must not be the only scoping mechanism.

### Component identity

The Paywalls V2 JSON includes an `id` on every component, but the current Swift models do not consistently represent it. The first implementation should add that `id` field to every component model before using the adapter. The adapter then assigns an identity to each component while `ViewModelFactory` walks the component tree.

Suggested fields:

```swift
struct PaywallComponentIdentity: Hashable, Sendable {
    let paywallID: String?
    let componentID: String
    let type: String
    let name: String?
}
```

The stable observable component identity is the combination of paywall ID and component ID. This prevents copied paywalls from muddying state propagation or observability when their component IDs remain identical to the original paywall. `name` remains useful for analytics and debugging, but it is not part of uniqueness because names can be duplicated or absent. Internal state keys still include `PaywallStateScope.instanceID`, so two simultaneous renderings of the same paywall do not share mutable state.

### State keys

Every observable value is addressed by a scoped key.

```swift
struct PaywallStateKey: Hashable, Sendable {
    let scope: PaywallStateScope
    let component: PaywallComponentIdentity
    let field: String
}
```

Global paywall-level values use a synthetic component identity such as `paywall`.

Component field names are generated from override `properties` JSON keys instead of a fixed SDK-authored list. Direct properties map to `component.<property_name>`, and reducers can compose multiple properties into derived fields. For example, an icon override containing `color`, `formats`, and `icon_name` emits direct fields such as `component.color` and can also emit a derived `component.icon_url` field from `formats` + `icon_name`.

Initial important fields generated by existing payloads include:

- `paywall.selected_package_id`
- `component.visible`
- `component.text`
- `component.color`
- `component.background`
- `component.padding`
- `component.margin`
- `component.size`
- `component.font_weight`
- `component.icon_url`

### State values

The first implementation needs a value type that covers current override outputs, mutation inputs, and raw JSON-shaped override properties.

Use a public API-safe shape if exposed, following the existing `CustomVariableValue` pattern: a public struct with static factories and private storage rather than a new public enum. Internally, the store can use an enum if it remains internal.

Suggested internal cases:

- `string(String)`
- `number(Double)`
- `bool(Bool)`
- `packageID(String?)`
- raw JSON object/array/string/number/bool/null values preserved from override `properties`
- `color(DisplayableColorScheme)` or a serializable color wrapper
- `edgeInsets(EdgeInsets)` or a paywall padding wrapper
- `size(PaywallComponent.Size)`
- `rawHashable` only if a strongly typed wrapper is not practical for an early field

The first pass should avoid hardcoding a global field list. It should preserve raw override property values, generate state keys from property names, and add reducer coverage only where the UI has a way to consume the derived field.

### State store

RevenueCatUI adds an internal store similar to `ios-state-example`'s `StateManager`, with improvements for multiple paywalls and composed consumer hooks.

Responsibilities:

- hold keyed state slots
- publish per-key values
- publish committed events
- handle mutation requests
- route proposed mutations through an optional gate
- commit accepted or replacement mutations

Conceptual API:

```swift
final class PaywallStateStore: ObservableObject {
    func value(for key: PaywallStateKey) -> PaywallStateValue?
    func publisher(for key: PaywallStateKey) -> AnyPublisher<PaywallStateValue?, Never>
    func request(_ mutation: PaywallStateMutation, details: PaywallStateChangeDetails)
    var resolvedEvents: AnyPublisher<PaywallStateChange, Never> { get }
}
```

Important implementation rules:

- Do not store one mutable interceptor directly on the store in a way that nested views can overwrite.
- Resolve app gates outside internal locks or serial queues.
- If a proposal is replaced with a different key, compute the replacement old value from the replacement key.
- A proposal can resolve only once.
- Default behavior accepts mutations immediately.

### Consumer hooks

The SwiftUI API should eventually mirror existing RevenueCatUI gate modifiers such as `.onPurchaseInitiated` and `.onRestoreInitiated`. Until the behavior and surface area are fully worked out, these hooks and their data types should be exposed only as `@_spi(Internal) public`, not regular `public` API.

Proposed initial SPI shape:

```swift
PaywallView()
    .onPaywallStateChange { change in
        // observe committed changes
    }
    .onPaywallStateMutation { proposal in
        proposal.accept()
    }
```

The mutation hook receives a proposal that supports:

- `accept()`
- `reject()`
- `replace(with:)`

Committed events include:

- paywall instance ID
- offering identifier
- paywall revision
- workflow page ID, when available
- component identity
- field
- old value
- new value
- source details, such as package row tap or derived rule evaluation

The event/proposal types should avoid new public enums unless the team explicitly accepts the API stability risk. If these move from SPI to stable public API later, prefer public structs with static factories or other API-stable shapes.

### Adapter flow

The adapter has two layers.

#### Source state bridge

Existing broad runtime inputs become state slots:

- selected package ID
- screen condition
- custom variables used by condition evaluation
- intro offer eligibility per package
- promo offer eligibility per package
- countdown time

The first implementation should prioritize selected package ID because it is directly user-controlled and already drives override changes.

Package selection has one important existing special case: package selection inside a presented sheet is temporary. Today `RootView` resets `PackageContext.package` when a bottom sheet is dismissed, restoring the workflow-selected package or the paywall default package. The adapter must preserve that behavior by distinguishing root package selection from sheet-scoped package selection.

Suggested package selection keys:

- `paywall.root_selected_package_id`
- `paywall.sheet[componentID].selected_package_id`

When a sheet is visible, sheet content should read and write the sheet-scoped selected package slot. When the sheet is dismissed, the active package context switches back to the root selected package, using the same workflow/default restoration rule that `RootView` uses today. Sheet selection proposals should include the sheet component ID in their details so apps can observe or gate them separately from root package selection.

#### Derived field projection

Existing `PresentedPartial.buildPartial(...)` semantics remain the compatibility source. The adapter evaluates the same rules, but writes fields into state slots based on the selected override's raw `properties` keys.

Example for a text component:

1. Read source slots: selected package ID, component state, screen condition, eligibility, custom variables.
2. Evaluate the component's existing overrides using the same condition order and combination semantics.
3. Produce projected field values from raw property keys: for example `visible` -> `component.visible`, `text` -> `component.text`, and reducer-derived fields like `icon_name` + `formats` -> `component.icon_url`.
4. Commit only fields whose values changed.
5. The SwiftUI text view observes the projected field slots it renders.

This allows component-by-component migration. A component can continue using `styles(...)` until it has a reactive projection.

## Initial migration slice

### Phase 1: Internal primitives and scoping

Add the state store, state keys, scoped identities, mutation proposal, and event pipeline. Inject one store per `PaywallsV2View` instance through the environment. No component behavior changes yet.

### Phase 2: Component IDs in models

Add the JSON `id` field to all Paywalls V2 component models and carry that ID into `PaywallComponentIdentity`. This is a prerequisite for state observability and avoids deriving identity from structural paths.

### Phase 3: Package selection bridge

Change package row selection so it requests a mutation for `paywall.root_selected_package_id` or `paywall.sheet[componentID].selected_package_id`, depending on whether the row is rendered in the root paywall or a presented sheet. On commit, bridge the active selected package ID back into `PackageContext`.

This proves:

- app gates can reject package changes
- app gates can replace selected package changes
- committed events include paywall and component scope
- duplicate paywall instances do not share selection state
- sheet package selection does not leak into root package selection after dismissal

### Phase 4: Reactive text fields

Add a projected style object or field observers for `TextComponentView`. Start with:

- visible
- text
- color
- font weight
- padding
- margin

The legacy `TextComponentViewModel.styles(...)` path remains available while the component is behind the adapter or a feature flag.

### Phase 5: Stack and package visibility

Move `StackComponentView` and `PackageComponentViewModel.visible(...)` to projected `visible` slots. This makes conditional sections and package rows update independently.

### Phase 6: Expand field coverage

Migrate additional component types and fields according to observed value:

- image visibility and URL-related fields
- button disabled or visible state
- carousel and tabs selection
- background, border, shadow, badge, and layout fields

## Testing strategy

Unit tests should cover the state store first:

- a request without a gate commits immediately
- a gate can accept a mutation
- a gate can reject a mutation
- a gate can replace value and key
- a proposal resolves only once
- replacement old value comes from the replacement key
- committed events include scope and details

Adapter tests should cover Paywalls V2 behavior:

- two `PaywallsV2View` instances with copied component IDs maintain independent selected package state
- two copied paywalls with different paywall IDs and identical component IDs produce distinct observable component identities
- package row tap emits a proposed mutation
- rejecting the proposal leaves the selected package unchanged
- replacing the proposal selects the replacement package
- committed selection updates `PackageContext`
- sheet-scoped package selection is restored to the root workflow/default package when the sheet dismisses
- text override projection matches the legacy `styles(...)` result for the same inputs
- custom variable conditions keep their current missing-variable semantics
- unsupported condition discard behavior remains unchanged

Snapshot or lightweight SwiftUI tests should be added only after the first component slice is stable.

## Risks and mitigations

### Public API stability

New public Swift enums are source-breaking in this SDK's build model. The first implementation should keep consumer-facing state APIs behind `@_spi(Internal) public`. If those APIs graduate to stable public API later, event and value APIs should use structs with static factories or keep enum-like details internal.

### State fan-out

Projecting every field for every component can create many slots. The first implementation should project only fields needed by migrated components, and only commit changed values.

### Rule divergence

The adapter must not reimplement override semantics differently. It should call or share logic with `PresentedPartial.buildPartial(...)` and existing partial combination code.

### Multi-paywall collision

Component IDs cannot be trusted as globally unique runtime keys because copied paywalls can retain identical component IDs. Observable component identity must include paywall ID plus component ID, and every mutable state key must also include `PaywallStateScope.instanceID`.

### Gate deadlocks

The gate callback must not run while the store holds locks. Default acceptance should remain synchronous and simple, but app-provided gates must be able to resolve asynchronously.

## Acceptance criteria

- Existing Paywalls V2 JSON decodes and renders without schema changes.
- Paywalls V2 component models expose the JSON component `id` field needed for state identity.
- A paywall instance has an isolated state scope.
- Root and sheet-scoped package selection can be observed and gated through the new pipeline.
- Two copied paywall instances with identical component IDs do not cross-update.
- The first migrated component field projection matches existing override behavior.
- Existing purchase, restore, and component interaction APIs continue to work.
