//
//  DefaultPaywallViewTests.swift
//  
//
//  Created by Nacho Soto on 7/20/23.
//

import Nimble
import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting

#if !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class OtherPaywallViewTests: BaseSnapshotTest {

    func testDefaultPaywall() {
        let view = PaywallView(offering: TestData.offeringWithNoPaywall,
                               introEligibility: Self.eligibleChecker,
                               purchaseHandler: Self.purchaseHandler)

        view.snapshot(size: Self.fullScreenSize)
    }

    func testDefaultDarkModePaywall() {
        let view = PaywallView(offering: TestData.offeringWithNoPaywall,
                               introEligibility: Self.eligibleChecker,
                               purchaseHandler: Self.purchaseHandler)
            .environment(\.colorScheme, .dark)

        view.snapshot(size: Self.fullScreenSize)
    }

    func testLoadingPaywallView() {
        LoadingPaywallView(mode: .fullScreen)
            .snapshot(size: Self.fullScreenSize)
    }

    func testLoadingFooterPaywallView() {
        LoadingPaywallView(mode: .footer)
            .snapshot(size: Self.footerSize)
    }

    func testLoadingCondensedFooterPaywallView() {
        LoadingPaywallView(mode: .condensedFooter)
            .snapshot(size: Self.footerSize)
    }

}

#endif
