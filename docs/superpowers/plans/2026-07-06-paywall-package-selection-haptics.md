# Paywall Package/Tab Selection Haptics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fire a `UISelectionFeedbackGenerator` haptic when the user actually changes the selected package or tab on a Paywalls V2 screen, gated by a new editor-configurable `hapticFeedbackEnabled` field on the relevant component config.

**Architecture:** A small environment-injected `PackageSelectionHapticFeedback` struct (mirrors the existing `ComponentInteractionLogger` pattern) provides the haptic mechanism. A new optional `Bool?` field on `PackageComponent`, `TabControlButtonComponent`, and `TabControlToggleComponent` (wire key `haptic_feedback_enabled`, `nil`/absent = enabled) lets the dashboard opt a component out. Three call sites (package card tap, tab button tap, tab toggle flip) read the flag and invoke the environment closure only when the selection actually changed.

**Tech Stack:** Swift, SwiftUI, XCTest, Nimble, `@_spi(Internal)` component schema types.

## Global Constraints

- All new/modified RevenueCatUI types keep the existing `@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)` annotation and `#if !os(tvOS) // For Paywalls V2` gating used throughout this subsystem.
- Haptic firing is iOS-only: gate with `#if canImport(UIKit) && os(iOS)`, no-op elsewhere (no macOS/tvOS/watchOS haptic APIs are in scope).
- New `Codable` fields must be optional (`Bool?`) with a `nil` default so existing/older JSON payloads decode without error, per the established pattern from PR #6520 (adding `visible` to `PackageComponent`).
- Wire JSON key for the new field is `haptic_feedback_enabled` (project-wide `.convertFromSnakeCase`/`.convertToSnakeCase` decoder/encoder strategy applies; do not add a custom `CodingKeys` raw value for it).
- Do not modify `TabControlToggleComponent`'s existing unused `defaultValue: Bool` init parameter — pre-existing, unrelated.
- V1 templates, `WatchTemplateView`, and `CarouselComponentView` are out of scope.
- Run `swiftlint` (or `swiftlint --fix`) and `swift build` before each commit.
- Design reference: `docs/superpowers/specs/2026-07-06-paywall-package-selection-haptics-design.md`.

---

### Task 1: `PackageSelectionHapticFeedback` environment wrapper

**Files:**
- Modify: `RevenueCatUI/Purchasing/PaywallEventTracker.swift` (append after line 259, end of file)
- Test: `Tests/RevenueCatUITests/Purchasing/PackageSelectionHapticFeedbackTests.swift` (create)

**Interfaces:**
- Produces: `PackageSelectionHapticFeedback` (struct, `init(action: @escaping () -> Void = Self.defaultAction)`, `func callAsFunction()`), `EnvironmentValues.packageSelectionHapticFeedback: PackageSelectionHapticFeedback` (get/set). Later tasks read this via `@Environment(\.packageSelectionHapticFeedback) private var hapticFeedback` and call `self.hapticFeedback()`.

- [ ] **Step 1: Write the failing test**

Create `Tests/RevenueCatUITests/Purchasing/PackageSelectionHapticFeedbackTests.swift`:

```swift
//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageSelectionHapticFeedbackTests.swift

import Foundation
import Nimble
@_spi(Internal) @testable import RevenueCatUI
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class PackageSelectionHapticFeedbackTests: TestCase {

    func testCallAsFunctionInvokesTheInjectedAction() {
        var didFire = false

        let feedback = PackageSelectionHapticFeedback { didFire = true }
        feedback()

        expect(didFire) == true
    }

    func testCallAsFunctionInvokesTheActionExactlyOncePerCall() {
        var fireCount = 0

        let feedback = PackageSelectionHapticFeedback { fireCount += 1 }
        feedback()
        feedback()
        feedback()

        expect(fireCount) == 3
    }

}
```

The default action (real `UISelectionFeedbackGenerator` call) and the `EnvironmentKey`
get/set plumbing are not separately unit tested: there's no observable return value to assert
on for a UIKit haptic call, and `ComponentInteractionLoggerKey`'s identical get/set forwarding
has no dedicated test either in this codebase (see `Tests/RevenueCatUITests/Purchasing/ControlInteractionLoggerTests.swift`).
Both are exercised at runtime through the call sites added in Tasks 5-7. Device-level haptic
*feel* is verified manually (see Task 8, Step 5).

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter PackageSelectionHapticFeedbackTests`
Expected: FAIL to compile — `PackageSelectionHapticFeedback` and `EnvironmentValues.packageSelectionHapticFeedback` do not exist yet.

- [ ] **Step 3: Write minimal implementation**

Append to `RevenueCatUI/Purchasing/PaywallEventTracker.swift`, after the final `extension EnvironmentValues` block (after line 259):

```swift

/// Fires a native selection-changed haptic when the user changes the selected package or tab
/// on a Paywalls V2 screen. Wraps a closure (like `ComponentInteractionLogger`) so tests can
/// inject a spy without touching real UIKit APIs.
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

/// `EnvironmentKey` for storing the paywall package/tab selection haptic feedback.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PackageSelectionHapticFeedbackKey: EnvironmentKey {
    static let defaultValue: PackageSelectionHapticFeedback = .init()
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {
    var packageSelectionHapticFeedback: PackageSelectionHapticFeedback {
        get { self[PackageSelectionHapticFeedbackKey.self] }
        set { self[PackageSelectionHapticFeedbackKey.self] = newValue }
    }
}
```

Add the conditional UIKit import near the top of the file (after the existing `import SwiftUI` on line 17):

```swift
import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if canImport(UIKit) && os(iOS)
import UIKit
#endif
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter PackageSelectionHapticFeedbackTests`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add RevenueCatUI/Purchasing/PaywallEventTracker.swift Tests/RevenueCatUITests/Purchasing/PackageSelectionHapticFeedbackTests.swift
git commit -m "feat(paywalls): add environment-injected package selection haptic feedback"
```

