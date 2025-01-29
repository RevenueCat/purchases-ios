//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Template2ViewTests.swift

import Nimble
import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting

#if !os(watchOS) && !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class Template2ViewTests: BaseSnapshotTest {

    func testSamplePaywall() {
        Self.createPaywall(offering: Self.offering.withLocalImages)
            .snapshot(size: Self.fullScreenSize)
    }

    func testTabletPaywall() {
        Self.createPaywall(offering: Self.offering.withLocalImages)
            .snapshotTablet()
    }

    func testLandscapePaywall() {
        Self.createPaywall(offering: Self.offering.withLocalImages)
            .snapshotLandscape()
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

    func testPurchasingState() {
        let handler = Self.purchaseHandler.with(delay: 120)

        let view = Self.createPaywall(offering: Self.offering.withLocalImages,
                                      purchaseHandler: handler)
            .task {
                _ = try? await handler.purchase(package: TestData.annualPackage)
            }

        view.snapshot(size: Self.fullScreenSize)
    }

    func testDarkMode() {
        Self.createPaywall(offering: Self.offering.withLocalImages,
                           introEligibility: Self.ineligibleChecker)
            .environment(\.colorScheme, .dark)
            .snapshot(size: Self.fullScreenSize)
    }

    private static let offering = TestData.offeringWithMultiPackagePaywall

}

#endif
