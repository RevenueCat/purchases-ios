import Nimble
import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting

#if !os(macOS)

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
class PaywallViewTests: BaseSnapshotTest {

    func testSamplePaywall() {
        let offering = TestData.offeringWithNoIntroOffer

        let view = PaywallView(offering: offering,
                               paywall: offering.paywallWithLocalImage,
                               introEligibility: Self.eligibleChecker,
                               purchaseHandler: Self.purchaseHandler)
        view.snapshot(size: Self.fullScreenSize)
    }

    func testSquarePaywall() {
        let offering = TestData.offeringWithNoIntroOffer

        let view = PaywallView(offering: offering,
                               paywall: offering.paywallWithLocalImage,
                               mode: .square,
                               introEligibility: Self.eligibleChecker,
                               purchaseHandler: Self.purchaseHandler)
        view.snapshot(size: Self.squareSize)
    }

    func testBannerPaywall() {
        let offering = TestData.offeringWithNoIntroOffer

        let view = PaywallView(offering: offering,
                               paywall: offering.paywallWithLocalImage,
                               mode: .banner,
                               introEligibility: Self.eligibleChecker,
                               purchaseHandler: Self.purchaseHandler)
        view.snapshot(size: Self.bannerSize)
    }

    func testSamplePaywallWithIntroOffer() {
        let offering = TestData.offeringWithIntroOffer

        let view = PaywallView(offering: offering,
                               paywall: offering.paywallWithLocalImage,
                               introEligibility: Self.eligibleChecker,
                               purchaseHandler: Self.purchaseHandler)

        view.snapshot(size: Self.fullScreenSize)
    }

    func testSamplePaywallWithIneligibleIntroOffer() {
        let offering = TestData.offeringWithIntroOffer

        let view = PaywallView(offering: offering,
                               paywall: offering.paywallWithLocalImage,
                               introEligibility: Self.ineligibleChecker,
                               purchaseHandler: Self.purchaseHandler)

        view.snapshot(size: Self.fullScreenSize)
    }

    func testSamplePaywallWithLoadingEligibility() {
        let offering = TestData.offeringWithIntroOffer

        let view = PaywallView(
            offering: offering,
            paywall: offering.paywallWithLocalImage,
            introEligibility: Self.ineligibleChecker
                .with(delay: .seconds(30)),
            purchaseHandler: Self.purchaseHandler
        )

        view.snapshot(size: Self.fullScreenSize)
    }

    func testDarkMode() {
        let offering = TestData.offeringWithIntroOffer

        let view = PaywallView(offering: offering,
                               paywall: offering.paywallWithLocalImage,
                               introEligibility: Self.ineligibleChecker,
                               purchaseHandler: Self.purchaseHandler)

        view
            .environment(\.colorScheme, .dark)
            .snapshot(size: Self.fullScreenSize)
    }

}

#endif
