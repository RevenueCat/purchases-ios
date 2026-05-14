# Paywalls V2 Reactive State Adapter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first backward-compatible Paywalls V2 reactive state adapter without changing the existing Paywalls V2 JSON payload shape.

**Architecture:** Add an internal RevenueCatUI state pipeline scoped by paywall instance, paywall ID, component ID, and field. Preserve existing override semantics while migrating package selection and a first text-field projection through request/gate/commit state changes.

**Tech Stack:** Swift, SwiftUI, Combine, XCTest, Nimble, existing RevenueCatUI Paywalls V2 models.

---

## Spec source

Design document: `docs/superpowers/specs/2026-05-14-paywalls-v2-reactive-state-adapter-design.md`

This plan implements the approved first slice:

- Preserve existing Paywalls V2 JSON compatibility.
- Add component `id` to all Paywalls V2 component models.
- Keep initial consumer hooks `@_spi(Internal) public`.
- Support root and sheet-scoped package selection.
- Add a first text projection that can be compared against legacy `styles(...)`.

## File structure

### Create

- `RevenueCatUI/Templates/V2/State/PaywallStateScope.swift`  
  Runtime paywall scope with `instanceID`, `paywallID`, `offeringIdentifier`, `paywallRevision`, and optional workflow page ID.

- `RevenueCatUI/Templates/V2/State/PaywallComponentIdentity.swift`  
  Observable identity using paywall ID + component ID + type + optional name.

- `RevenueCatUI/Templates/V2/State/PaywallStateKey.swift`  
  Scoped state slot key with factory helpers for paywall-level and component-level fields.

- `RevenueCatUI/Templates/V2/State/PaywallStateValue.swift`  
  Internal value representation for strings, numbers, bools, package IDs, and a first small style set.

- `RevenueCatUI/Templates/V2/State/PaywallStateMutation.swift`  
  Mutation, change details, proposed/committed change, and proposal resolution model.

- `RevenueCatUI/Templates/V2/State/PaywallStateStore.swift`  
  Combine-backed store with request, gate, commit, per-key publisher, and resolved events.

- `RevenueCatUI/Templates/V2/State/PaywallStateEnvironment.swift`  
  SwiftUI environment keys for the store, scope, mutation handler, and committed event observer.

- `RevenueCatUI/Templates/V2/State/PaywallStateViewModifiers.swift`  
  SPI view modifiers: `.onPaywallStateChange` and `.onPaywallStateMutation`.

- `RevenueCatUI/Templates/V2/State/PaywallComponentIdentityFactory.swift`  
  Helpers to derive identities from component models after component IDs are represented everywhere.

- `RevenueCatUI/Templates/V2/State/PaywallPackageSelectionCoordinator.swift`  
  Bridge between state store selection slots and `PackageContext`, including sheet-scoped selection.

- `Tests/RevenueCatUITests/PaywallsV2/PaywallStateStoreTests.swift`  
  Store unit tests.

- `Tests/RevenueCatUITests/PaywallsV2/PaywallComponentIdentityTests.swift`  
  Identity tests for paywall ID + component ID behavior.

- `Tests/RevenueCatUITests/PaywallsV2/PaywallPackageSelectionCoordinatorTests.swift`  
  Root and sheet package selection bridge tests.

### Modify

- `Sources/Paywalls/Components/PaywallTextComponent.swift`
- `Sources/Paywalls/Components/PaywallImageComponent.swift`
- `Sources/Paywalls/Components/PaywallIconComponent.swift`
- `Sources/Paywalls/Components/PaywallStackComponent.swift`
- `Sources/Paywalls/Components/PaywallButtonComponent.swift`
- `Sources/Paywalls/Components/PaywallPackageComponent.swift`
- `Sources/Paywalls/Components/PaywallPurchaseButtonComponent.swift`
- `Sources/Paywalls/Components/PaywallStickyFooterComponent.swift`
- `Sources/Paywalls/Components/PaywallTimelineComponent.swift`
- `Sources/Paywalls/Components/PaywallTabsComponent.swift`
- `Sources/Paywalls/Components/PaywallCarouselComponent.swift`
- `Sources/Paywalls/Components/PaywallVideoComponent.swift`
- `Sources/Paywalls/Components/PaywallCountdownComponent.swift`  
  Add `public let id: String` or `public let id: String?` depending on current JSON requirements. Decode and encode `id` without changing the JSON payload shape.

- `RevenueCatUI/Templates/V2/PaywallsV2View.swift`  
  Create and inject `PaywallStateScope`, `PaywallStateStore`, and package selection coordinator.

- `RevenueCatUI/Templates/V2/ViewModelHelpers/ViewModelFactory.swift`  
  Carry `PaywallComponentIdentity` through view-model creation.

- `RevenueCatUI/Templates/V2/ViewModelHelpers/PaywallComponentViewModel.swift`  
  Expose identity on component view-model cases where needed.

- `RevenueCatUI/Templates/V2/Components/Packages/Package/PackageComponentView.swift`  
  Route package row selection through the state store instead of directly mutating root `PackageContext`.

- `RevenueCatUI/Templates/V2/Components/Root/RootView.swift`
- `RevenueCatUI/Templates/V2/Components/Button/BottomSheetView.swift`
- `RevenueCatUI/Templates/V2/Components/Button/ButtonComponentView.swift`  
  Mark and preserve sheet-scoped selection behavior.

- `RevenueCatUI/Templates/V2/Components/Text/TextComponentViewModel.swift`
- `RevenueCatUI/Templates/V2/Components/Text/TextComponentView.swift`  
  Add a first reactive text projection while keeping legacy `styles(...)` as the comparison/fallback path.

> **Review (incomplete modify list):** Three component types are nested inside `Sources/Paywalls/Components/PaywallTabsComponent.swift` — `TabControlComponent`, `TabControlButtonComponent`, `TabControlToggleComponent` — and `PaywallComponentIdentityFactory` already references all three. They each need the `id` field. The plan only lists `PaywallTabsComponent.swift`, which is correct file-wise but doesn't make the nested-type work explicit. Also: `Sources/Paywalls/Components/PaywallHeaderComponent.swift` exists but isn't mentioned — clarify whether the type is dead code (since `PaywallComponent.fallbackHeader` has no associated value) or whether it needs `id`. Lastly, confirm `RevenueCatUI/Templates/V2/WorkflowPaywallView.swift` and `Sources/Paywalls/PaywallV2CacheWarming.swift` don't construct components in a way that requires updates.

- `Tests/RevenueCatUITests/PaywallsV2/ViewModelFactoryTests.swift`
- `Tests/RevenueCatUITests/PaywallsV2/PackageComponentViewTests.swift`
- `Tests/RevenueCatUITests/PaywallsV2/TextComponentLocalizationTests.swift`  
  Add focused coverage around identity, package selection, and text projection.

---

## Task 1: Add state scope, identity, key, and value primitives

**Files:**
- Create: `RevenueCatUI/Templates/V2/State/PaywallStateScope.swift`
- Create: `RevenueCatUI/Templates/V2/State/PaywallComponentIdentity.swift`
- Create: `RevenueCatUI/Templates/V2/State/PaywallStateKey.swift`
- Create: `RevenueCatUI/Templates/V2/State/PaywallStateValue.swift`
- Test: `Tests/RevenueCatUITests/PaywallsV2/PaywallComponentIdentityTests.swift`

