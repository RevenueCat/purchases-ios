import Nimble
import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting
import SwiftUI

#if !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class OnePackageStandardPaywallViewTests: BaseSnapshotTest {

    func testSamplePaywall() {
        let view = PaywallView(offering: Self.offeringWithNoIntroOffer,
                               introEligibility: Self.eligibleChecker,
                               purchaseHandler: Self.purchaseHandler)
        view.snapshot(size: Self.fullScreenSize)
    }

    // Disabled until we bring modes back.
    /*
    func testCardPaywall() {
        let view = PaywallView(offering: Self.offeringWithNoIntroOffer,
                               mode: .card,
                               introEligibility: Self.eligibleChecker,
                               purchaseHandler: Self.purchaseHandler)
            .background(.white) // Non-fullscreen views have no background

        view.snapshot(size: Self.cardSize)
    }

    func testBannerPaywall() {
        let view = PaywallView(offering: Self.offeringWithNoIntroOffer,
                               mode: .banner,
                               introEligibility: Self.eligibleChecker,
                               purchaseHandler: Self.purchaseHandler)
            .background(.white) // Non-fullscreen views have no background

        view.snapshot(size: Self.bannerSize)
    }
    */

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
