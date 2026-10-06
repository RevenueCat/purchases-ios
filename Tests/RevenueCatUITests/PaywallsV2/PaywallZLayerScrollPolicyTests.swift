//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallZLayerScrollPolicyTests.swift
//

import Nimble
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PaywallZLayerScrollPolicyTests: TestCase {

    func testRootZLayerScrollsWhenOverflowIsUnset() {
        expect(Self.shouldScroll(preference: nil, isRoot: true)) == true
    }

    func testRootZLayerScrollsWhenOverflowIsScroll() {
        expect(Self.shouldScroll(preference: true, isRoot: true)) == true
    }

    func testRootZLayerDoesNotScrollWhenOverflowIsDefault() {
        expect(Self.shouldScroll(preference: false, isRoot: true)) == false
    }

    func testNonRootZLayerNeverScrollsForAnyOverflowOrAncestor() {
        let preferences: [Bool?] = [nil, true, false]
        for preference in preferences {
            for ancestorScrolls in [false, true] {
                XCTAssertFalse(Self.shouldScroll(
                    preference: preference,
                    isRoot: false,
                    ancestorScrolls: ancestorScrolls
                ), "Non-root z-layer scrolled: overflow \(String(describing: preference)), ancestor \(ancestorScrolls)")
            }
        }
    }

    func testNestedZLayerDoesNotScrollWhenRootZLayerDisablesScrolling() {
        let rootScrolls = Self.shouldScroll(preference: false, isRoot: true)
        expect(rootScrolls) == false
        expect(Self.shouldScroll(preference: nil, isRoot: false, ancestorScrolls: rootScrolls)) == false
    }

    func testRootZLayerDoesNotAddScrollingInsideScrollingAncestor() {
        for preference: Bool? in [nil, true, false] {
            expect(Self.shouldScroll(preference: preference, isRoot: true, ancestorScrolls: true)) == false
        }
    }

    private static func shouldScroll(
        preference: Bool?,
        isRoot: Bool,
        ancestorScrolls: Bool = false
    ) -> Bool {
        PaywallZLayerScrollPolicy.shouldApplyScroll(
            stackScrollPreference: preference,
            isRootStack: isRoot,
            ancestorScrollsVertically: ancestorScrolls
        )
    }

}

#endif
