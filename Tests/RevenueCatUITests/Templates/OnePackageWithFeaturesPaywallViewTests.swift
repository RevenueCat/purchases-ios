import Nimble
import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting

#if !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class OnePackageWithFeaturesPaywallViewTests: BaseSnapshotTest {

    func testSamplePaywall() {
        let view = PaywallView(offering: Self.offering.withLocalImages,
                               introEligibility: Self.eligibleChecker,
                               purchaseHandler: Self.purchaseHandler)
        view.snapshot(size: Self.fullScreenSize)
    }

    private static let offering = TestData.offeringWithSinglePackageFeaturesPaywall

}

#endif