---

### Task 2: `hapticFeedbackEnabled` field on `PackageComponent`

**Files:**
- Modify: `Sources/Paywalls/Components/PaywallPackageComponent.swift`
- Test: `Tests/UnitTests/Paywalls/Components/PackageComponentTests.swift` (create)

**Interfaces:**
- Consumes: none (independent of Task 1).
- Produces: `PaywallComponent.PackageComponent.hapticFeedbackEnabled: Bool?`, and a new `init` parameter `hapticFeedbackEnabled: Bool? = nil`. Task 4 reads `component.hapticFeedbackEnabled`.

- [ ] **Step 1: Write the failing test**

Create `Tests/UnitTests/Paywalls/Components/PackageComponentTests.swift`:

```swift
//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageComponentTests.swift

import Foundation
@_spi(Internal) @testable import RevenueCat
import XCTest

class PackageComponentTests: TestCase {

    private func makeComponent(hapticFeedbackEnabled: Bool?) -> PaywallComponent.PackageComponent {
        return PaywallComponent.PackageComponent(
            packageID: "weekly",
            isSelectedByDefault: true,
            applePromoOfferProductCode: nil,
            stack: PaywallComponent.StackComponent(components: []),
            hapticFeedbackEnabled: hapticFeedbackEnabled
        )
    }

    func testHapticFeedbackEnabledDefaultsToNilWhenOmitted() {
        let component = PaywallComponent.PackageComponent(
            packageID: "weekly",
            isSelectedByDefault: true,
            applePromoOfferProductCode: nil,
            stack: PaywallComponent.StackComponent(components: [])
        )

        XCTAssertNil(component.hapticFeedbackEnabled)
    }

    func testHapticFeedbackEnabledRoundTripsTrue() throws {
        let component = self.makeComponent(hapticFeedbackEnabled: true)
        let decoded = try component.encodeAndDecode()

        XCTAssertEqual(decoded.hapticFeedbackEnabled, true)
        XCTAssertEqual(component, decoded)
    }

    func testHapticFeedbackEnabledRoundTripsFalse() throws {
        let component = self.makeComponent(hapticFeedbackEnabled: false)
        let decoded = try component.encodeAndDecode()

        XCTAssertEqual(decoded.hapticFeedbackEnabled, false)
        XCTAssertEqual(component, decoded)
    }

    func testHapticFeedbackEnabledRoundTripsNil() throws {
        let component = self.makeComponent(hapticFeedbackEnabled: nil)
        let decoded = try component.encodeAndDecode()

        XCTAssertNil(decoded.hapticFeedbackEnabled)
        XCTAssertEqual(component, decoded)
    }

    func testHapticFeedbackEnabledDecodesFromSnakeCaseWireKey() throws {
        let component = self.makeComponent(hapticFeedbackEnabled: nil)
        let encoded = try JSONEncoder.default.encode(component)

        var json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        json["haptic_feedback_enabled"] = false

        let patchedData = try JSONSerialization.data(withJSONObject: json)
        let decoded = try JSONDecoder.default.decode(
            PaywallComponent.PackageComponent.self,
            from: patchedData
        )

        XCTAssertEqual(decoded.hapticFeedbackEnabled, false)
    }

    func testHapticFeedbackEnabledDiffAffectsEquality() {
        let enabled = self.makeComponent(hapticFeedbackEnabled: true)
        let disabled = self.makeComponent(hapticFeedbackEnabled: false)

        XCTAssertNotEqual(enabled, disabled)
    }

}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter PackageComponentTests`
Expected: FAIL to compile — `hapticFeedbackEnabled` is not a member of `PackageComponent`, and the `init` has no such parameter.

- [ ] **Step 3: Write minimal implementation**

In `Sources/Paywalls/Components/PaywallPackageComponent.swift`, update the `PackageComponent` class (lines 20-72):

```swift
    final class PackageComponent: PaywallComponentBase {

        let type: ComponentType
        public let packageID: String
        public let isSelectedByDefault: Bool
        public let visible: Bool?
        @_spi(Internal) public let applePromoOfferProductCode: String?
        public let stack: PaywallComponent.StackComponent
        public let name: String?
        public let hapticFeedbackEnabled: Bool?

        public let overrides: ComponentOverrides<PartialPackageComponent>?

        public init(
            packageID: String,
            isSelectedByDefault: Bool,
            visible: Bool? = nil,
            applePromoOfferProductCode: String?,
            stack: PaywallComponent.StackComponent,
            name: String? = nil,
            hapticFeedbackEnabled: Bool? = nil,
            overrides: ComponentOverrides<PartialPackageComponent>? = nil
        ) {
            self.type = .package
            self.packageID = packageID
            self.isSelectedByDefault = isSelectedByDefault
            self.visible = visible
            self.applePromoOfferProductCode = applePromoOfferProductCode
            self.stack = stack
            self.name = name
            self.hapticFeedbackEnabled = hapticFeedbackEnabled
            self.overrides = overrides
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(packageID)
            hasher.combine(isSelectedByDefault)
            hasher.combine(visible)
            hasher.combine(applePromoOfferProductCode)
            hasher.combine(stack)
            hasher.combine(name)
            hasher.combine(hapticFeedbackEnabled)
            hasher.combine(overrides)
        }

        public static func == (lhs: PackageComponent, rhs: PackageComponent) -> Bool {
            return lhs.type == rhs.type &&
                   lhs.packageID == rhs.packageID &&
                   lhs.isSelectedByDefault == rhs.isSelectedByDefault &&
                   lhs.visible == rhs.visible &&
                   lhs.applePromoOfferProductCode == rhs.applePromoOfferProductCode &&
                   lhs.stack == rhs.stack &&
                   lhs.name == rhs.name &&
                   lhs.hapticFeedbackEnabled == rhs.hapticFeedbackEnabled &&
                   lhs.overrides == rhs.overrides
        }
    }
```