- [ ] **Step 1: Write identity tests**

Create `Tests/RevenueCatUITests/PaywallsV2/PaywallComponentIdentityTests.swift`:

```swift
@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PaywallComponentIdentityTests: TestCase {

    func testCopiedPaywallsWithSameComponentIDHaveDifferentObservableIdentity() {
        let original = PaywallComponentIdentity(
            paywallID: "paywall_original",
            componentID: "component_title",
            type: "text",
            name: "Title"
        )
        let copy = PaywallComponentIdentity(
            paywallID: "paywall_copy",
            componentID: "component_title",
            type: "text",
            name: "Title"
        )

        XCTAssertNotEqual(original, copy)
    }

    func testSamePaywallAndComponentIDHaveSameObservableIdentity() {
        let left = PaywallComponentIdentity(
            paywallID: "paywall_a",
            componentID: "component_title",
            type: "text",
            name: "First"
        )
        let right = PaywallComponentIdentity(
            paywallID: "paywall_a",
            componentID: "component_title",
            type: "text",
            name: "Renamed"
        )

        XCTAssertEqual(left, right)
    }

    func testRuntimeScopesSeparateSamePaywallRenderedTwice() {
        let identity = PaywallComponentIdentity(
            paywallID: "paywall_a",
            componentID: "component_title",
            type: "text",
            name: nil
        )
        let firstScope = PaywallStateScope(
            instanceID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            paywallID: "paywall_a",
            offeringIdentifier: "default",
            paywallRevision: 7,
            workflowPageID: nil
        )
        let secondScope = PaywallStateScope(
            instanceID: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            paywallID: "paywall_a",
            offeringIdentifier: "default",
            paywallRevision: 7,
            workflowPageID: nil
        )

        XCTAssertNotEqual(
            PaywallStateKey(scope: firstScope, component: identity, field: .componentVisible),
            PaywallStateKey(scope: secondScope, component: identity, field: .componentVisible)
        )
    }

}

#endif
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
swift test --filter PaywallComponentIdentityTests
```

Expected: fail to compile because `PaywallComponentIdentity`, `PaywallStateScope`, `PaywallStateKey`, and `PaywallStateKey.Field.componentVisible` do not exist.

- [ ] **Step 3: Add `PaywallStateScope`**

Create `RevenueCatUI/Templates/V2/State/PaywallStateScope.swift`:

```swift
@_spi(Internal) import RevenueCat
import Foundation

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public struct PaywallStateScope: Hashable, Sendable {

    @_spi(Internal) public let instanceID: UUID
    @_spi(Internal) public let paywallID: String?
    @_spi(Internal) public let offeringIdentifier: String
    @_spi(Internal) public let paywallRevision: Int?
    @_spi(Internal) public let workflowPageID: String?

    @_spi(Internal)
    public init(
        instanceID: UUID = UUID(),
        paywallID: String?,
        offeringIdentifier: String,
        paywallRevision: Int?,
        workflowPageID: String?
    ) {
        self.instanceID = instanceID
        self.paywallID = paywallID
        self.offeringIdentifier = offeringIdentifier
        self.paywallRevision = paywallRevision
        self.workflowPageID = workflowPageID
    }

}

#endif
```

- [ ] **Step 4: Add `PaywallComponentIdentity`**

Create `RevenueCatUI/Templates/V2/State/PaywallComponentIdentity.swift`:

```swift
import Foundation

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public struct PaywallComponentIdentity: Hashable, Sendable {

    @_spi(Internal) public let paywallID: String?
    @_spi(Internal) public let componentID: String
    @_spi(Internal) public let type: String
    @_spi(Internal) public let name: String?

    @_spi(Internal)
    public init(
        paywallID: String?,
        componentID: String,
        type: String,
        name: String?
    ) {
        self.paywallID = paywallID
        self.componentID = componentID
        self.type = type
        self.name = name
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.paywallID == rhs.paywallID &&
            lhs.componentID == rhs.componentID &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(paywallID)
        hasher.combine(componentID)
        hasher.combine(type)
    }

}

#endif
```

- [ ] **Step 5: Add `PaywallStateKey`**

Create `RevenueCatUI/Templates/V2/State/PaywallStateKey.swift`:

```swift
import Foundation

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public struct PaywallStateKey: Hashable, Sendable {

    @_spi(Internal) public struct Field: Hashable, Sendable, RawRepresentable {
        @_spi(Internal) public let rawValue: String

        @_spi(Internal) public init(rawValue: String) {
            self.rawValue = rawValue
        }

        @_spi(Internal) public static let rootSelectedPackageID = Field(rawValue: "paywall.root_selected_package_id")
        @_spi(Internal) public static let componentVisible = Field(rawValue: "component.visible")
        @_spi(Internal) public static let componentText = Field(rawValue: "component.text")
        @_spi(Internal) public static let componentColor = Field(rawValue: "component.color")
        @_spi(Internal) public static let componentFontWeight = Field(rawValue: "component.font_weight")
        @_spi(Internal) public static let componentPadding = Field(rawValue: "component.padding")
        @_spi(Internal) public static let componentMargin = Field(rawValue: "component.margin")

        @_spi(Internal)
        public static func sheetSelectedPackageID(componentID: String) -> Field {
            Field(rawValue: "paywall.sheet[\(componentID)].selected_package_id")
        }
    }

    @_spi(Internal) public let scope: PaywallStateScope
    @_spi(Internal) public let component: PaywallComponentIdentity
    @_spi(Internal) public let field: Field

    @_spi(Internal)
    public init(scope: PaywallStateScope, component: PaywallComponentIdentity, field: Field) {
        self.scope = scope
        self.component = component
        self.field = field
    }

    @_spi(Internal)
    public static func paywall(scope: PaywallStateScope, field: Field) -> PaywallStateKey {
        PaywallStateKey(
            scope: scope,
            component: PaywallComponentIdentity(
                paywallID: scope.paywallID,
                componentID: "paywall",
                type: "paywall",
                name: nil
            ),
            field: field
        )
    }

}

#endif
```

- [ ] **Step 6: Add `PaywallStateValue`**

> **Review:** `PaywallStateValue` is declared `internal` (no access modifier), but Task 2 exposes it through `@_spi(Internal) public` types (`PaywallStateChange.oldValue`/`.newValue`, `PaywallStateMutation` via `PaywallStateMutationProposal.replace(with:)`). Confirmed via compiler: `error: property cannot be declared public because its type uses an internal type`. `@_spi` is still `public` for access-control. Promote `PaywallStateValue` and `PaywallStateMutation` to `@_spi(Internal) public`, and per the design doc, prefer the `CustomVariableValue` shape (public struct with static factories, private storage) over a raw enum so a future graduation to stable public API doesn't require an `@frozen`-breaking case addition.

Create `RevenueCatUI/Templates/V2/State/PaywallStateValue.swift`:

```swift
import Foundation
import SwiftUI

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum PaywallStateValue: Hashable, Sendable {

    case string(String)
    case number(Double)
    case bool(Bool)
    case packageID(String?)
    case fontWeight(Font.Weight)
    case edgeInsets(EdgeInsets)

    var packageID: String? {
        guard case .packageID(let value) = self else { return nil }
        return value
    }

    var boolValue: Bool? {
        guard case .bool(let value) = self else { return nil }
        return value
    }

    var stringValue: String? {
        guard case .string(let value) = self else { return nil }
        return value
    }

}

#endif
```

