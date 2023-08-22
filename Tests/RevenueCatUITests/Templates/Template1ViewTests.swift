import Nimble
import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting
import SwiftUI

#if !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class Template1ViewTests: BaseSnapshotTest {

    func testSamplePaywall() {
        PaywallView(offering: Self.offeringWithNoIntroOffer,
                    introEligibility: Self.eligibleChecker,
                    purchaseHandler: Self.purchaseHandler)
        .snapshot(size: Self.fullScreenSize)
    }

    func testCustomFont() {
        PaywallView(offering: Self.offeringWithNoIntroOffer,
                    fonts: Self.fonts,
                    introEligibility: Self.eligibleChecker,
                    purchaseHandler: Self.purchaseHandler)
        .snapshot(size: Self.fullScreenSize)
    }

    func testFooterPaywall() {
        PaywallView(offering: Self.offeringWithNoIntroOffer,
                    mode: .footer,
                    introEligibility: Self.eligibleChecker,
                    purchaseHandler: Self.purchaseHandler)
        .snapshot(size: Self.footerSize)
    }

    func testCondensedFooterPaywall() {
        PaywallView(offering: Self.offeringWithNoIntroOffer,
                    mode: .condensedFooter,
                    introEligibility: Self.eligibleChecker,
                    purchaseHandler: Self.purchaseHandler)
        .snapshot(size: Self.footerSize)
    }

    func testSamplePaywallWithIntroOffer() {
        let view = PaywallView(offering: Self.offeringWithIntroOffer,
                               introEligibility: Self.eligibleChecker,
                               purchaseHandler: Self.purchaseHandler)

        view.snapshot(size: Self.fullScreenSize)
    }

    func testSamplePaywallWithIneligibleIntroOffer() {
        let view = PaywallView(offering: Self.offeringWithIntroOffer,
                               introEligibility: Self.ineligibleChecker,
                               purchaseHandler: Self.purchaseHandler)

        view.snapshot(size: Self.fullScreenSize)
    }

    func testSamplePaywallWithLoadingEligibility() {
        let view = PaywallView(
            offering: Self.offeringWithIntroOffer,
            introEligibility: Self.ineligibleChecker
                .with(delay: 30),
            purchaseHandler: Self.purchaseHandler
        )

        view.snapshot(size: Self.fullScreenSize)
    }

    func testDarkMode() {
        let view = PaywallView(offering: Self.offeringWithIntroOffer,
                               introEligibility: Self.ineligibleChecker,
                               purchaseHandler: Self.purchaseHandler)

        view
            .environment(\.colorScheme, .dark)
            .snapshot(size: Self.fullScreenSize)
    }

    private static let offeringWithIntroOffer = TestData.offeringWithIntroOffer.withLocalImages
    private static let offeringWithNoIntroOffer = TestData.offeringWithNoIntroOffer.withLocalImages

}

#endif
