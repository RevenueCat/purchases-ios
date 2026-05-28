//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StackScrollBehaviorTests.swift
//
//  Created by RevenueCat on 5/28/26.

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class StackScrollBehaviorTests: TestCase {

    func testStackScrollingIsEnabledWhenOverflowIsScroll() {
        expect(
            StackScrollBehavior.stackScrollingIsEnabled(
                overflow: .scroll,
                isScrollableByDefault: false
            )
        ) == true
    }

    func testStackScrollingIsEnabledWhenScrollableByDefault() {
        expect(
            StackScrollBehavior.stackScrollingIsEnabled(
                overflow: nil,
                isScrollableByDefault: true
            )
        ) == true
    }

    func testStackScrollingIsDisabledForDefaultOverflow() {
        expect(
            StackScrollBehavior.stackScrollingIsEnabled(
                overflow: .default,
                isScrollableByDefault: true
            )
        ) == false
    }

    func testZLayerScrollIsDisabledWhenAncestorScrollsVertically() {
        expect(
            StackScrollBehavior.shouldApplyZLayerScroll(
                overflow: .scroll,
                isScrollableByDefault: false,
                ancestorScrollsVertically: true
            )
        ) == false
    }

    func testZLayerScrollIsEnabledWhenOverflowScrollAndNoAncestorScroll() {
        expect(
            StackScrollBehavior.shouldApplyZLayerScroll(
                overflow: .scroll,
                isScrollableByDefault: false,
                ancestorScrollsVertically: false
            )
        ) == true
    }

    func testZLayerScrollIsDisabledWithoutOverflowScroll() {
        expect(
            StackScrollBehavior.shouldApplyZLayerScroll(
                overflow: .default,
                isScrollableByDefault: false,
                ancestorScrollsVertically: false
            )
        ) == false
    }

    func testShouldWrapPaywallContentWhenRootDoesNotScrollVertically() {
        expect(
            StackScrollBehavior.shouldWrapPaywallContentInVerticalScroll(
                rootStackOverflow: .default,
                rootStackIsScrollableByDefault: false
            )
        ) == true
    }

    func testShouldNotWrapPaywallContentWhenRootScrollsByDefault() {
        expect(
            StackScrollBehavior.shouldWrapPaywallContentInVerticalScroll(
                rootStackOverflow: nil,
                rootStackIsScrollableByDefault: true
            )
        ) == false
    }

    func testPaywallContentFrameAlignmentUsesTopForStickyFooter() {
        expect(
            StackScrollBehavior.paywallContentFrameAlignment(
                stickyFooterPresent: true,
                rootFrameAlignment: .center
            )
        ) == .top
    }

    func testPaywallContentFrameAlignmentPreservesRootAlignmentWithoutStickyFooter() {
        expect(
            StackScrollBehavior.paywallContentFrameAlignment(
                stickyFooterPresent: false,
                rootFrameAlignment: .center
            )
        ) == .center
    }

    func testShouldExpandPaywallContentForStickyFooterOrFillHeight() {
        expect(
            StackScrollBehavior.shouldExpandPaywallContentToAvailableHeight(
                stickyFooterPresent: true,
                rootHeightIsFill: false
            )
        ) == true

        expect(
            StackScrollBehavior.shouldExpandPaywallContentToAvailableHeight(
                stickyFooterPresent: false,
                rootHeightIsFill: true
            )
        ) == true

        expect(
            StackScrollBehavior.shouldExpandPaywallContentToAvailableHeight(
                stickyFooterPresent: false,
                rootHeightIsFill: false
            )
        ) == false
    }

}

#endif