- [ ] **Step 7: Run test to verify it passes**

Run:

```bash
swift test --filter PaywallComponentIdentityTests
```

Expected: pass for `PaywallComponentIdentityTests`.

- [ ] **Step 8: Commit**

```bash
git add RevenueCatUI/Templates/V2/State Tests/RevenueCatUITests/PaywallsV2/PaywallComponentIdentityTests.swift
git commit -m "feat: add paywalls reactive state identity primitives"
```

---

## Task 2: Add the reactive state store and proposal model

**Files:**
- Create: `RevenueCatUI/Templates/V2/State/PaywallStateMutation.swift`
- Create: `RevenueCatUI/Templates/V2/State/PaywallStateStore.swift`
- Test: `Tests/RevenueCatUITests/PaywallsV2/PaywallStateStoreTests.swift`

- [ ] **Step 1: Write failing state store tests**

Create `Tests/RevenueCatUITests/PaywallsV2/PaywallStateStoreTests.swift`:

```swift
import Combine
@testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PaywallStateStoreTests: TestCase {

    private var cancellables: Set<AnyCancellable> = []

    func testRequestWithoutGateCommitsImmediately() {
        let key = Self.makeKey(field: .componentVisible)
        let store = PaywallStateStore(initialValues: [key: .bool(true)])
        var events: [PaywallStateChange] = []
        store.resolvedEvents.sink { events.append($0) }.store(in: &cancellables)

        store.request(.init(key: key, value: .bool(false)), details: .init(source: "test"))

        XCTAssertEqual(store.value(for: key), .bool(false))
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.oldValue, .bool(true))
        XCTAssertEqual(events.first?.newValue, .bool(false))
    }

    func testGateCanRejectMutation() {
        let key = Self.makeKey(field: .componentVisible)
        let store = PaywallStateStore(initialValues: [key: .bool(true)])
        store.mutationHandler = PaywallStateMutationHandler { proposal in
            proposal.reject()
        }

        store.request(.init(key: key, value: .bool(false)), details: .init(source: "test"))

        XCTAssertEqual(store.value(for: key), .bool(true))
    }

    func testGateCanReplaceMutationAndUsesReplacementOldValue() {
        let originalKey = Self.makeKey(field: .componentVisible)
        let replacementKey = Self.makeKey(field: .componentText)
        let store = PaywallStateStore(initialValues: [
            originalKey: .bool(true),
            replacementKey: .string("old")
        ])
        var events: [PaywallStateChange] = []
        store.resolvedEvents.sink { events.append($0) }.store(in: &cancellables)
        store.mutationHandler = PaywallStateMutationHandler { proposal in
            proposal.replace(with: .init(key: replacementKey, value: .string("new")))
        }

        store.request(.init(key: originalKey, value: .bool(false)), details: .init(source: "test"))

        XCTAssertEqual(store.value(for: originalKey), .bool(true))
        XCTAssertEqual(store.value(for: replacementKey), .string("new"))
        XCTAssertEqual(events.first?.key, replacementKey)
        XCTAssertEqual(events.first?.oldValue, .string("old"))
        XCTAssertEqual(events.first?.newValue, .string("new"))
    }

    func testProposalCanResolveOnlyOnce() {
        let key = Self.makeKey(field: .componentVisible)
        let store = PaywallStateStore(initialValues: [key: .bool(true)])
        store.mutationHandler = PaywallStateMutationHandler { proposal in
            proposal.accept()
            proposal.reject()
            proposal.replace(with: .init(key: key, value: .bool(true)))
        }

        store.request(.init(key: key, value: .bool(false)), details: .init(source: "test"))

        XCTAssertEqual(store.value(for: key), .bool(false))
    }

    private static func makeKey(field: PaywallStateKey.Field) -> PaywallStateKey {
        let scope = PaywallStateScope(
            instanceID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            paywallID: "paywall_a",
            offeringIdentifier: "default",
            paywallRevision: 1,
            workflowPageID: nil
        )
        return .init(
            scope: scope,
            component: .init(
                paywallID: "paywall_a",
                componentID: "component_a",
                type: "text",
                name: nil
            ),
            field: field
        )
    }

}

#endif
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
swift test --filter PaywallStateStoreTests
```

Expected: fail to compile because store and mutation types do not exist.

- [ ] **Step 3: Add mutation and proposal types**

> **Review (mutationHandler ownership):** Storing `var mutationHandler` directly on `PaywallStateStore` violates the design doc's explicit rule: *"Do not store one mutable interceptor directly on the store in a way that nested views can overwrite."* Task 3 sets `store.mutationHandler = …` from `.onAppear`, which means a nested `PaywallsV2View` (workflow exit offer, embedded paywall) can silently overwrite the outer handler. Read the handler from the SwiftUI environment at request time, or have an outer coordinator own it and call into the store.

> **Review (silent-drop hazard):** A non-nil `PaywallStateMutationHandler` that never calls `accept()` / `reject()` / `replace(with:)` causes the proposal to be silently dropped — the store has no timeout or default. Document the contract explicitly, add a `DEBUG`-only assertion if the proposal is deinit'd unresolved, or fall back to accept on deinit. Otherwise an app passing an async gate that forgets to resolve will look like "package taps do nothing" in production.

Create `RevenueCatUI/Templates/V2/State/PaywallStateMutation.swift`:

```swift
import Foundation

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallStateMutation: Hashable, Sendable {
    let key: PaywallStateKey
    let value: PaywallStateValue?
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public struct PaywallStateChangeDetails: Hashable, Sendable {
    @_spi(Internal) public let source: String
    @_spi(Internal) public let sheetComponentID: String?

    @_spi(Internal)
    public init(source: String, sheetComponentID: String? = nil) {
        self.source = source
        self.sheetComponentID = sheetComponentID
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public struct PaywallStateChange: Hashable, Sendable {
    @_spi(Internal) public let key: PaywallStateKey
    @_spi(Internal) public let oldValue: PaywallStateValue?
    @_spi(Internal) public let newValue: PaywallStateValue?
    @_spi(Internal) public let details: PaywallStateChangeDetails
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public struct PaywallStateMutationHandler {
    private let action: @Sendable (PaywallStateMutationProposal) -> Void

    @_spi(Internal)
    public init(action: @escaping @Sendable (PaywallStateMutationProposal) -> Void) {
        self.action = action
    }

    func callAsFunction(_ proposal: PaywallStateMutationProposal) {
        self.action(proposal)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public final class PaywallStateMutationProposal: @unchecked Sendable {
    @_spi(Internal) public let change: PaywallStateChange

    private let lock = NSLock()
    private var resolve: ((Resolution) -> Void)?

    init(change: PaywallStateChange, resolve: @escaping (Resolution) -> Void) {
        self.change = change
        self.resolve = resolve
    }

    @_spi(Internal) public func accept() {
        self.handle(.accept)
    }

    @_spi(Internal) public func reject() {
        self.handle(.reject)
    }

    @_spi(Internal) public func replace(with mutation: PaywallStateMutation) {
        self.handle(.replace(mutation))
    }

    private func handle(_ resolution: Resolution) {
        let callback: ((Resolution) -> Void)? = lock.withLock {
            let callback = self.resolve
            self.resolve = nil
            return callback
        }
        callback?(resolution)
    }

    enum Resolution {
        case accept
        case reject
        case replace(PaywallStateMutation)
    }
}

#endif
```

