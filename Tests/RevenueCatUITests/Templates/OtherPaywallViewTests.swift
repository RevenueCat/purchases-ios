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
        Self.createPaywall(offering: TestData.offeringWithNoPaywall)
            .snapshot(size: Self.fullScreenSize)
    }

    func testDefaultSpanishPaywall() {
        Self.createPaywall(offering: TestData.offeringWithNoPaywall)
            .environment(\.locale, .init(identifier: "es_ES"))
            .snapshot(size: Self.fullScreenSize)
    }

    func testDefaultDarkModePaywall() {
        Self.createPaywall(offering: TestData.offeringWithNoPaywall)
            .environment(\.colorScheme, .dark)
            .snapshot(size: Self.fullScreenSize)
    }

    func testLoadingPaywallView() {
        LoadingPaywallView(mode: .fullScreen, shimmer: false)
            .snapshot(size: Self.fullScreenSize)
    }

    func testLoadingFooterPaywallView() {
        LoadingPaywallView(mode: .footer, shimmer: false)
            .snapshot(size: Self.footerSize)
    }

    func testLoadingCondensedFooterPaywallView() {
        LoadingPaywallView(mode: .condensedFooter, shimmer: false)
            .snapshot(size: Self.footerSize)
    }

}

#endif
