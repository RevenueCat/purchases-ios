import Nimble
import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting

#if !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class Template2ViewTests: BaseSnapshotTest {

    func testSamplePaywall() {
        PaywallView(offering: Self.offering.withLocalImages,
                    introEligibility: Self.eligibleChecker,
                    purchaseHandler: Self.purchaseHandler)
        .snapshot(size: Self.fullScreenSize)
    }

    func testTabletPaywall() {
        PaywallView(offering: Self.offering.withLocalImages,
                    introEligibility: Self.eligibleChecker,
                    purchaseHandler: Self.purchaseHandler)
        .environment(\.userInterfaceIdiom, .pad)
        .snapshot(size: Self.iPadSize)
    }

    func testCustomFont() {
        PaywallView(offering: Self.offering.withLocalImages,
                    fonts: Self.fonts,
                    introEligibility: Self.eligibleChecker,
                    purchaseHandler: Self.purchaseHandler)
        .snapshot(size: Self.fullScreenSize)
    }

    func testFooterPaywall() {
        PaywallView(offering: Self.offering.withLocalImages,
                    mode: .footer,
                    introEligibility: Self.eligibleChecker,
                    purchaseHandler: Self.purchaseHandler)
        .snapshot(size: Self.footerSize)
    }

    func testCondensedFooterPaywall() {
        PaywallView(offering: Self.offering.withLocalImages,
                    mode: .condensedFooter,
                    introEligibility: Self.eligibleChecker,
                    purchaseHandler: Self.purchaseHandler)
        .snapshot(size: Self.footerSize)
    }

    func testPurchasingState() {
        let handler = Self.purchaseHandler.with(delay: 120)

        let view = PaywallView(offering: Self.offering.withLocalImages,
                               introEligibility: Self.eligibleChecker,
                               purchaseHandler: handler)
            .task {
                _ = try? await handler.purchase(package: TestData.annualPackage,
                                                with: .fullScreen)
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