- [ ] **Step 4: Add state store**

Create `RevenueCatUI/Templates/V2/State/PaywallStateStore.swift`:

```swift
import Combine
import Foundation

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PaywallStateStore: ObservableObject {

    var mutationHandler: PaywallStateMutationHandler?

    private let lock = NSLock()
    private var subjects: [PaywallStateKey: CurrentValueSubject<PaywallStateValue?, Never>]
    private let resolvedEventsSubject = PassthroughSubject<PaywallStateChange, Never>()

    init(initialValues: [PaywallStateKey: PaywallStateValue?] = [:]) {
        self.subjects = initialValues.mapValues { CurrentValueSubject<PaywallStateValue?, Never>($0) }
    }

    var resolvedEvents: AnyPublisher<PaywallStateChange, Never> {
        self.resolvedEventsSubject.eraseToAnyPublisher()
    }

    func value(for key: PaywallStateKey) -> PaywallStateValue? {
        self.lock.withLock {
            self.subjects[key]?.value
        }
    }

    func publisher(for key: PaywallStateKey) -> AnyPublisher<PaywallStateValue?, Never> {
        self.subject(for: key).eraseToAnyPublisher()
    }

    func request(_ mutation: PaywallStateMutation, details: PaywallStateChangeDetails) {
        let proposedChange = PaywallStateChange(
            key: mutation.key,
            oldValue: self.value(for: mutation.key),
            newValue: mutation.value,
            details: details
        )

        guard let mutationHandler else {
            self.commit(mutation, details: details)
            return
        }

        let proposal = PaywallStateMutationProposal(change: proposedChange) { [weak self] resolution in
            switch resolution {
            case .accept:
                self?.commit(mutation, details: details)
            case .reject:
                break
            case .replace(let replacement):
                self?.commit(replacement, details: details)
            }
        }
        mutationHandler(proposal)
    }

    private func commit(_ mutation: PaywallStateMutation, details: PaywallStateChangeDetails) {
        let subject = self.subject(for: mutation.key)
        let oldValue = subject.value
        guard oldValue != mutation.value else { return }

        let change = PaywallStateChange(
            key: mutation.key,
            oldValue: oldValue,
            newValue: mutation.value,
            details: details
        )
        subject.send(mutation.value)
        self.resolvedEventsSubject.send(change)
    }

    private func subject(for key: PaywallStateKey) -> CurrentValueSubject<PaywallStateValue?, Never> {
        self.lock.withLock {
            if let subject = self.subjects[key] {
                return subject
            }
            let subject = CurrentValueSubject<PaywallStateValue?, Never>(nil)
            self.subjects[key] = subject
            return subject
        }
    }

}

#endif
```

- [ ] **Step 5: Run tests to verify they pass**

Run:

```bash
swift test --filter PaywallStateStoreTests
```

Expected: pass for `PaywallStateStoreTests`.

- [ ] **Step 6: Commit**

```bash
git add RevenueCatUI/Templates/V2/State Tests/RevenueCatUITests/PaywallsV2/PaywallStateStoreTests.swift
git commit -m "feat: add paywalls reactive state store"
```

---

## Task 3: Add SPI SwiftUI hooks and environment injection

**Files:**
- Create: `RevenueCatUI/Templates/V2/State/PaywallStateEnvironment.swift`
- Create: `RevenueCatUI/Templates/V2/State/PaywallStateViewModifiers.swift`
- Modify: `RevenueCatUI/Templates/V2/PaywallsV2View.swift`
- Test: `Tests/RevenueCatUITests/PaywallsV2/PaywallStateStoreTests.swift`

- [ ] **Step 1: Add environment tests**

Append to `PaywallStateStoreTests`:

```swift
func testDefaultEnvironmentStoreIsAvailable() {
    let store = PaywallStateStore()
    XCTAssertNil(store.value(for: Self.makeKey(field: .componentVisible)))
}
```

This test is intentionally small; the environment is exercised by compilation when the new keys are used in `PaywallsV2View`.

- [ ] **Step 2: Add environment keys**

> **Review:** `static let defaultValue = PaywallStateStore()` on an `EnvironmentKey` produces a **single process-wide store**, shared by any view that reads `\.paywallStateStore` without an injected value. This directly violates the design doc: *"Do not introduce a global state store shared across unrelated paywall instances without explicit scoping."* Two simultaneous `PaywallsV2View`s (or a workflow with a child paywall, or any test that forgets to inject) would cross-contaminate. Either (a) make the env value `PaywallStateStore?` with `defaultValue = nil` and `fatalError`/precondition at the read site inside V2 code, or (b) drop the custom env key and use `@EnvironmentObject` so SwiftUI's runtime catches missing injection.

Create `RevenueCatUI/Templates/V2/State/PaywallStateEnvironment.swift`:

```swift
import SwiftUI

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallStateStoreKey: EnvironmentKey {
    static let defaultValue = PaywallStateStore()
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallStateMutationHandlerKey: EnvironmentKey {
    static let defaultValue: PaywallStateMutationHandler? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallStateChangeObserverKey: EnvironmentKey {
    static let defaultValue: (@Sendable (PaywallStateChange) -> Void)? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {
    var paywallStateStore: PaywallStateStore {
        get { self[PaywallStateStoreKey.self] }
        set { self[PaywallStateStoreKey.self] = newValue }
    }

    var paywallStateMutationHandler: PaywallStateMutationHandler? {
        get { self[PaywallStateMutationHandlerKey.self] }
        set { self[PaywallStateMutationHandlerKey.self] = newValue }
    }

    var paywallStateChangeObserver: (@Sendable (PaywallStateChange) -> Void)? {
        get { self[PaywallStateChangeObserverKey.self] }
        set { self[PaywallStateChangeObserverKey.self] = newValue }
    }
}

#endif
```

- [ ] **Step 3: Add SPI modifiers**

Create `RevenueCatUI/Templates/V2/State/PaywallStateViewModifiers.swift`:

```swift
import SwiftUI

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public extension View {

    func onPaywallStateChange(
        _ action: @escaping @Sendable (PaywallStateChange) -> Void
    ) -> some View {
        self.environment(\.paywallStateChangeObserver, action)
    }

    func onPaywallStateMutation(
        _ action: @escaping @Sendable (PaywallStateMutationProposal) -> Void
    ) -> some View {
        self.environment(\.paywallStateMutationHandler, PaywallStateMutationHandler(action: action))
    }

}

#endif
```

- [ ] **Step 4: Inject store in `PaywallsV2View`**

Modify `PaywallsV2View`:

```swift
@StateObject
private var paywallStateStore: PaywallStateStore
```

In `init`, create:

```swift
let paywallStateStore = PaywallStateStore()
self._paywallStateStore = .init(wrappedValue: paywallStateStore)
```

In `loadedPaywallView(paywallState:)`, add:

```swift
.environment(\.paywallStateStore, self.paywallStateStore)
.onAppear {
    self.paywallStateStore.mutationHandler = self.paywallStateMutationHandler
}
.onReceive(self.paywallStateStore.resolvedEvents) { change in
    self.paywallStateChangeObserver?(change)
}
```

Also add environment reads:

```swift
@Environment(\.paywallStateMutationHandler)
private var paywallStateMutationHandler

@Environment(\.paywallStateChangeObserver)
private var paywallStateChangeObserver
```

