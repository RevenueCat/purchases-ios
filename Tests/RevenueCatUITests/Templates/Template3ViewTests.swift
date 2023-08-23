import Nimble
import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting

#if !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class Template3ViewTests: BaseSnapshotTest {

    func testSamplePaywall() {
        Self.createPaywall(offering: Self.offering.withLocalImages)
            .snapshot(size: Self.fullScreenSize)
    }

    func testTabletPaywall() {
        PaywallView(offering: Self.offering.withLocalImages,
                    introEligibility: Self.eligibleChecker,
                    purchaseHandler: Self.purchaseHandler)
        .environment(\.userInterfaceIdiom, .pad)
        .snapshot(size: Self.iPadSize)
    }

    func testDarkMode() {
        Self.createPaywall(offering: Self.offering.withLocalImages)
            .environment(\.colorScheme, .dark)
            .snapshot(size: Self.fullScreenSize)
    }

    func testCustomFont() {
        Self.createPaywall(offering: Self.offering.withLocalImages,
                           fonts: Self.fonts)
        .snapshot(size: Self.fullScreenSize)
    }

    func testFooterPaywall() {
        Self.createPaywall(offering: Self.offering.withLocalImages,
                           mode: .footer)
        .snapshot(size: Self.footerSize)
    }

    func testCondensedFooterPaywall() {
        Self.createPaywall(offering: Self.offering.withLocalImages,
                           mode: .condensedFooter)
        .snapshot(size: Self.footerSize)
    }

    private static let offering = TestData.offeringWithSinglePackageFeaturesPaywall

}

#endif