And update the `CodingKeys` extension near the bottom of the file:

```swift
extension PaywallComponent.PackageComponent {

    enum CodingKeys: String, CodingKey {
        case type
        case packageID = "packageId"
        case isSelectedByDefault
        case visible
        case applePromoOfferProductCode
        case stack
        case name
        case hapticFeedbackEnabled
        case overrides
    }

}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter PackageComponentTests`
Expected: PASS (6 tests)

- [ ] **Step 5: Run the full existing component test suite to check nothing broke**

Run: `swift test --filter PartialComponentTests`
Expected: PASS (no regressions from the new field/init param)

- [ ] **Step 6: Commit**

```bash
git add Sources/Paywalls/Components/PaywallPackageComponent.swift Tests/UnitTests/Paywalls/Components/PackageComponentTests.swift
git commit -m "feat(paywalls): add hapticFeedbackEnabled field to PackageComponent"
```

---

### Task 3: `hapticFeedbackEnabled` field on `TabControlButtonComponent` and `TabControlToggleComponent`

**Files:**
- Modify: `Sources/Paywalls/Components/PaywallTabsComponent.swift`
- Test: `Tests/UnitTests/Paywalls/Components/TabsComponentTests.swift` (create)

**Interfaces:**
- Consumes: none (independent of Tasks 1-2).
- Produces: `PaywallComponent.TabControlButtonComponent.hapticFeedbackEnabled: Bool?`, `PaywallComponent.TabControlToggleComponent.hapticFeedbackEnabled: Bool?`, and matching `init` parameters (`hapticFeedbackEnabled: Bool? = nil`). Tasks 6-7 read `viewModel.component.hapticFeedbackEnabled`.

- [ ] **Step 1: Write the failing test**

Create `Tests/UnitTests/Paywalls/Components/TabsComponentTests.swift`:

```swift
//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TabsComponentTests.swift

import Foundation
@_spi(Internal) @testable import RevenueCat
import XCTest

class TabsComponentTests: TestCase {

    // MARK: - TabControlButtonComponent

    func testTabControlButtonHapticFeedbackEnabledDefaultsToNilWhenOmitted() {
        let component = PaywallComponent.TabControlButtonComponent(
            tabId: "weekly",
            stack: PaywallComponent.StackComponent(components: [])
        )

        XCTAssertNil(component.hapticFeedbackEnabled)
    }

    func testTabControlButtonHapticFeedbackEnabledRoundTripsTrueAndFalse() throws {
        let enabled = PaywallComponent.TabControlButtonComponent(
            tabId: "weekly",
            stack: PaywallComponent.StackComponent(components: []),
            hapticFeedbackEnabled: true
        )
        let disabled = PaywallComponent.TabControlButtonComponent(
            tabId: "weekly",
            stack: PaywallComponent.StackComponent(components: []),
            hapticFeedbackEnabled: false
        )

        XCTAssertEqual(try enabled.encodeAndDecode().hapticFeedbackEnabled, true)
        XCTAssertEqual(try disabled.encodeAndDecode().hapticFeedbackEnabled, false)
        XCTAssertNotEqual(enabled, disabled)
    }

    func testTabControlButtonHapticFeedbackEnabledDecodesFromSnakeCaseWireKey() throws {
        let component = PaywallComponent.TabControlButtonComponent(
            tabId: "weekly",
            stack: PaywallComponent.StackComponent(components: [])
        )
        let encoded = try JSONEncoder.default.encode(component)

        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        json["haptic_feedback_enabled"] = false

        let patchedData = try JSONSerialization.data(withJSONObject: json)
        let decoded = try JSONDecoder.default.decode(
            PaywallComponent.TabControlButtonComponent.self,
            from: patchedData
        )

        XCTAssertEqual(decoded.hapticFeedbackEnabled, false)
    }

    // MARK: - TabControlToggleComponent

    private func makeToggleComponent(hapticFeedbackEnabled: Bool?) -> PaywallComponent.TabControlToggleComponent {
        return PaywallComponent.TabControlToggleComponent(
            defaultValue: false,
            thumbColorOn: .init(light: .hex("#00ff00")),
            thumbColorOff: .init(light: .hex("#ff0000")),
            trackColorOn: .init(light: .hex("#dedede")),
            trackColorOff: .init(light: .hex("#bebebe")),
            hapticFeedbackEnabled: hapticFeedbackEnabled
        )
    }

    func testTabControlToggleHapticFeedbackEnabledDefaultsToNilWhenOmitted() {
        let component = PaywallComponent.TabControlToggleComponent(
            defaultValue: false,
            thumbColorOn: .init(light: .hex("#00ff00")),
            thumbColorOff: .init(light: .hex("#ff0000")),
            trackColorOn: .init(light: .hex("#dedede")),
            trackColorOff: .init(light: .hex("#bebebe"))
        )

        XCTAssertNil(component.hapticFeedbackEnabled)
    }

    func testTabControlToggleHapticFeedbackEnabledRoundTripsTrueAndFalse() throws {
        let enabled = self.makeToggleComponent(hapticFeedbackEnabled: true)
        let disabled = self.makeToggleComponent(hapticFeedbackEnabled: false)

        XCTAssertEqual(try enabled.encodeAndDecode().hapticFeedbackEnabled, true)
        XCTAssertEqual(try disabled.encodeAndDecode().hapticFeedbackEnabled, false)
        XCTAssertNotEqual(enabled, disabled)
    }

    func testTabControlToggleHapticFeedbackEnabledDecodesFromSnakeCaseWireKey() throws {
        let component = self.makeToggleComponent(hapticFeedbackEnabled: nil)
        let encoded = try JSONEncoder.default.encode(component)

        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        json["haptic_feedback_enabled"] = false

        let patchedData = try JSONSerialization.data(withJSONObject: json)
        let decoded = try JSONDecoder.default.decode(
            PaywallComponent.TabControlToggleComponent.self,
            from: patchedData
        )

        XCTAssertEqual(decoded.hapticFeedbackEnabled, false)
    }

}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter TabsComponentTests`
Expected: FAIL to compile — `hapticFeedbackEnabled` and the new `init` parameters don't exist yet on either class.

