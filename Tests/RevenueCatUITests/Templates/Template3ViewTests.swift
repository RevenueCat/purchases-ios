import Nimble
import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting

#if !os(macOS)

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
class Template3ViewTests: BaseSnapshotTest {

    func testSamplePaywall() {
        PaywallView(offering: Self.offering.withLocalImages,
                    introEligibility: Self.eligibleChecker,
                    purchaseHandler: Self.purchaseHandler)
        .snapshot(size: Self.fullScreenSize)
    }

    func testDarkMode() {
        PaywallView(offering: Self.offering.withLocalImages,
                    introEligibility: Self.eligibleChecker,
                    purchaseHandler: Self.purchaseHandler)
        .environment(\.colorScheme, .dark)
        .snapshot(size: Self.fullScreenSize)
    }

    func testCustomFont() {
        PaywallView(offering: Self.offering.withLocalImages,
                    fonts: Self.fonts,
                    introEligibility: Self.eligibleChecker,
                    purchaseHandler: Self.purchaseHandler)
        .snapshot(size: Self.fullScreenSize)
    }

    func testCardPaywall() {
        PaywallView(offering: Self.offering.withLocalImages,
                    mode: .card,
                    introEligibility: Self.eligibleChecker,
                    purchaseHandler: Self.purchaseHandler)
        .snapshot(size: Self.cardSize)
    }

    func testCondensedCardPaywall() {
        PaywallView(offering: Self.offering.withLocalImages,
                    mode: .condensedCard,
                    introEligibility: Self.eligibleChecker,
                    purchaseHandler: Self.purchaseHandler)
        .snapshot(size: Self.cardSize)
    }

    private static let offering = TestData.offeringWithSinglePackageFeaturesPaywall

}

#endif
