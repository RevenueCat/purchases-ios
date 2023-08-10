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

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
class OtherPaywallViewTests: BaseSnapshotTest {

    func testDefaultPaywall() {
        let view = PaywallView(offering: Self.offeringWithNoPaywall,
                               introEligibility: Self.eligibleChecker,
                               purchaseHandler: Self.purchaseHandler)

        view.snapshot(size: Self.fullScreenSize)
    }

    func testDefaultDarkModePaywall() {
        let view = PaywallView(offering: Self.offeringWithNoPaywall,
                               introEligibility: Self.eligibleChecker,
                               purchaseHandler: Self.purchaseHandler)
            .environment(\.colorScheme, .dark)

        view.snapshot(size: Self.fullScreenSize)
    }

    func testLoadingPaywallView() {
        LoadingPaywallView(mode: .fullScreen)
            .snapshot(size: Self.fullScreenSize)
    }

    func testLoadingCardPaywallView() {
        LoadingPaywallView(mode: .card)
            .snapshot(size: Self.cardSize)
    }

    func testLoadingCondensedCardPaywallView() {
        LoadingPaywallView(mode: .condensedCard)
            .snapshot(size: Self.cardSize)
    }

    private static let offeringWithNoPaywall = Offering(
        identifier: "offering",
        serverDescription: "Main offering",
        metadata: [:],
        paywall: nil,
        availablePackages: TestData.packages
    )

}

#endif
