//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PromotionalOfferViewModelTests.swift
//
//  Created by Facundo Menzella on 10/6/25.

import Combine
import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import StoreKit
import XCTest

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
final class PromotionalOfferViewModelTests: TestCase {

    var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }

    @MainActor
    func testActionWrapperTriggersActionOnPurchaseSuccess() async {
        let mockPurchases = MockCustomerCenterPurchases()
        let actionWrapper = CustomerCenterActionWrapper()

        var capturedAction: PromotionalOfferViewAction?
        let signedData = PromotionalOffer.SignedData(
            identifier: "id",
            keyIdentifier: "key_i",
            nonce: UUID(),
            signature: "a signature",
            timestamp: 1234
        )
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
            currencyCode: "USD",
            localizedPriceString: "",
            productIdentifier: "productIdentifier",
            productType: .nonRenewableSubscription,
            localizedDescription: "localizedDescription",
            locale: Locale(identifier: "en_US")
        )

        mockPurchases.purchaseResult = .success(
            (
                transaction: nil,
                customerInfo: CustomerInfoFixtures.customerInfoWithAmazonSubscriptions,
                userCancelled: false
            )
        )

        let viewModel = PromotionalOfferViewModel(
            promotionalOfferData: PromotionalOfferData(
                promotionalOffer: PromotionalOffer(discount: discount, signedData: signedData),
                product: product.toStoreProduct(),
                promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer(
                    iosOfferId: "offerIdentifier",
                    eligible: true,
                    title: "title",
                    subtitle: "subtitle",
                    productMapping: [:]
                )
            ),
            purchasesProvider: mockPurchases,
            actionWrapper: actionWrapper,
            onPromotionalOfferPurchaseFlowComplete: { action in
                capturedAction = action
            }
        )

        var didReceivePromotionalOfferSuccess = false
        actionWrapper.promotionalOfferSuccess
            .sink { _ in
                didReceivePromotionalOfferSuccess = true
            }
            .store(in: &cancellables)

        await viewModel.purchasePromo()

        expect(capturedAction!.isSuccess).to(beTrue())
        await expect(didReceivePromotionalOfferSuccess).toEventually(beTrue())
    }

    @MainActor
    func testOnPromotionalOfferPurchaseFlowCompleteGetsCalledOnPurchaseError() async {
        let mockPurchases = MockCustomerCenterPurchases()
        let actionWrapper = CustomerCenterActionWrapper()

        var capturedAction: PromotionalOfferViewAction?
        let signedData = PromotionalOffer.SignedData(
            identifier: "id",
            keyIdentifier: "key_i",
            nonce: UUID(),
            signature: "a signature",
            timestamp: 1234
        )
        let discount = MockStoreProductDiscount(
            offerIdentifier: "offerIdentifier",
            currencyCode: "USD",
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
            currencyCode: "USD",
            localizedPriceString: "",
            productIdentifier: "productIdentifier",
            productType: .nonRenewableSubscription,
            localizedDescription: "localizedDescription",
            locale: Locale(identifier: "en_US")
        )

        mockPurchases.purchaseResult = .failure(NSError(domain: "", code: 0))

        let viewModel = PromotionalOfferViewModel(
            promotionalOfferData: PromotionalOfferData(
                promotionalOffer: PromotionalOffer(discount: discount, signedData: signedData),
                product: product.toStoreProduct(),
                promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer(
                    iosOfferId: "offerIdentifier",
                    eligible: true,
                    title: "title",
                    subtitle: "subtitle",
                    productMapping: [:]
                )
            ),
            purchasesProvider: mockPurchases,
            actionWrapper: actionWrapper,
            onPromotionalOfferPurchaseFlowComplete: { action in
                capturedAction = action
            }
        )

        await viewModel.purchasePromo()

        expect(capturedAction!.isFailure).to(beTrue())
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension PromotionalOfferViewAction {

    var isSuccess: Bool {
        switch self {
        case .successfullyRedeemedPromotionalOffer:
            return true
        default:
            return false
        }
    }

    var isFailure: Bool {
        switch self {
        case .promotionalCodeRedemptionFailed:
            return true
        default:
            return false
        }
    }
}

#endif
