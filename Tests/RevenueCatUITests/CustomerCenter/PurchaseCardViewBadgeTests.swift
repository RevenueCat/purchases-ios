//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseCardViewBadgeTests.swift
//
//  Created by Facundo Menzella on 12/6/25.

import Nimble
@_spi(Internal) import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
final class PurchaseCardViewBadgeTests: TestCase {

    func testPromoBadge() {
        let badge = PurchaseInformationCardView.Badge(
            purchaseInformation: .mock(
                productIdentifier: "rc_promo_asdasd",
                store: .promotional,
                isCancelled: false,
                isExpired: false
            ),
            localization: CustomerCenterConfigData.default.localization
        )

        expect(badge?.title) == CCLocalizedString.active.defaultValue
    }

    func testPromoCancelledBadge() {
        let badge = PurchaseInformationCardView.Badge(
            purchaseInformation: .mock(
                productIdentifier: "rc_promo_asdasd",
                store: .promotional,
                isCancelled: true,
                isExpired: false
            ),
            localization: CustomerCenterConfigData.default.localization
        )

        expect(badge?.title) == CCLocalizedString.active.defaultValue
    }

    func testExpiredBadge() {
        let badge = PurchaseInformationCardView.Badge(
            purchaseInformation: .expired,
            localization: CustomerCenterConfigData.default.localization
        )

        expect(badge?.title) == CCLocalizedString.expired.defaultValue
    }

    func testCancelledBadge() {
        let badge = PurchaseInformationCardView.Badge(
            purchaseInformation: .mock(isCancelled: true),
            localization: CustomerCenterConfigData.default.localization
        )

        expect(badge?.title) == CCLocalizedString.badgeCancelled.defaultValue
    }

    func testFreeTrialBadge() {
        let badge = PurchaseInformationCardView.Badge(
            purchaseInformation: .mock(pricePaid: .free, isTrial: true, isCancelled: false),
            localization: CustomerCenterConfigData.default.localization
        )

        expect(badge?.title) == CCLocalizedString.badgeFreeTrial.defaultValue
    }

    func testFreeTrialCancelledBadge() {
        let badge = PurchaseInformationCardView.Badge(
            purchaseInformation: .mock(isTrial: true, isCancelled: true),
            localization: CustomerCenterConfigData.default.localization
        )

        expect(badge?.title) == CCLocalizedString.badgeTrialCancelled.defaultValue
    }

    func testActiveBadge() {
        let badge = PurchaseInformationCardView.Badge(
            purchaseInformation: .mock(isCancelled: false, isExpired: false),
            localization: CustomerCenterConfigData.default.localization
        )

        expect(badge?.title) == CCLocalizedString.active.defaultValue
    }

}

#endif