- [ ] **Step 5: Run tests**

Run:

```bash
swift test --filter PaywallStateStoreTests
```

Expected: pass.

- [ ] **Step 6: Commit**

```bash
git add RevenueCatUI/Templates/V2/State RevenueCatUI/Templates/V2/PaywallsV2View.swift Tests/RevenueCatUITests/PaywallsV2/PaywallStateStoreTests.swift
git commit -m "feat: add paywalls state environment hooks"
```

---

## Task 4: Add component IDs to Paywalls V2 models

**Files:**
- Modify all `Sources/Paywalls/Components/Paywall*Component.swift` model files listed in the file structure section.
- Test: `Tests/RevenueCatUITests/PaywallsV2/ConditionDeserializationTests.swift`
- Test: `Tests/RevenueCatUITests/PaywallsV2/ViewModelFactoryTests.swift`

- [ ] **Step 1: Write decoding tests for universal component IDs**

Add to `ConditionDeserializationTests` or create `PaywallComponentIDDecodingTests.swift`:

```swift
@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS)

final class PaywallComponentIDDecodingTests: TestCase {

    func testTextComponentDecodesID() throws {
        let json = """
        {
          "type": "text",
          "id": "text_1",
          "text_lid": "title",
          "fontWeight": "regular",
          "color": { "light": { "type": "hex", "value": "#000000" } },
          "fontSize": 16,
          "horizontalAlignment": "center",
          "size": { "width": { "type": "fill" }, "height": { "type": "fit" } },
          "padding": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
          "margin": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 }
        }
        """.data(using: .utf8)!

        let component = try JSONDecoder().decode(PaywallComponent.self, from: json)

        guard case .text(let text) = component else {
            return XCTFail("Expected text component")
        }
        XCTAssertEqual(text.id, "text_1")
    }

}

#endif
```

- [ ] **Step 2: Run test to verify it fails or exposes missing model fields**

Run:

```bash
swift test --filter PaywallComponentIDDecodingTests
```

Expected: fail to compile or fail assertions because the model does not expose `id`.

- [ ] **Step 3: Add `id` to each component class/struct**

For each component model, add:

```swift
public let id: String
```

Add to `CodingKeys`:

```swift
case id
```

Decode:

```swift
self.id = try container.decode(String.self, forKey: .id)
```

Encode:

```swift
try container.encode(id, forKey: .id)
```

Update initializers with a default for test ergonomics only if existing tests create models directly:

```swift
id: String = UUID().uuidString
```

Prefer explicit IDs in new tests. Preserve existing tests by providing a default value in source initializers.

- [ ] **Step 4: Update factory tests and previews that instantiate components**

Where test clarity matters, pass stable IDs:

```swift
let textWithRule = PaywallComponent.TextComponent(
    id: "text_with_rule",
    text: "badge_text_lid",
    color: Self.black,
    overrides: [
        .init(extendedConditions: [
            .selectedPackage(operator: .in, packages: ["monthly"])
        ], properties: .init(fontWeight: .bold))
    ]
)
```

- [ ] **Step 5: Run targeted component tests**

Run:

```bash
swift test --filter PaywallComponentIDDecodingTests
swift test --filter ViewModelFactoryTests
```

Expected: both pass.

- [ ] **Step 6: Commit**

```bash
git add Sources/Paywalls/Components Tests/RevenueCatUITests/PaywallsV2
git commit -m "feat: expose paywalls v2 component ids"
```

---

> **Review (Task 5 — ViewModelFactory callers):** `ViewModelFactory` is a `struct` at `RevenueCatUI/Templates/V2/ViewModelHelpers/ViewModelFactory.swift:29` with self-recursive `toViewModel(...)` calls at lines 537 and 551. Adding an init parameter — even with `paywallID: String? = nil` defaulted — needs an explicit audit step: every call site that constructs a `ViewModelFactory` (production code, previews, tests) must receive the real paywall ID, not the default, or the identity propagation silently no-ops with `nil`. Add a search step (`rg "ViewModelFactory(" RevenueCatUI Tests`) and enumerate updates before Step 4. Also: the snippet `var factory = ViewModelFactory(paywallID: ...)` uses `var` for a struct — confirm `toViewModel` doesn't need `mutating`, otherwise let it be `let`.

## Task 5: Carry component identity through view-model creation

**Files:**
- Create: `RevenueCatUI/Templates/V2/State/PaywallComponentIdentityFactory.swift`
- Modify: `RevenueCatUI/Templates/V2/ViewModelHelpers/ViewModelFactory.swift`
- Modify: `RevenueCatUI/Templates/V2/ViewModelHelpers/PaywallComponentViewModel.swift`
- Modify component view-model classes to store `identity`.
- Test: `Tests/RevenueCatUITests/PaywallsV2/ViewModelFactoryTests.swift`

- [ ] **Step 1: Write factory identity test**

Add to `ViewModelFactoryTests`:

```swift
@MainActor
func testTextViewModelReceivesPaywallComponentIdentity() throws {
    let text = PaywallComponent.TextComponent(
        id: "text_component",
        text: "title",
        color: Self.black
    )
    var factory = ViewModelFactory(
        paywallID: "paywall_a"
    )

    let viewModel = try factory.toViewModel(
        component: .text(text),
        packageValidator: PackageValidator(),
        purchaseButtonCollector: nil,
        offering: Self.mockOffering,
        localizationProvider: .init(locale: .current, localizedStrings: ["title": .string("Title")]),
        uiConfigProvider: try Self.createUIConfigProvider(),
        colorScheme: .light
    )

    guard case .text(let textViewModel) = viewModel else {
        return XCTFail("Expected text view model")
    }
    XCTAssertEqual(textViewModel.identity.componentID, "text_component")
    XCTAssertEqual(textViewModel.identity.paywallID, "paywall_a")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
swift test --filter ViewModelFactoryTests/testTextViewModelReceivesPaywallComponentIdentity
```

Expected: fail because `ViewModelFactory(paywallID:)` and `TextComponentViewModel.identity` do not exist.

- [ ] **Step 3: Add identity factory**

Create `PaywallComponentIdentityFactory.swift`:

```swift
@_spi(Internal) import RevenueCat
import Foundation

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallComponentIdentityFactory {

    let paywallID: String?

    func identity(for component: PaywallComponent) -> PaywallComponentIdentity {
        switch component {
        case .text(let component):
            return .init(paywallID: paywallID, componentID: component.id, type: "text", name: component.name)
        case .button(let component):
            return .init(paywallID: paywallID, componentID: component.id, type: "button", name: component.name)
        case .package(let component):
            return .init(paywallID: paywallID, componentID: component.id, type: "package", name: component.name)
        case .stack(let component):
            return .init(paywallID: paywallID, componentID: component.id, type: "stack", name: component.name)
        default:
            return .init(paywallID: paywallID, componentID: component.idForStateIdentity, type: component.typeForStateIdentity, name: nil)
        }
    }
}

private extension PaywallComponent {
    var idForStateIdentity: String {
        switch self {
        case .image(let component): return component.id
        case .icon(let component): return component.id
        case .purchaseButton(let component): return component.id
        case .stickyFooter(let component): return component.id
        case .timeline(let component): return component.id
        case .tabs(let component): return component.id
        case .tabControl(let component): return component.id
        case .tabControlButton(let component): return component.id
        case .tabControlToggle(let component): return component.id
        case .carousel(let component): return component.id
        case .video(let component): return component.id
        case .countdown(let component): return component.id
        case .fallbackHeader: return "fallback_header"
        case .text, .button, .package, .stack: fatalError("Handled above")
        }
    }

    var typeForStateIdentity: String {
        switch self {
        case .image: return "image"
        case .icon: return "icon"
        case .purchaseButton: return "purchase_button"
        case .stickyFooter: return "sticky_footer"
        case .timeline: return "timeline"
        case .tabs: return "tabs"
        case .tabControl: return "tab_control"
        case .tabControlButton: return "tab_control_button"
        case .tabControlToggle: return "tab_control_toggle"
        case .carousel: return "carousel"
        case .video: return "video"
        case .countdown: return "countdown"
        case .fallbackHeader: return "fallback_header"
        case .text: return "text"
        case .button: return "button"
        case .package: return "package"
        case .stack: return "stack"
        }
    }
}

#endif
```

