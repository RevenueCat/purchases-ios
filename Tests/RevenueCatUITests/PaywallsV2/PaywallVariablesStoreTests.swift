//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallVariablesStoreTests.swift

import Nimble
@_spi(Internal) import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class PaywallVariablesStoreTests: TestCase {

    // MARK: - Initial state

    func testStoreIsEmptyByDefault() {
        let store = PaywallVariablesStore()
        expect(store.values).to(beEmpty())
    }

    func testStoreSeedsWithProvidedInitialValues() {
        let store = PaywallVariablesStore(initialValues: [
            "selectedPlan": .string("annual"),
            "comparisonOpen": .bool(false)
        ])

        expect(store.values["selectedPlan"]) == .string("annual")
        expect(store.values["comparisonOpen"]) == .bool(false)
    }

    // MARK: - Literal updates

    func testApplyLiteralUpdateSetsValue() {
        let store = PaywallVariablesStore()

        store.apply([.set(key: "comparisonOpen", value: .literal(.bool(true)))])

        expect(store.values["comparisonOpen"]) == .bool(true)
    }

    func testApplyLiteralUpdateOverwritesExistingValue() {
        let store = PaywallVariablesStore(initialValues: ["count": .int(0)])

        store.apply([.set(key: "count", value: .literal(.int(5)))])

        expect(store.values["count"]) == .int(5)
    }

    func testApplyMultipleUpdatesInOneBatch() {
        let store = PaywallVariablesStore()

        store.apply([
            .set(key: "a", value: .literal(.string("hello"))),
            .set(key: "b", value: .literal(.int(42))),
            .set(key: "c", value: .literal(.bool(true)))
        ])

        expect(store.values["a"]) == .string("hello")
        expect(store.values["b"]) == .int(42)
        expect(store.values["c"]) == .bool(true)
    }

    func testLastWriteWinsWithinBatch() {
        let store = PaywallVariablesStore()

        store.apply([
            .set(key: "x", value: .literal(.int(1))),
            .set(key: "x", value: .literal(.int(2))),
            .set(key: "x", value: .literal(.int(3)))
        ])

        expect(store.values["x"]) == .int(3)
    }

    // MARK: - $value payload reference

    func testApplyPayloadReferenceUsesPayloadValue() {
        let store = PaywallVariablesStore()

        store.apply(
            [.set(key: "selectedTab", value: .payloadReference)],
            payload: .string("billing")
        )

        expect(store.values["selectedTab"]) == .string("billing")
    }

    func testApplyPayloadReferenceWithIntegerPayload() {
        let store = PaywallVariablesStore()

        store.apply(
            [.set(key: "currentSlide", value: .payloadReference)],
            payload: .int(3)
        )

        expect(store.values["currentSlide"]) == .int(3)
    }

    func testPayloadReferenceWithoutPayloadIsSkipped() {
        let store = PaywallVariablesStore(initialValues: ["existing": .string("kept")])

        store.apply(
            [.set(key: "existing", value: .payloadReference)],
            payload: nil
        )

        // Skipped silently — existing value remains.
        expect(store.values["existing"]) == .string("kept")
    }

    func testMixedLiteralAndPayloadInBatch() {
        let store = PaywallVariablesStore()

        store.apply(
            [
                .set(key: "literalKey", value: .literal(.bool(true))),
                .set(key: "payloadKey", value: .payloadReference)
            ],
            payload: .string("from-payload")
        )

        expect(store.values["literalKey"]) == .bool(true)
        expect(store.values["payloadKey"]) == .string("from-payload")
    }

    // MARK: - No-ops

    func testApplyEmptyBatchIsNoOp() {
        let store = PaywallVariablesStore(initialValues: ["a": .int(1)])

        store.apply([])

        expect(store.values["a"]) == .int(1)
        expect(store.values.count) == 1
    }

    func testUnsupportedUpdateIsSkipped() {
        let store = PaywallVariablesStore(initialValues: ["a": .int(1)])

        store.apply([.unsupported])

        expect(store.values["a"]) == .int(1)
        expect(store.values.count) == 1
    }

    // MARK: - Repeated apply calls

    func testRepeatedApplyAccumulatesAndOverwrites() {
        let store = PaywallVariablesStore()

        store.apply([.set(key: "a", value: .literal(.int(1)))])
        store.apply([.set(key: "b", value: .literal(.string("hi")))])
        store.apply([.set(key: "a", value: .literal(.int(99)))])

        expect(store.values["a"]) == .int(99)
        expect(store.values["b"]) == .string("hi")
    }

}

#endif
