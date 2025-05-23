//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriptionDetailViewModelTests.swift
//
//  Created by Facundo Menzella on 13/5/25.

import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import StoreKit
import XCTest

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
final class SubscriptionDetailViewModelTests: TestCase {

    func testShouldShowContactSupport() {
        let viewModelAppStore = SubscriptionDetailViewModel(
            customerInfoViewModel: CustomerCenterViewModel(
                uiPreviewPurchaseProvider: MockCustomerCenterPurchases()
            ),
            screen: CustomerCenterConfigData.default.screens[.management]!,
            showPurchaseHistory: false,
            allowsMissingPurchaseAction: false,
            purchaseInformation: .yearlyExpiring(store: .appStore)
        )

        expect(viewModelAppStore.shouldShowContactSupport).to(beFalse())
        expect(viewModelAppStore.allowMissingPurchase).to(beFalse())

        let otherStores = [
            Store.macAppStore,
            .playStore,
            .stripe,
            .promotional,
            .unknownStore,
            .amazon,
            .rcBilling,
            .external
        ]

        otherStores.forEach {
            let viewModelOther = SubscriptionDetailViewModel(
                customerInfoViewModel: CustomerCenterViewModel(
                    uiPreviewPurchaseProvider: MockCustomerCenterPurchases()
                ),
                screen: CustomerCenterConfigData.default.screens[.management]!,
                showPurchaseHistory: false,
                allowsMissingPurchaseAction: true,
                purchaseInformation: .yearlyExpiring(store: $0)
            )

            expect(viewModelOther.shouldShowContactSupport).to(beTrue())
            expect(viewModelOther.allowMissingPurchase).to(beTrue())
        }
    }
}

#endif