- [ ] **Step 4: Update `ViewModelFactory`**

Add property and initializer:

```swift
private let identityFactory: PaywallComponentIdentityFactory

init(paywallID: String? = nil) {
    self.identityFactory = PaywallComponentIdentityFactory(paywallID: paywallID)
}
```

When creating view models:

```swift
let identity = self.identityFactory.identity(for: component)
return .text(
    try TextComponentViewModel(
        identity: identity,
        localizationProvider: localizationProvider,
        uiConfigProvider: uiConfigProvider,
        component: component,
        discardRules: discardRules
    )
)
```

- [ ] **Step 5: Add identity to component view models**

For `TextComponentViewModel`:

```swift
let identity: PaywallComponentIdentity

init(
    identity: PaywallComponentIdentity,
    localizationProvider: LocalizationProvider,
    uiConfigProvider: UIConfigProvider,
    component: PaywallComponent.TextComponent,
    discardRules: Bool = false
) throws {
    self.identity = identity
    self.localizationProvider = localizationProvider
    self.uiConfigProvider = uiConfigProvider
    self.component = component
}
```

Repeat for package, stack, and button view models in this task. Other component view models can receive identity in the later field migration task if making all initializers large becomes too invasive.

- [ ] **Step 6: Pass paywall ID from `PaywallsV2View.createPaywallState`**

Change signature:

```swift
static func createPaywallState(
    paywallID: String?,
    componentsConfig: PaywallComponentsData.PaywallComponentsConfig,
    ...
)
```

Instantiate:

```swift
var factory = ViewModelFactory(paywallID: paywallID)
```

Call with:

```swift
paywallID: paywallComponents.data.id
```

- [ ] **Step 7: Run test**

Run:

```bash
swift test --filter ViewModelFactoryTests/testTextViewModelReceivesPaywallComponentIdentity
```

Expected: pass.

- [ ] **Step 8: Commit**

```bash
git add RevenueCatUI/Templates/V2 Tests/RevenueCatUITests/PaywallsV2/ViewModelFactoryTests.swift
git commit -m "feat: carry paywall component identity through v2 view models"
```

---

> **Review (Task 6 — missing isolation test & sheet-slot cleanup):**
> 1. The design doc's acceptance criteria explicitly require: *"Two `PaywallsV2View` instances with copied component IDs maintain independent selected package state."* The closest test here (`testRuntimeScopesSeparateSamePaywallRenderedTwice` in Task 1) only checks that two `PaywallStateKey`s with different `instanceID`s are unequal — that proves the *key* shape, not end-to-end isolation through a real `PaywallStateStore` + `PaywallPackageSelectionCoordinator` pair driven by package row taps. Add an explicit test that creates two coordinators sharing component IDs but different scopes, mutates one, and asserts the other's `PackageContext` and store slot are untouched.
> 2. `restoreRootSelectionAfterSheetDismiss()` updates `PackageContext` back to root, but leaves the `paywall.sheet[componentID].selected_package_id` slot populated with the last sheet selection. Next presentation of the same sheet will read the stale value (or fire spurious `change` events). Either clear the slot on dismiss, or seed it from the root selection at present time and document the chosen direction.

## Task 6: Add package selection coordinator for root and sheet selection

**Files:**
- Create: `RevenueCatUI/Templates/V2/State/PaywallPackageSelectionCoordinator.swift`
- Modify: `RevenueCatUI/Templates/V2/PaywallsV2View.swift`
- Modify: `RevenueCatUI/Templates/V2/Components/Root/RootView.swift`
- Modify: `RevenueCatUI/Templates/V2/Components/Button/BottomSheetView.swift`
- Modify: `RevenueCatUI/Templates/V2/Components/Button/ButtonComponentView.swift`
- Modify: `RevenueCatUI/Templates/V2/Components/Packages/Package/PackageComponentView.swift`
- Test: `Tests/RevenueCatUITests/PaywallsV2/PaywallPackageSelectionCoordinatorTests.swift`

- [ ] **Step 1: Write coordinator tests**

Create `PaywallPackageSelectionCoordinatorTests.swift`:

```swift
@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class PaywallPackageSelectionCoordinatorTests: TestCase {

    func testRootSelectionCommitsToPackageContext() {
        let monthly = TestData.monthlyPackage
        let annual = TestData.annualPackage
        let context = PackageContext(package: monthly, variableContext: .init(packages: [monthly, annual]))
        let store = PaywallStateStore()
        let coordinator = PaywallPackageSelectionCoordinator(
            scope: Self.scope,
            store: store,
            packageContext: context,
            packages: [monthly, annual],
            defaultPackage: monthly
        )

        coordinator.selectRootPackage(annual, sourceComponent: Self.packageIdentity)

        XCTAssertEqual(context.package?.identifier, annual.identifier)
    }

    func testRejectedRootSelectionDoesNotChangePackageContext() {
        let monthly = TestData.monthlyPackage
        let annual = TestData.annualPackage
        let context = PackageContext(package: monthly, variableContext: .init(packages: [monthly, annual]))
        let store = PaywallStateStore()
        store.mutationHandler = PaywallStateMutationHandler { proposal in proposal.reject() }
        let coordinator = PaywallPackageSelectionCoordinator(
            scope: Self.scope,
            store: store,
            packageContext: context,
            packages: [monthly, annual],
            defaultPackage: monthly
        )

        coordinator.selectRootPackage(annual, sourceComponent: Self.packageIdentity)

        XCTAssertEqual(context.package?.identifier, monthly.identifier)
    }

    func testSheetDismissRestoresDefaultPackage() {
        let monthly = TestData.monthlyPackage
        let annual = TestData.annualPackage
        let context = PackageContext(package: monthly, variableContext: .init(packages: [monthly, annual]))
        let coordinator = PaywallPackageSelectionCoordinator(
            scope: Self.scope,
            store: PaywallStateStore(),
            packageContext: context,
            packages: [monthly, annual],
            defaultPackage: monthly
        )

        coordinator.selectSheetPackage(annual, sheetComponentID: "sheet_a", sourceComponent: Self.packageIdentity)
        XCTAssertEqual(context.package?.identifier, annual.identifier)

        coordinator.restoreRootSelectionAfterSheetDismiss()
        XCTAssertEqual(context.package?.identifier, monthly.identifier)
    }

    private static let scope = PaywallStateScope(
        instanceID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        paywallID: "paywall_a",
        offeringIdentifier: "default",
        paywallRevision: 1,
        workflowPageID: nil
    )

    private static let packageIdentity = PaywallComponentIdentity(
        paywallID: "paywall_a",
        componentID: "package_monthly",
        type: "package",
        name: nil
    )

}

#endif
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
swift test --filter PaywallPackageSelectionCoordinatorTests
```