- [ ] **Step 3: Write minimal implementation**

In `Sources/Paywalls/Components/PaywallTabsComponent.swift`, update `TabControlButtonComponent` (lines 19-46):

```swift
    final class TabControlButtonComponent: Codable, Sendable, Hashable, Equatable {

        let type: ComponentType
        public let tabId: String
        public let name: String?
        public let stack: StackComponent
        public let hapticFeedbackEnabled: Bool?

        public init(
            tabId: String,
            stack: StackComponent,
            name: String? = nil,
            hapticFeedbackEnabled: Bool? = nil
        ) {
            self.type = .tabControlButton
            self.tabId = tabId
            self.name = name
            self.stack = stack
            self.hapticFeedbackEnabled = hapticFeedbackEnabled
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(tabId)
            hasher.combine(name)
            hasher.combine(stack)
            hasher.combine(hapticFeedbackEnabled)
        }

        public static func == (lhs: TabControlButtonComponent, rhs: TabControlButtonComponent) -> Bool {
            return lhs.type == rhs.type &&
                lhs.tabId == rhs.tabId &&
                lhs.name == rhs.name &&
                lhs.stack == rhs.stack &&
                lhs.hapticFeedbackEnabled == rhs.hapticFeedbackEnabled
        }
    }
```

And `TabControlToggleComponent` (lines 48-88):

```swift
    final class TabControlToggleComponent: Codable, Sendable, Hashable, Equatable {

        let type: ComponentType
        public let name: String?
        public let thumbColorOn: ColorScheme
        public let thumbColorOff: ColorScheme
        public let trackColorOn: ColorScheme
        public let trackColorOff: ColorScheme
        public let hapticFeedbackEnabled: Bool?

        public init(defaultValue: Bool,
                    name: String? = nil,
                    thumbColorOn: ColorScheme,
                    thumbColorOff: ColorScheme,
                    trackColorOn: ColorScheme,
                    trackColorOff: ColorScheme,
                    hapticFeedbackEnabled: Bool? = nil) {
            self.type = .tabControlToggle
            self.name = name
            self.thumbColorOn = thumbColorOn
            self.thumbColorOff = thumbColorOff
            self.trackColorOn = trackColorOn
            self.trackColorOff = trackColorOff
            self.hapticFeedbackEnabled = hapticFeedbackEnabled
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(name)
            hasher.combine(thumbColorOn)
            hasher.combine(thumbColorOff)
            hasher.combine(trackColorOn)
            hasher.combine(trackColorOff)
            hasher.combine(hapticFeedbackEnabled)
        }

        public static func == (lhs: TabControlToggleComponent, rhs: TabControlToggleComponent) -> Bool {
            return lhs.type == rhs.type &&
                   lhs.name == rhs.name &&
                   lhs.thumbColorOn == rhs.thumbColorOn &&
                   lhs.thumbColorOff == rhs.thumbColorOff &&
                   lhs.trackColorOn == rhs.trackColorOn &&
                   lhs.trackColorOff == rhs.trackColorOff &&
                   lhs.hapticFeedbackEnabled == rhs.hapticFeedbackEnabled
        }
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter TabsComponentTests`
Expected: PASS (6 tests)

- [ ] **Step 5: Run the full existing component test suite to check nothing broke**

Run: `swift test --filter PaywallComponentStateTests`
Expected: PASS (no regressions)

- [ ] **Step 6: Commit**

```bash
git add Sources/Paywalls/Components/PaywallTabsComponent.swift Tests/UnitTests/Paywalls/Components/TabsComponentTests.swift
git commit -m "feat(paywalls): add hapticFeedbackEnabled field to tab control components"
```

---

### Task 4: Wire `hapticFeedbackEnabled` through `PackageComponentViewModel`

**Files:**
- Modify: `RevenueCatUI/Templates/V2/Components/Packages/Package/PackageComponentViewModel.swift`
- Test: `Tests/RevenueCatUITests/PaywallsV2/PackageComponentViewTests.swift`

