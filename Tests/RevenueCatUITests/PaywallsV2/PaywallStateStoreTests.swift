//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallStateStoreTests.swift
//

import Combine
import Nimble
@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PaywallStateStoreTests: TestCase {

    private static let declarations: [String: PaywallComponent.StateDeclaration] = [
        "planComparisonOpen": .init(type: "boolean", defaultValue: .bool(false)),
        "activeSlide": .init(type: "integer", defaultValue: .int(0)),
        "discountMultiplier": .init(type: "double", defaultValue: .double(0.5)),
        "selectedFeatureTab": .init(type: "string", defaultValue: .string("billing"))
    ]

    // MARK: - Seeding

    func testStoreSeededFromDeclaredDefaults() {
        let store = PaywallStateStore(declarations: Self.declarations)

        expect(store.values["planComparisonOpen"]).to(equal(.bool(false)))
        expect(store.values["activeSlide"]).to(equal(.int(0)))
        expect(store.values["discountMultiplier"]).to(equal(.double(0.5)))
        expect(store.values["selectedFeatureTab"]).to(equal(.string("billing")))
    }

    func testEmptyStoreHasNoValues() {
        let store = PaywallStateStore()

        expect(store.values).to(beEmpty())
        expect(store.defaults).to(beEmpty())
    }

    func testSeedingNormalizesDoubleTypedIntegralDefault() {
        let store = PaywallStateStore(declarations: [
            "multiplier": .init(type: "double", defaultValue: .int(1))
        ])

        expect(store.values["multiplier"]).to(equal(.double(1)))
    }

    // MARK: - Updates

    func testSetUpdateWritesLiteralValue() {
        let store = PaywallStateStore(declarations: Self.declarations)

        store.apply([.set(key: "planComparisonOpen", value: .literal(.bool(true)))])

        expect(store.values["planComparisonOpen"]).to(equal(.bool(true)))
    }

    func testSetUpdateSubstitutesPayloadForPayloadReference() {
        let store = PaywallStateStore(declarations: Self.declarations)

        store.apply([.set(key: "activeSlide", value: .payloadReference)], payload: .int(3))

        expect(store.values["activeSlide"]).to(equal(.int(3)))
    }

    func testPayloadReferenceWithoutPayloadIsIgnored() {
        let store = PaywallStateStore(declarations: Self.declarations)

        store.apply([.set(key: "activeSlide", value: .payloadReference)], payload: nil)

        expect(store.values["activeSlide"]).to(equal(.int(0)))
    }

    func testUpdatesAppliedInDeclaredOrder() {
        let store = PaywallStateStore(declarations: Self.declarations)

        store.apply([
            .set(key: "selectedFeatureTab", value: .literal(.string("usage"))),
            .set(key: "selectedFeatureTab", value: .literal(.string("support")))
        ])

        expect(store.values["selectedFeatureTab"]).to(equal(.string("support")))
    }

    func testWriteToUndeclaredKeyIsIgnored() {
        let store = PaywallStateStore(declarations: Self.declarations)

        store.apply([.set(key: "undeclared", value: .literal(.bool(true)))])

        expect(store.values["undeclared"]).to(beNil())
    }

    func testTypeMismatchedWriteIsIgnored() {
        let store = PaywallStateStore(declarations: Self.declarations)

        // String written to a boolean key keeps the current value.
        store.apply([.set(key: "planComparisonOpen", value: .literal(.string("true")))])

        expect(store.values["planComparisonOpen"]).to(equal(.bool(false)))
    }

    func testIntegralWriteToDoubleKeyIsCoerced() {
        let store = PaywallStateStore(declarations: Self.declarations)

        store.apply([.set(key: "discountMultiplier", value: .literal(.int(2)))])

        expect(store.values["discountMultiplier"]).to(equal(.double(2)))
    }

    func testIntegralDoubleWriteToIntegerKeyIsCoerced() {
        let store = PaywallStateStore(declarations: Self.declarations)

        store.apply([.set(key: "activeSlide", value: .literal(.double(4)))])

        expect(store.values["activeSlide"]).to(equal(.int(4)))
    }

    func testNonIntegralDoubleWriteToIntegerKeyIsIgnored() {
        let store = PaywallStateStore(declarations: Self.declarations)

        store.apply([.set(key: "activeSlide", value: .literal(.double(1.5)))])

        expect(store.values["activeSlide"]).to(equal(.int(0)))
    }

    func testUnsupportedUpdateIsIgnored() {
        let store = PaywallStateStore(declarations: Self.declarations)

        store.apply([.unsupported])

        expect(store.values).to(equal(store.defaults))
    }

    // MARK: - Reset

    func testResetRestoresDeclaredDefaults() {
        let store = PaywallStateStore(declarations: Self.declarations)
        store.apply([
            .set(key: "planComparisonOpen", value: .literal(.bool(true))),
            .set(key: "activeSlide", value: .literal(.int(5)))
        ])

        store.reset()

        expect(store.values["planComparisonOpen"]).to(equal(.bool(false)))
        expect(store.values["activeSlide"]).to(equal(.int(0)))
    }

    // MARK: - Incremental declarations

    func testRegisterDeclarationsAddsNewKeys() {
        let store = PaywallStateStore()

        store.registerDeclarations(["newKey": .init(type: "boolean", defaultValue: .bool(true))])

        expect(store.values["newKey"]).to(equal(.bool(true)))
        expect(store.defaults["newKey"]).to(equal(.bool(true)))
    }

    func testRegisterDeclarationsDoesNotOverwriteExistingKeys() {
        let store = PaywallStateStore(declarations: Self.declarations)
        store.apply([.set(key: "planComparisonOpen", value: .literal(.bool(true)))])

        store.registerDeclarations([
            "planComparisonOpen": .init(type: "boolean", defaultValue: .bool(false))
        ])

        // Mutated value and original default are both preserved.
        expect(store.values["planComparisonOpen"]).to(equal(.bool(true)))
        expect(store.defaults["planComparisonOpen"]).to(equal(.bool(false)))
    }

    // MARK: - Change notifications

    func testApplyNotifiesObserversOnChange() {
        let store = PaywallStateStore(declarations: Self.declarations)
        var changeCount = 0
        let cancellable = store.objectWillChange.sink { changeCount += 1 }
        defer { cancellable.cancel() }

        // Applied from the main thread, so the notification is delivered synchronously.
        store.apply([.set(key: "planComparisonOpen", value: .literal(.bool(true)))])

        expect(changeCount).to(equal(1))
    }

    func testNoOpApplyDoesNotNotifyObservers() {
        let store = PaywallStateStore(declarations: Self.declarations)
        var changeCount = 0
        let cancellable = store.objectWillChange.sink { changeCount += 1 }
        defer { cancellable.cancel() }

        // Writing the value the key already holds is a no-op.
        store.apply([.set(key: "planComparisonOpen", value: .literal(.bool(false)))])

        expect(changeCount).to(equal(0))
    }

    // MARK: - Thread safety

    func testConcurrentReadsAndWritesDoNotCrashAndLandOnAValidValue() {
        let store = PaywallStateStore(declarations: Self.declarations)
        let iterations = 500

        DispatchQueue.concurrentPerform(iterations: iterations) { index in
            store.apply([.set(key: "activeSlide", value: .literal(.int(index)))])
            _ = store.values
            _ = store.defaults
            if index.isMultiple(of: 7) {
                store.registerDeclarations([
                    "key\(index)": .init(type: "integer", defaultValue: .int(index))
                ])
            }
        }

        guard case .int(let finalValue)? = store.values["activeSlide"] else {
            fail("Expected an int value for activeSlide")
            return
        }
        expect(finalValue).to(beGreaterThanOrEqualTo(0))
        expect(finalValue).to(beLessThan(iterations))
    }

}

#endif