Expected: fail because coordinator does not exist.

- [ ] **Step 3: Implement coordinator**

Create `PaywallPackageSelectionCoordinator.swift`:

```swift
@_spi(Internal) import RevenueCat
import Foundation

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class PaywallPackageSelectionCoordinator: ObservableObject {

    private let scope: PaywallStateScope
    private let store: PaywallStateStore
    private let packageContext: PackageContext
    private let packagesByID: [String: Package]
    private let defaultPackage: Package?
    private var activeSheetComponentID: String?

    init(
        scope: PaywallStateScope,
        store: PaywallStateStore,
        packageContext: PackageContext,
        packages: [Package],
        defaultPackage: Package?
    ) {
        self.scope = scope
        self.store = store
        self.packageContext = packageContext
        self.packagesByID = Dictionary(uniqueKeysWithValues: packages.map { ($0.identifier, $0) })
        self.defaultPackage = defaultPackage
    }

    func selectRootPackage(_ package: Package, sourceComponent: PaywallComponentIdentity) {
        self.request(
            packageID: package.identifier,
            field: .rootSelectedPackageID,
            sourceComponent: sourceComponent,
            sheetComponentID: nil
        )
    }

    func selectSheetPackage(
        _ package: Package,
        sheetComponentID: String,
        sourceComponent: PaywallComponentIdentity
    ) {
        self.activeSheetComponentID = sheetComponentID
        self.request(
            packageID: package.identifier,
            field: .sheetSelectedPackageID(componentID: sheetComponentID),
            sourceComponent: sourceComponent,
            sheetComponentID: sheetComponentID
        )
    }

    func restoreRootSelectionAfterSheetDismiss() {
        self.activeSheetComponentID = nil
        let rootKey = PaywallStateKey.paywall(scope: self.scope, field: .rootSelectedPackageID)
        let rootPackageID = self.store.value(for: rootKey)?.packageID
        self.packageContext.update(
            package: rootPackageID.flatMap { self.packagesByID[$0] } ?? self.defaultPackage,
            variableContext: self.packageContext.variableContext
        )
    }

    private func request(
        packageID: String,
        field: PaywallStateKey.Field,
        sourceComponent: PaywallComponentIdentity,
        sheetComponentID: String?
    ) {
        let key = PaywallStateKey.paywall(scope: self.scope, field: field)
        self.store.request(
            .init(key: key, value: .packageID(packageID)),
            details: .init(source: sourceComponent.componentID, sheetComponentID: sheetComponentID)
        )
        if self.store.value(for: key)?.packageID == packageID {
            self.packageContext.update(
                package: self.packagesByID[packageID],
                variableContext: self.packageContext.variableContext
            )
        }
    }

}

#endif
```

- [ ] **Step 4: Inject coordinator**

In `LoadedPaywallsV2View`, create or receive:

```swift
@StateObject
private var packageSelectionCoordinator: PaywallPackageSelectionCoordinator
```

Pass from `PaywallsV2View` using `paywallState.packages`, default package, `selectedPackageContext`, `paywallStateStore`, and scope.

Add environment:

```swift
.environmentObject(self.packageSelectionCoordinator)
```

- [ ] **Step 5: Route package row taps through coordinator**

In `PackageComponentView.PackageSelectorIfNeeded`, add:

```swift
@EnvironmentObject
private var packageSelectionCoordinator: PaywallPackageSelectionCoordinator

@Environment(\.activeSheetComponentID)
private var activeSheetComponentID
```

Replace direct update:

```swift
if let activeSheetComponentID {
    self.packageSelectionCoordinator.selectSheetPackage(
        self.package,
        sheetComponentID: activeSheetComponentID,
        sourceComponent: self.componentIdentity
    )
} else {
    self.packageSelectionCoordinator.selectRootPackage(
        self.package,
        sourceComponent: self.componentIdentity
    )
}
```

Keep `componentInteractionLogger` behavior before the state request.

- [ ] **Step 6: Add active sheet environment**

In `BottomSheetView.swift`, add an environment key:

```swift
private struct ActiveSheetComponentIDKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

extension EnvironmentValues {
    var activeSheetComponentID: String? {
        get { self[ActiveSheetComponentIDKey.self] }
        set { self[ActiveSheetComponentIDKey.self] = newValue }
    }
}
```

When rendering sheet content:

```swift
.environment(\.activeSheetComponentID, sheetViewModel.sheet.id)
```

In `RootView` sheet dismissal:

```swift
self.packageSelectionCoordinator.restoreRootSelectionAfterSheetDismiss()
```

- [ ] **Step 7: Run targeted tests**

Run:

```bash
swift test --filter PaywallPackageSelectionCoordinatorTests
swift test --filter PackageComponentViewTests
```

Expected: pass.

- [ ] **Step 8: Commit**

```bash
git add RevenueCatUI/Templates/V2 Tests/RevenueCatUITests/PaywallsV2/PaywallPackageSelectionCoordinatorTests.swift Tests/RevenueCatUITests/PaywallsV2/PackageComponentViewTests.swift
git commit -m "feat: route paywalls package selection through state"
```

---

## Task 7: Add first reactive text projection

**Files:**
- Modify: `RevenueCatUI/Templates/V2/Components/Text/TextComponentViewModel.swift`
- Modify: `RevenueCatUI/Templates/V2/Components/Text/TextComponentView.swift`
- Test: `Tests/RevenueCatUITests/PaywallsV2/TextComponentLocalizationTests.swift`

- [ ] **Step 1: Add projection equivalence test**

Add to `TextComponentLocalizationTests`:

```swift
@MainActor
func testProjectedTextStyleMatchesLegacyStylesForSelectedPackageOverride() throws {
    let textComponent = PaywallComponent.TextComponent(
        id: "text_a",
        text: "base_lid",
        color: Self.black,
        overrides: [
            .init(extendedConditions: [
                .selectedPackage(operator: .in, packages: ["monthly"])
            ], properties: .init(text: "override_lid"))
        ]
    )
    let viewModel = try TextComponentViewModel(
        identity: .init(paywallID: "paywall_a", componentID: "text_a", type: "text", name: nil),
        localizationProvider: .init(locale: .current, localizedStrings: [
            "base_lid": .string("Base"),
            "override_lid": .string("Override")
        ]),
        uiConfigProvider: try Self.createUIConfigProvider(),
        component: textComponent
    )
    let packageContext = PackageContext(package: TestData.monthlyPackage, variableContext: .init())
    var legacyText: String?
    _ = viewModel.styles(
        state: .default,
        condition: .compact,
        selectedPackageId: "monthly",
        packageContext: packageContext,
        isEligibleForIntroOffer: false,
        promoOffer: nil
    ) { style -> EmptyView in
        legacyText = style.text
        return EmptyView()
    }

    let projected = viewModel.projectedStyle(
        state: .default,
        condition: .compact,
        selectedPackageId: "monthly",
        packageContext: packageContext,
        isEligibleForIntroOffer: false,
        promoOffer: nil,
        countdownTime: nil,
        customVariables: [:]
    )

    XCTAssertEqual(projected.text, legacyText)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
swift test --filter TextComponentLocalizationTests/testProjectedTextStyleMatchesLegacyStylesForSelectedPackageOverride
```