**Interfaces:**
- Consumes: `PaywallComponent.PackageComponent.hapticFeedbackEnabled: Bool?` (Task 2).
- Produces: `PackageComponentViewModel.hapticFeedbackEnabled: Bool`. Task 5 reads `self.viewModel.hapticFeedbackEnabled`.

- [ ] **Step 1: Write the failing test**

Add to `Tests/RevenueCatUITests/PaywallsV2/PackageComponentViewTests.swift`, inside the `PackageComponentViewTests` class (after the existing `testSelectedVisibilityOverrideUsesRenderedPackageContext` test):

```swift
    func testHapticFeedbackEnabledDefaultsToTrueWhenComponentOmitsIt() throws {
        let package = TestData.monthlyPackage
        let component = PaywallComponent.PackageComponent(
            packageID: package.identifier,
            isSelectedByDefault: false,
            applePromoOfferProductCode: nil,
            stack: Self.makePackageStack(label: "Monthly")
        )

        let viewModel = try Self.makeViewModel(component: component, package: package)

        XCTAssertTrue(viewModel.hapticFeedbackEnabled)
    }

    func testHapticFeedbackEnabledReflectsExplicitFalse() throws {
        let package = TestData.monthlyPackage
        let component = PaywallComponent.PackageComponent(
            packageID: package.identifier,
            isSelectedByDefault: false,
            applePromoOfferProductCode: nil,
            stack: Self.makePackageStack(label: "Monthly"),
            hapticFeedbackEnabled: false
        )

        let viewModel = try Self.makeViewModel(component: component, package: package)

        XCTAssertFalse(viewModel.hapticFeedbackEnabled)
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter PackageComponentViewTests`
Expected: FAIL to compile — `PackageComponentViewModel` has no member `hapticFeedbackEnabled`.

- [ ] **Step 3: Write minimal implementation**

In `RevenueCatUI/Templates/V2/Components/Packages/Package/PackageComponentViewModel.swift`, update the class:

