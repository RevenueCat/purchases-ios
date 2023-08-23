import Nimble
import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting

#if !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class Template4ViewTests: BaseSnapshotTest {

    func testSamplePaywall() {
        Self.createPaywall(offering: Self.offering.withLocalImages)
            .snapshot(size: Self.fullScreenSize)
    }

    func testTabletPaywall() {
        PaywallView(offering: Self.offering.withLocalImages,
                    introEligibility: Self.eligibleChecker,
                    purchaseHandler: Self.purchaseHandler)
        // TODO: create custom environment variable for iPad
//        .environment(\.userInterfaceIdiom, .iPad)
        .snapshot(size: Self.iPadSize)
    }

    func testCustomFont() {
        Self.createPaywall(offering: Self.offering.withLocalImages,
                           fonts: Self.fonts)
        .snapshot(size: Self.fullScreenSize)
    }

    func testLargeDynamicType() {
        Self.createPaywall(offering: Self.offering.withLocalImages)
            .environment(\.dynamicTypeSize, .xxLarge)
            .snapshot(size: Self.fullScreenSize)
    }

    func testLargerDynamicType() {
        Self.createPaywall(offering: Self.offering.withLocalImages)
            .environment(\.dynamicTypeSize, .accessibility2)
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

    private static let offering = TestData.offeringWithMultiPackageHorizontalPaywall

}

#endif