Expected: fail because `projectedStyle(...)` does not exist.

- [ ] **Step 3: Extract style computation from `styles(...)`**

In `TextComponentViewModel`, add:

```swift
@MainActor
func projectedStyle(
    state: ComponentViewState,
    condition: ScreenCondition,
    selectedPackageId: String?,
    packageContext: PackageContext,
    isEligibleForIntroOffer: Bool,
    promoOffer: PromotionalOffer?,
    countdownTime: CountdownTime? = nil,
    customVariables: [String: CustomVariableValue] = [:]
) -> TextComponentStyle {
    let isEligibleForPromoOffer = promoOffer != nil
    let conditionContext = uiConfigProvider.conditionContext(
        selectedPackageId: selectedPackageId,
        customVariables: customVariables
    )
    let localizedPartial = LocalizedTextPartial.buildPartial(
        state: state,
        condition: condition,
        isEligibleForIntroOffer: isEligibleForIntroOffer,
        isEligibleForPromoOffer: isEligibleForPromoOffer,
        conditionContext: conditionContext,
        with: self.presentedOverrides
    )
    let partial = localizedPartial?.partial
    let text = localizedPartial?.text ?? self.text
    let config = TextProcessingConfig(
        packageContext: packageContext,
        variableConfig: uiConfigProvider.variableConfig,
        locale: self.localizationProvider.locale,
        localizations: self.uiConfigProvider.getLocalizations(for: self.localizationProvider.locale),
        isEligibleForIntroOffer: isEligibleForIntroOffer,
        promoOffer: promoOffer,
        countdownTime: countdownTime,
        customVariables: customVariables,
        defaultCustomVariables: uiConfigProvider.defaultCustomVariables
    )
    return TextComponentStyle(
        uiConfigProvider: self.uiConfigProvider,
        visible: partial?.visible ?? self.component.visible ?? true,
        name: partial?.name ?? self.component.name,
        text: Self.processText(text, config: config),
        fontName: partial?.fontName ?? self.component.fontName,
        fontWeight: partial?.fontWeightResolved ?? self.component.fontWeightResolved,
        color: partial?.color ?? self.component.color,
        backgroundColor: partial?.backgroundColor ?? self.component.backgroundColor,
        size: partial?.size ?? self.component.size,
        padding: partial?.padding ?? self.component.padding,
        margin: partial?.margin ?? self.component.margin,
        fontSize: partial?.fontSize ?? self.component.fontSize,
        horizontalAlignment: partial?.horizontalAlignment ?? self.component.horizontalAlignment
    )
}
```

Then make legacy `styles(...)` call `projectedStyle(...)`.

- [ ] **Step 4: Commit projected values into the state store**

> **Review:** The snippet calls `self.paywallStateStore.request(...)` inline in the view's construction (effectively from `body`). SwiftUI re-evaluates `body` continuously, so this writes to the store on every layout pass — producing "Modifying state during view update" runtime warnings and risking publisher→state→re-render feedback loops (especially once other components observe `.componentText`). Move the write into `.onAppear` + `.onChange(of:)` for the inputs that feed `projectedStyle(...)`, or a `.task(id:)` keyed on the same inputs. The `commit` short-circuit on unchanged value mitigates the loop but doesn't fix the "during view update" violation.

In `TextComponentView`, read store:

```swift
@Environment(\.paywallStateStore)
private var paywallStateStore
```

After computing projected style, request changed values:

```swift
let style = viewModel.projectedStyle(...)
self.paywallStateStore.request(
    .init(
        key: .init(scope: scope, component: viewModel.identity, field: .componentText),
        value: .string(style.text)
    ),
    details: .init(source: viewModel.identity.componentID)
)
```

Keep rendering from `style` in this task. Observing the projected fields directly can be a subsequent migration once equivalence is covered.

- [ ] **Step 5: Run targeted tests**

Run:

```bash
swift test --filter TextComponentLocalizationTests/testProjectedTextStyleMatchesLegacyStylesForSelectedPackageOverride
swift test --filter TextComponentLocalizationTests
```

Expected: pass.

- [ ] **Step 6: Commit**

```bash
git add RevenueCatUI/Templates/V2/Components/Text Tests/RevenueCatUITests/PaywallsV2/TextComponentLocalizationTests.swift
git commit -m "feat: add paywalls text style projection"
```

---

> **Review (Task 8 — verification is thin & API testers not updated):**
> 1. Filtered `swift test` runs only the new tests. Add `swift build` (catches non-test compile errors in production targets) and a broader run — `bundle exec fastlane test_ios` or `tuist test RevenueCatUITests` — to surface regressions in existing tests (especially snapshot tests under `Tests/RevenueCatUITests/Templates/V2/` that exercise `TextComponentView`).
> 2. The plan never touches `Tests/APITesters/SwiftAPITester` or `ObjcAPITester`. Any new `@_spi(Internal) public` symbol intended to stay stable should be exercised there so the `run_api_tests` lane catches accidental breakage on the SPI surface (the testers import with `@_spi(Internal)`).
> 3. Add an explicit step to re-record or verify snapshot tests after Task 7 lands, since `TextComponentView` rendering path changes.

## Task 8: Run API and focused regression checks

**Files:**
- Modify only files needed to fix compile, lint, or API issues found by this task.

- [ ] **Step 1: Run focused Swift tests**

Run:

```bash
swift test --filter PaywallStateStoreTests
swift test --filter PaywallComponentIdentityTests
swift test --filter PaywallPackageSelectionCoordinatorTests
swift test --filter ViewModelFactoryTests
swift test --filter PackageComponentViewTests
swift test --filter TextComponentLocalizationTests
```

Expected: all selected tests pass.

- [ ] **Step 2: Run API tests**

Run:

```bash
bundle exec fastlane ios run_api_tests
```

Expected: pass. If it fails because an API type was exposed as stable public API, move that type or member behind `@_spi(Internal) public` and rerun the command.

- [ ] **Step 3: Run SwiftLint**

Run:

```bash
swiftlint
```

Expected: pass. Fix only issues introduced by this work.

- [ ] **Step 4: Commit fixes if needed**

If Step 1, Step 2, or Step 3 required changes:

```bash
git add RevenueCatUI Sources Tests
git commit -m "fix: address paywalls reactive state verification issues"
```

If no files changed, do not create an empty commit.

---

## Plan self-review

- Spec coverage: Tasks cover state primitives, state store, SPI hooks, component IDs, identity propagation, root and sheet package selection, first text projection, and verification.
- Scope check: The plan keeps future expansion out of the first implementation slice.
- Type consistency: `PaywallStateScope`, `PaywallComponentIdentity`, `PaywallStateKey`, `PaywallStateValue`, `PaywallStateMutation`, `PaywallStateChange`, `PaywallStateMutationProposal`, `PaywallStateStore`, and `PaywallPackageSelectionCoordinator` are introduced before use.

## Execution handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-14-paywalls-v2-reactive-state-adapter.md`. Two execution options:

1. **Subagent-Driven (recommended)** - dispatch a fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** - execute tasks in this session using executing-plans, batch execution with checkpoints for review.

Which approach?
