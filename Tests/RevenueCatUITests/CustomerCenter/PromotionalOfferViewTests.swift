//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  NewTests.swift
//
//  Created by César de la Vega Rodríguez on 7/11/25.

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import StoreKit
import SwiftUI
import XCTest

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
final class PromotionalOfferViewTests: TestCase {

    @MainActor
    func testPromotionalOfferViewCanBeInstantiatedWithoutCrashing() async {
        #if !os(watchOS) && !os(macOS)
        let mockPurchases = MockCustomerCenterPurchases()
        let actionWrapper = CustomerCenterActionWrapper()
        let signedData = PromotionalOffer.SignedData(
            identifier: "id",
            keyIdentifier: "key_i",
            nonce: UUID(),
            signature: "a signature",
            timestamp: 1234)
        let discount = MockStoreProductDiscount(
            offerIdentifier: "offerIdentifier",
            currencyCode: "usd",
            price: 1,
            localizedPriceString: "$1.00",
            paymentMode: .payAsYouGo,
            subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .month),
            numberOfPeriods: 1,
            type: .introductory
        )
        let product = TestStoreProduct(
            localizedTitle: "localizedTitle",
            price: 0,
            localizedPriceString: "",
            productIdentifier: "productIdentifier",
            productType: .nonRenewableSubscription,
            localizedDescription: "localizedDescription"
        )
        let promotionalOfferView = PromotionalOfferView(
            promotionalOffer: PromotionalOffer(discount: discount, signedData: signedData),
            product: product.toStoreProduct(),
            promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer(
                iosOfferId: "offerIdentifier",
                eligible: true,
                title: "title",
                subtitle: "subtitle",
                productMapping: [:]
            ),
            purchasesProvider: mockPurchases,
            actionWrapper: actionWrapper,
            onDismissPromotionalOfferView: { _ in }
        )
            .environment(\.appearance, CustomerCenterConfigData.mock().appearance)
            .environment(\.localization, CustomerCenterConfigData.mock().localization)
        let viewController = UIHostingController(rootView: promotionalOfferView)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        viewController.view.layoutIfNeeded()
        expect(viewController.view).toNot(beNil())
        #endif
    }

}

#endif
