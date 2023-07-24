import Nimble
import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting

#if !os(macOS)

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
class SinglePackagePaywallViewTests: BaseSnapshotTest {

    func testSamplePaywall() {
        let offering = TestData.offeringWithNoIntroOffer

        let view = PaywallView(offering: offering,
                               paywall: offering.paywallWithLocalImages,
                               introEligibility: Self.eligibleChecker,
                               purchaseHandler: Self.purchaseHandler)
        view.snapshot(size: Self.fullScreenSize)
    }

    func testCardPaywall() {
        let offering = TestData.offeringWithNoIntroOffer

        let view = PaywallView(offering: offering,
                               paywall: offering.paywallWithLocalImages,
                               mode: .card,
                               introEligibility: Self.eligibleChecker,
                               purchaseHandler: Self.purchaseHandler)
        view.snapshot(size: Self.cardSize)
    }

    func testBannerPaywall() {
        let offering = TestData.offeringWithNoIntroOffer

        let view = PaywallView(offering: offering,
                               paywall: offering.paywallWithLocalImages,
                               mode: .banner,
                               introEligibility: Self.eligibleChecker,
                               purchaseHandler: Self.purchaseHandler)
        view.snapshot(size: Self.bannerSize)
    }

    func testSamplePaywallWithIntroOffer() {
        let offering = TestData.offeringWithIntroOffer

        let view = PaywallView(offering: offering,
                               paywall: offering.paywallWithLocalImages,
                               introEligibility: Self.eligibleChecker,
                               purchaseHandler: Self.purchaseHandler)

        view.snapshot(size: Self.fullScreenSize)
    }

    func testSamplePaywallWithIneligibleIntroOffer() {
        let offering = TestData.offeringWithIntroOffer

        let view = PaywallView(offering: offering,
                               paywall: offering.paywallWithLocalImages,
                               introEligibility: Self.ineligibleChecker,
                               purchaseHandler: Self.purchaseHandler)

        view.snapshot(size: Self.fullScreenSize)
    }

    func testSamplePaywallWithLoadingEligibility() {
        let offering = TestData.offeringWithIntroOffer

        let view = PaywallView(
            offering: offering,
            paywall: offering.paywallWithLocalImages,
            introEligibility: Self.ineligibleChecker
                .with(delay: .seconds(30)),
            purchaseHandler: Self.purchaseHandler
        )

        view.snapshot(size: Self.fullScreenSize)
    }

    func testDarkMode() {
        let offering = TestData.offeringWithIntroOffer

        let view = PaywallView(offering: offering,
                               paywall: offering.paywallWithLocalImages,
                               introEligibility: Self.ineligibleChecker,
                               purchaseHandler: Self.purchaseHandler)

        view
            .environment(\.colorScheme, .dark)
            .snapshot(size: Self.fullScreenSize)
    }

}

#endif
