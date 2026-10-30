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

    func testScrollWhenPaywallRootStackIsZLayer() {
        expect(
            PaywallZLayerScrollPolicy.shouldApplyScroll(
                stackScrollPreference: nil,
                paywallRootStackIsZLayer: true,
                ancestorScrollsVertically: false
            )
        ) == true
    }

    func testScrollWhenStackScrollingEnabled() {
        expect(
            PaywallZLayerScrollPolicy.shouldApplyScroll(
                stackScrollPreference: true,
                paywallRootStackIsZLayer: false,
                ancestorScrollsVertically: false
            )
        ) == true
    }

    func testNoScrollWhenRootExplicitlyDisablesScrolling() {
        expect(
            PaywallZLayerScrollPolicy.shouldApplyScroll(
                stackScrollPreference: false,
                paywallRootStackIsZLayer: true,
                ancestorScrollsVertically: false
            )
        ) == false
    }

    func testNoScrollWhenAncestorScrollsVertically() {
        expect(
            PaywallZLayerScrollPolicy.shouldApplyScroll(
                stackScrollPreference: true,
                paywallRootStackIsZLayer: true,
                ancestorScrollsVertically: true
            )
        ) == false
    }

    func testNoScrollWhenNotEnabledAndRootIsNotZLayer() {
        expect(
            PaywallZLayerScrollPolicy.shouldApplyScroll(
                stackScrollPreference: nil,
                paywallRootStackIsZLayer: false,
                ancestorScrollsVertically: false
            )
        ) == false
    }

}

#endif
