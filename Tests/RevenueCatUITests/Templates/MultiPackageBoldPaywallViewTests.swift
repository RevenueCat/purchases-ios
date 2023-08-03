import Nimble
import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting

#if !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class MultiPackageBoldPaywallViewTests: BaseSnapshotTest {

    func testSamplePaywall() {
        let view = PaywallView(offering: Self.offering.withLocalImages,
                               introEligibility: Self.eligibleChecker,
                               purchaseHandler: Self.purchaseHandler)
        view.snapshot(size: Self.fullScreenSize)
    }

    func testPurchasingState() {
        let handler = Self.purchaseHandler.with(delay: 120)

        let view = PaywallView(offering: Self.offering.withLocalImages,
                               introEligibility: Self.eligibleChecker,
                               purchaseHandler: handler)
            .task {
                _ = try? await handler.purchase(package: TestData.annualPackage)
            }

        view.snapshot(size: Self.fullScreenSize)
    }

    func testDarkMode() {
        let view = PaywallView(offering: Self.offering.withLocalImages,
                               introEligibility: Self.ineligibleChecker,
                               purchaseHandler: Self.purchaseHandler)

        view
            .environment(\.colorScheme, .dark)
            .snapshot(size: Self.fullScreenSize)
    }

    private static let offering = TestData.offeringWithMultiPackagePaywall

}

#endif
