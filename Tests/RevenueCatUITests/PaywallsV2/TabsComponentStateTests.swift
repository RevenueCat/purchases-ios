//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TabsComponentStateTests.swift
//

import Nimble
@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

/// Phase 1 (Tab state): a Tabs component publishes its selected-tab state into the presentation
/// store, and other components re-resolve their `state`-conditioned overrides against the snapshot.
/// These tests cover that read path end to end at the resolver level, plus the store mutation the
/// view performs on selection (`stateUpdates` + `$value` payload = selected tab id).
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TabsComponentStateTests: TestCase {

    private static let stateKey = "selectedFeatureTab"

    private static let declarations: [String: PaywallComponent.StateDeclaration] = [
        stateKey: .init(type: "string", defaultValue: .string("monthly"))
    ]

    /// A single override that makes a component visible only while the selected tab is "annual".
    private static func visibleWhenAnnualOverrides()
    -> PresentedOverrides<PaywallComponent.PartialStackComponent> {
        [
            PresentedOverride(
                conditions: [.state(operator: .equals, name: stateKey, value: .string("annual"))],
                properties: PaywallComponent.PartialStackComponent(visible: true)
            )
        ]
    }

    private static func buildVisibilityPartial(
        stateValues: [String: PaywallComponent.ConditionValue],
        stateDefaults: [String: PaywallComponent.ConditionValue]
    ) -> PaywallComponent.PartialStackComponent? {
        PaywallComponent.PartialStackComponent.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: ConditionContext(
                stateValues: stateValues,
                stateDefaults: stateDefaults
            ),
            with: visibleWhenAnnualOverrides()
        )
    }

    // MARK: - Resolver reads the state snapshot

    func testStateOverrideAppliesWhenSnapshotMatches() {
        let partial = Self.buildVisibilityPartial(
            stateValues: [Self.stateKey: .string("annual")],
            stateDefaults: [Self.stateKey: .string("monthly")]
        )

        expect(partial?.visible).to(equal(true))
    }

    func testStateOverrideDoesNotApplyWhenSnapshotDiffers() {
        let partial = Self.buildVisibilityPartial(
            stateValues: [Self.stateKey: .string("monthly")],
            stateDefaults: [Self.stateKey: .string("monthly")]
        )

        // No override matched, so nothing was combined.
        expect(partial).to(beNil())
    }

    func testStateOverrideFallsBackToDeclaredDefaultWhenKeyHasNoValue() {
        // Key declared (default "annual") but not present in the live snapshot → uses the default.
        let partial = Self.buildVisibilityPartial(
            stateValues: [:],
            stateDefaults: [Self.stateKey: .string("annual")]
        )

        expect(partial?.visible).to(equal(true))
    }

    func testUndeclaredStateKeyNeverApplies() {
        // Neither a value nor a declared default for the key → the override is never applied,
        // matching the spec rule that an undeclared `state` reference evaluates to false.
        let partial = Self.buildVisibilityPartial(stateValues: [:], stateDefaults: [:])

        expect(partial).to(beNil())
    }

    // MARK: - Tab selection mutates the store (mirrors the view's dispatch)

    func testApplyingTabSelectionUpdatesSnapshotAndFlipsResolution() {
        let store = PaywallStateStore(declarations: Self.declarations)

        // Default tab → override should not apply yet.
        expect(Self.buildVisibilityPartial(
            stateValues: store.values,
            stateDefaults: store.defaults
        )).to(beNil())

        // Selecting the "annual" tab publishes `{ "set": <key>, "to": "$value" }` with the tab id.
        store.apply(
            [.set(key: Self.stateKey, value: .payloadReference)],
            payload: .string("annual")
        )

        expect(store.values[Self.stateKey]).to(equal(.string("annual")))
        expect(Self.buildVisibilityPartial(
            stateValues: store.values,
            stateDefaults: store.defaults
        )?.visible).to(equal(true))
    }

}

#endif
