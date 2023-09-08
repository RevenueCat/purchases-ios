import Nimble
import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting

#if !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class Template4ViewTests: BaseSnapshotTest {

    func testSamplePaywall() {
        PaywallView(offering: Self.offering.withLocalImages,
                    introEligibility: Self.eligibleChecker,
                    purchaseHandler: Self.purchaseHandler)
        .snapshot(size: Self.fullScreenSize)
    }

    func testCustomFont() {
        PaywallView(offering: Self.offering.withLocalImages,
                    fonts: Self.fonts,
                    introEligibility: Self.eligibleChecker,
                    purchaseHandler: Self.purchaseHandler)
        .snapshot(size: Self.fullScreenSize)
    }

    func testLargeDynamicType() {
        PaywallView(offering: Self.offering.withLocalImages,
                    introEligibility: Self.eligibleChecker,
                    purchaseHandler: Self.purchaseHandler)
        .environment(\.dynamicTypeSize, .xxLarge)
        .snapshot(size: Self.fullScreenSize)
    }

    func testLargerDynamicType() {
        PaywallView(offering: Self.offering.withLocalImages,
                    introEligibility: Self.eligibleChecker,
                    purchaseHandler: Self.purchaseHandler)
        .environment(\.dynamicTypeSize, .accessibility2)
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

    private static let offering = TestData.offeringWithMultiPackageHorizontalPaywall

}

#endif