```swift
    let isSelectedByDefault: Bool
    let promotionalOfferProductCode: String?
    let componentName: String?
    let package: Package?
    let stackViewModel: StackComponentViewModel
    let hasPurchaseButton: Bool
    let hapticFeedbackEnabled: Bool

    private let componentVisible: Bool?
    private let uiConfigProvider: UIConfigProvider
    private let presentedOverrides: PresentedOverrides<PresentedPackagePartial>?

    init(
        component: PaywallComponent.PackageComponent,
        offering: Offering,
        stackViewModel: StackComponentViewModel,
        hasPurchaseButton: Bool,
        uiConfigProvider: UIConfigProvider,
        discardRules: Bool = false
    ) {
        self.componentVisible = component.visible
        self.uiConfigProvider = uiConfigProvider
        self.isSelectedByDefault = component.isSelectedByDefault
        self.promotionalOfferProductCode = component.applePromoOfferProductCode
        self.componentName = component.name
        self.hapticFeedbackEnabled = component.hapticFeedbackEnabled ?? true

        self.package = offering.package(identifier: component.packageID)
        if package == nil {
            Logger.warning(Strings.paywall_could_not_find_package(component.packageID))
        }

        self.stackViewModel = stackViewModel
        self.hasPurchaseButton = hasPurchaseButton
        self.presentedOverrides = component.overrides?.toPresentedOverrides(discardRules: discardRules)
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter PackageComponentViewTests`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add RevenueCatUI/Templates/V2/Components/Packages/Package/PackageComponentViewModel.swift Tests/RevenueCatUITests/PaywallsV2/PackageComponentViewTests.swift
git commit -m "feat(paywalls): expose hapticFeedbackEnabled on PackageComponentViewModel"
```

---

### Task 5: Fire the haptic on package selection

**Files:**
- Modify: `RevenueCatUI/Templates/V2/Components/Packages/Package/PackageComponentView.swift`
- Test: `Tests/RevenueCatUITests/PaywallsV2/PackageComponentViewTests.swift`

**Interfaces:**
- Consumes: `PackageComponentViewModel.hapticFeedbackEnabled: Bool` (Task 4), `EnvironmentValues.packageSelectionHapticFeedback` (Task 1).
- Produces: `PackageSelectorIfNeeded.shouldTriggerHapticFeedback(origin:destination:hapticFeedbackEnabled:) -> Bool` (internal static method, testable via `@testable import`).

The decision logic ("did the selection actually change, and is haptics enabled for this
component") is pulled into a small internal static method so it can be unit tested directly,
without simulating a real SwiftUI button tap through a hosted view hierarchy — there is no
existing pattern in this codebase for that (`PackageComponentViewTests` only hosts views to
assert on rendered content, not to dispatch synthetic touches), and building one from scratch
here would be disproportionate to the risk. The `PackageSelectorIfNeeded` struct changes from
`private` to internal (module-visible) so `@testable import RevenueCatUI` can reach the static
method; its use is otherwise unchanged (still only referenced from this file).

- [ ] **Step 1: Write the failing test**

Add to `Tests/RevenueCatUITests/PaywallsV2/PackageComponentViewTests.swift`, inside the
`PackageComponentViewTests` class:

```swift
    func testShouldTriggerHapticFeedback_whenSelectionChangesAndEnabled_returnsTrue() {
        let origin = TestData.weeklyPackage
        let destination = TestData.monthlyPackage

        XCTAssertTrue(
            PackageSelectorIfNeeded.shouldTriggerHapticFeedback(
                origin: origin,
                destination: destination,
                hapticFeedbackEnabled: true
            )
        )
    }

    func testShouldTriggerHapticFeedback_whenSelectionUnchanged_returnsFalse() {
        let package = TestData.monthlyPackage

        XCTAssertFalse(
            PackageSelectorIfNeeded.shouldTriggerHapticFeedback(
                origin: package,
                destination: package,
                hapticFeedbackEnabled: true
            )
        )
    }

    func testShouldTriggerHapticFeedback_whenDisabled_returnsFalseEvenIfSelectionChanges() {
        let origin = TestData.weeklyPackage
        let destination = TestData.monthlyPackage

        XCTAssertFalse(
            PackageSelectorIfNeeded.shouldTriggerHapticFeedback(
                origin: origin,
                destination: destination,
                hapticFeedbackEnabled: false
            )
        )
    }

    func testShouldTriggerHapticFeedback_whenOriginIsNilAndSelectionChanges_returnsTrue() {
        let destination = TestData.monthlyPackage

        XCTAssertTrue(
            PackageSelectorIfNeeded.shouldTriggerHapticFeedback(
                origin: nil,
                destination: destination,
                hapticFeedbackEnabled: true
            )
        )
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter PackageComponentViewTests`
Expected: FAIL to compile — `PackageSelectorIfNeeded` is private to its file and has no
`shouldTriggerHapticFeedback` member.

- [ ] **Step 3: Write minimal implementation**

In `RevenueCatUI/Templates/V2/Components/Packages/Package/PackageComponentView.swift`, update the
call site (lines 81-86) to pass the new flag:

```swift
            .packageSelectorIfNeeded(
                packageContext: self.packageContext,
                package: package,
                componentName: self.viewModel.componentName,
                hasPurchaseButton: self.viewModel.hasPurchaseButton,
                hapticFeedbackEnabled: self.viewModel.hapticFeedbackEnabled
            )
```

Update the modifier function (lines 95-107):

```swift
    func packageSelectorIfNeeded(
        packageContext: PackageContext,
        package: Package,
        componentName: String?,
        hasPurchaseButton: Bool,
        hapticFeedbackEnabled: Bool
    ) -> some View {
        modifier(PackageSelectorIfNeeded(
            packageContext: packageContext,
            package: package,
            componentName: componentName,
            hasPurchaseButton: hasPurchaseButton,
            hapticFeedbackEnabled: hapticFeedbackEnabled
        ))
    }
```

Update the `PackageSelectorIfNeeded` struct (lines 111-152) — note it drops `private` so tests can
reach the static method:

```swift
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PackageSelectorIfNeeded: ViewModifier {

    @Environment(\.componentInteractionLogger)
    private var componentInteractionLogger
    @Environment(\.planSelectionDefaultPackage)
    private var planSelectionDefaultPackage
    @Environment(\.packageSelectionHapticFeedback)
    private var hapticFeedback

    let packageContext: PackageContext
    let package: Package
    let componentName: String?
    let hasPurchaseButton: Bool
    let hapticFeedbackEnabled: Bool

    func body(content: Content) -> some View {
        if hasPurchaseButton {
            content
        } else {
            Button {
                // Updating package with same variable context
                // This will be needed when different sets of packages
                // in different tiers
                let origin = self.packageContext.package
                if origin?.identifier != self.package.identifier {
                    self.componentInteractionLogger(
                        .paywallPackageRowSelection(
                            componentName: self.componentName,
                            destination: self.package,
                            origin: origin,
                            defaultPackage: self.planSelectionDefaultPackage
                        )
                    )
                }
                if Self.shouldTriggerHapticFeedback(
                    origin: origin,
                    destination: self.package,
                    hapticFeedbackEnabled: self.hapticFeedbackEnabled
                ) {
                    self.hapticFeedback()
                }
                self.packageContext.update(
                    package: self.package,
                    variableContext: self.packageContext.variableContext
                )
            } label: {
                content
            }
        }
    }

    static func shouldTriggerHapticFeedback(
        origin: Package?,
        destination: Package,
        hapticFeedbackEnabled: Bool
    ) -> Bool {
        return hapticFeedbackEnabled && origin?.identifier != destination.identifier
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter PackageComponentViewTests`
Expected: PASS (7 tests)

- [ ] **Step 5: Build the RevenueCatUI target to catch any call-site issues**

Run: `swift build`
Expected: builds cleanly with no errors or new warnings from this change.

- [ ] **Step 6: Commit**

```bash
git add RevenueCatUI/Templates/V2/Components/Packages/Package/PackageComponentView.swift Tests/RevenueCatUITests/PaywallsV2/PackageComponentViewTests.swift
git commit -m "feat(paywalls): fire selection haptic when package selection changes"
```

---

### Task 6: Fire the haptic on tab button selection

**Files:**
- Modify: `RevenueCatUI/Templates/V2/Components/Tabs/TabControlButtonComponentView.swift`
- Test: `Tests/RevenueCatUITests/PaywallsV2/TabControlHapticFeedbackTests.swift` (create)

**Interfaces:**
- Consumes: `PaywallComponent.TabControlButtonComponent.hapticFeedbackEnabled: Bool?` (Task 3), `EnvironmentValues.packageSelectionHapticFeedback` (Task 1).
- Produces: `TabControlButtonComponentView.shouldTriggerHapticFeedback(originTabId:destinationTabId:hapticFeedbackEnabled:) -> Bool` (internal static method).

Unlike the package selector, there is currently no origin/destination guard around
`trackTabcomponentInteraction` — it fires even on a repeat tap of the already-selected tab. That
existing analytics behavior is left untouched; only the new haptic call is gated on an actual
change, to match native selector behavior (no buzz on a no-op tap).

- [ ] **Step 1: Write the failing test**

Create `Tests/RevenueCatUITests/PaywallsV2/TabControlHapticFeedbackTests.swift`:

```swift
//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TabControlHapticFeedbackTests.swift

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import XCTest

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class TabControlHapticFeedbackTests: TestCase {

    func testShouldTriggerHapticFeedback_whenTabChangesAndEnabled_returnsTrue() {
        XCTAssertTrue(
            TabControlButtonComponentView.shouldTriggerHapticFeedback(
                originTabId: "weekly",
                destinationTabId: "annual",
                hapticFeedbackEnabled: true
            )
        )
    }

    func testShouldTriggerHapticFeedback_whenTabUnchanged_returnsFalse() {
        XCTAssertFalse(
            TabControlButtonComponentView.shouldTriggerHapticFeedback(
                originTabId: "weekly",
                destinationTabId: "weekly",
                hapticFeedbackEnabled: true
            )
        )
    }

    func testShouldTriggerHapticFeedback_whenDisabled_returnsFalseEvenIfTabChanges() {
        XCTAssertFalse(
            TabControlButtonComponentView.shouldTriggerHapticFeedback(
                originTabId: "weekly",
                destinationTabId: "annual",
                hapticFeedbackEnabled: false
            )
        )
    }

}

#endif
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter TabControlHapticFeedbackTests`
Expected: FAIL to compile — `TabControlButtonComponentView` has no `shouldTriggerHapticFeedback`
member.

- [ ] **Step 3: Write minimal implementation**

In `RevenueCatUI/Templates/V2/Components/Tabs/TabControlButtonComponentView.swift`, update the
struct:

```swift
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TabControlButtonComponentView: View {

    @EnvironmentObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    @EnvironmentObject
    private var packageContext: PackageContext

    @Environment(\.componentViewState)
    private var componentViewState

    @Environment(\.screenCondition)
    private var screenCondition

    @EnvironmentObject
    private var tabControlContext: TabControlContext

    @Environment(\.componentInteractionLogger)
    private var componentInteractionLogger

    @Environment(\.packageSelectionHapticFeedback)
    private var hapticFeedback

    private let viewModel: TabControlButtonComponentViewModel
    private let onDismiss: () -> Void

    private var selectedState: ComponentViewState {
        return self.tabControlContext.selectedTabId == self.viewModel.component.tabId ? .selected : .default
    }

    init(viewModel: TabControlButtonComponentViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        Button {
            let originTabId = self.tabControlContext.selectedTabId
            let destinationTabId = self.viewModel.component.tabId

            self.tabControlContext.selectedTabId = destinationTabId
            self.trackTabcomponentInteraction(originTabId: originTabId, destinationTabId: destinationTabId)

            if Self.shouldTriggerHapticFeedback(
                originTabId: originTabId,
                destinationTabId: destinationTabId,
                hapticFeedbackEnabled: self.viewModel.component.hapticFeedbackEnabled ?? true
            ) {
                self.hapticFeedback()
            }
        } label: {
            StackComponentView(
                viewModel: self.viewModel.stackViewModel,
                onDismiss: self.onDismiss
            )
            .environment(\.componentViewState, self.selectedState)
        }

    }

    private func trackTabcomponentInteraction(originTabId: String, destinationTabId: String) {
        let destinationContextName = self.tabControlContext.contextName(for: destinationTabId)

        _ = self.componentInteractionLogger(.paywallTabControlButtonSelection(
            componentName: self.tabControlContext.name,
            destinationTabId: destinationTabId,
            metadata: .init(
                originIndex: self.tabControlContext.index(for: originTabId),
                destinationIndex: self.tabControlContext.index(for: destinationTabId),
                originContextName: self.tabControlContext.contextName(for: originTabId),
                destinationContextName: destinationContextName,
                defaultIndex: self.tabControlContext.defaultTabIndex
            )
        ))
    }

    static func shouldTriggerHapticFeedback(
        originTabId: String,
        destinationTabId: String,
        hapticFeedbackEnabled: Bool
    ) -> Bool {
        return hapticFeedbackEnabled && originTabId != destinationTabId
    }

}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter TabControlHapticFeedbackTests`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add RevenueCatUI/Templates/V2/Components/Tabs/TabControlButtonComponentView.swift Tests/RevenueCatUITests/PaywallsV2/TabControlHapticFeedbackTests.swift
git commit -m "feat(paywalls): fire selection haptic when tab button selection changes"
```

---

### Task 7: Fire the haptic on tab toggle flip

**Files:**
- Modify: `RevenueCatUI/Templates/V2/Components/Tabs/TabControlToggleComponentView.swift`

**Interfaces:**
- Consumes: `PaywallComponent.TabControlToggleComponent.hapticFeedbackEnabled: Bool?` (Task 3), `EnvironmentValues.packageSelectionHapticFeedback` (Task 1).
- Produces: nothing consumed by later tasks — this is the last call site.

No extra change-guard is needed here: `isOn`'s `Binding<Bool>` setter (`set:`) is only invoked by
the custom `ToggleStyle`'s `configuration.isOn.toggle()`, i.e. only on an actual flip — there's no
"tap the already-selected side again" case to guard against, unlike the package/tab-button
selectors. The flag-read itself (`component.hapticFeedbackEnabled ?? true`) is already exercised
by Task 3's schema tests; this task just wires the call, matching the depth of testing already
applied to this view's existing analytics call (`componentInteractionLogger`), which also has no
dedicated tap-simulation test in this codebase.

- [ ] **Step 1: Write the minimal implementation**

In `RevenueCatUI/Templates/V2/Components/Tabs/TabControlToggleComponentView.swift`, update the
struct:

```swift
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TabControlToggleComponentView: View {

    @EnvironmentObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    @EnvironmentObject
    private var packageContext: PackageContext

    @Environment(\.componentViewState)
    private var componentViewState

    @Environment(\.screenCondition)
    private var screenCondition

    @EnvironmentObject
    private var tabControlContext: TabControlContext

    @Environment(\.componentInteractionLogger)
    private var componentInteractionLogger

    @Environment(\.packageSelectionHapticFeedback)
    private var hapticFeedback

    private let viewModel: TabControlToggleComponentViewModel
    private let onDismiss: () -> Void

    /// `selectedTabId` in `TabControlContext` is the source of truth.
    /// The toggle reads it and writes it only from user interaction.
    private var isOn: Binding<Bool> {
        Binding(
            get: {
                Self.computeIsOn(
                    selectedTabId: self.tabControlContext.selectedTabId,
                    tabIds: self.tabControlContext.tabIds
                )
            },
            set: { newValue in
                let tabIds = self.tabControlContext.tabIds
                guard tabIds.count >= 2 else { return }

                self.tabControlContext.selectedTabId = newValue ? tabIds[1] : tabIds[0]
                _ = self.componentInteractionLogger(.paywallTabControlToggle(
                    componentName: self.tabControlContext.name,
                    isOn: newValue
                ))
                if self.viewModel.component.hapticFeedbackEnabled ?? true {
                    self.hapticFeedback()
                }
            }
        )
    }

    init(viewModel: TabControlToggleComponentViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        Toggle("", isOn: self.isOn)
            .toggleStyle(
                CustomToggleStyle(
                    thumbColorOn: self.viewModel.thumbColorOn,
                    thumbColorOff: self.viewModel.thumbColorOff,
                    trackColorOn: self.viewModel.trackColorOn,
                    trackColorOff: self.viewModel.trackColorOff
                )
            )
            .labelsHidden()
    }

    /// Computes the toggle's ON state based on the selected tab.
    /// The toggle is ON when the second tab (index 1) is selected.
    private static func computeIsOn(selectedTabId: String, tabIds: [String]) -> Bool {
        guard tabIds.count == 2 else { return false }
        return selectedTabId == tabIds[1]
    }

}
```

(Only the `hapticFeedback` environment property and the `if` block inside `set:` are new; the rest
of the file — including `CustomToggleStyle` and the `#if DEBUG` preview block below it — is
unchanged.)

- [ ] **Step 2: Build to confirm it compiles**

Run: `swift build`
Expected: builds cleanly.

- [ ] **Step 3: Commit**

```bash
git add RevenueCatUI/Templates/V2/Components/Tabs/TabControlToggleComponentView.swift
git commit -m "feat(paywalls): fire selection haptic when tab toggle flips"
```

---

### Task 8: Full verification pass

**Files:** none (verification only)

**Interfaces:** none.

- [ ] **Step 1: Run the full unit test suite**

Run: `swift test`
Expected: PASS, no regressions anywhere in the suite.

- [ ] **Step 2: Run SwiftLint**

Run: `swiftlint`
Expected: no new violations. If there are violations in touched files, run `swiftlint --fix` and
re-verify with `swift test` and `swift build`.

- [ ] **Step 3: Regenerate the Tuist workspace and build it**

Run: `tuist generate && swift build`
Expected: the new test files (`PackageSelectionHapticFeedbackTests.swift`,
`PackageComponentTests.swift`, `TabsComponentTests.swift`,
`TabControlHapticFeedbackTests.swift`) are picked up by Tuist's glob-based sources with no manual
project file editing, and the workspace builds cleanly.

- [ ] **Step 4: Verify the public API surface is unaffected**

Run: `bundle exec fastlane run_api_tests`
Expected: PASS — all new members (`PackageSelectionHapticFeedback`,
`hapticFeedbackEnabled` on the three component classes, the new `init` parameters) are additive
and `@_spi(Internal)`/internal-scoped or purely additive optional params, so the public
`.swiftinterface` files should not need regeneration. If this fails, inspect the diff to confirm
it's only the expected additive change before regenerating.

- [ ] **Step 5: Manual verification note**

Document in the PR description (per repo Testability convention) that the actual haptic *feel* on
device cannot be asserted by an automated test — manual verification is: build PaywallsTester,
open a multi-package V2 paywall, tap between packages/tabs and confirm a subtle selection buzz,
then verify a paywall config with `haptic_feedback_enabled: false` produces no buzz.

- [ ] **Step 6: Final commit (if Step 2's `--fix` produced changes not yet committed)**

```bash
git add -A
git commit -m "chore: swiftlint fixes for paywall selection haptics"
```

- [ ] **Step 7: Hand off the wire contract to the dashboard team**

This SDK PR's job ends at correctly decoding and honoring the field — the dashboard Paywall
Builder editor UI to actually set it is a separate repo/team. Before or when opening the PR,
message the dashboard team (or file a ticket, per whatever the team's usual handoff channel is)
with the contract: a new optional `haptic_feedback_enabled: boolean` field on `package`,
`tab_control_button`, and `tab_control_toggle` component JSON; omitted or `null` means enabled.
