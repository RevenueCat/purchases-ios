import Nimble
import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting
import SwiftUI

#if !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class Template1ViewTests: BaseSnapshotTest {

    func testSamplePaywall() {
        Self.createPaywall(offering: Self.offeringWithNoIntroOffer)
            .snapshot(size: Self.fullScreenSize)
    }

    func testCustomFont() {
        Self.createPaywall(offering: Self.offeringWithNoIntroOffer,
                           fonts: Self.fonts)
        .snapshot(size: Self.fullScreenSize)
    }

    func testFooterPaywall() {
        Self.createPaywall(offering: Self.offeringWithNoIntroOffer,
                           mode: .footer)
        .snapshot(size: Self.footerSize)
    }

    func testCondensedFooterPaywall() {
        Self.createPaywall(offering: Self.offeringWithNoIntroOffer,
                           mode: .condensedFooter)
        .snapshot(size: Self.footerSize)
    }

    func testSamplePaywallWithIntroOffer() {
        Self.createPaywall(offering: Self.offeringWithIntroOffer)
            .snapshot(size: Self.fullScreenSize)
    }

    func testSamplePaywallWithIneligibleIntroOffer() {
        Self.createPaywall(offering: Self.offeringWithIntroOffer,
                           introEligibility: Self.ineligibleChecker)
            .snapshot(size: Self.fullScreenSize)
    }

    func testSamplePaywallWithLoadingEligibility() {
        let view = Self.createPaywall(
            offering: Self.offeringWithIntroOffer,
            introEligibility: Self.ineligibleChecker
                .with(delay: 30),
            purchaseHandler: Self.purchaseHandler
        )

        view.snapshot(size: Self.fullScreenSize)
    }

    func testDarkMode() {
        Self.createPaywall(offering: Self.offeringWithIntroOffer,
                           introEligibility: Self.ineligibleChecker)
            .environment(\.colorScheme, .dark)
            .snapshot(size: Self.fullScreenSize)
    }

    private static let offeringWithIntroOffer = TestData.offeringWithIntroOffer.withLocalImages
    private static let offeringWithNoIntroOffer = TestData.offeringWithNoIntroOffer.withLocalImages

}

#endif
