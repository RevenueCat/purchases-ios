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

    func testCustomFont() {
        PaywallView(offering: Self.offering.withLocalImages,
                    fonts: Self.fonts,
                    introEligibility: Self.eligibleChecker,
                    purchaseHandler: Self.purchaseHandler)
        .snapshot(size: Self.fullScreenSize)
    }

    private static let offering = TestData.offeringWithSinglePackageFeaturesPaywall

}

#endif
