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
        let view = LoadingPaywallView()
        view.snapshot(size: Self.fullScreenSize)
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
