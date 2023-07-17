import Nimble
import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting

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
