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

    // MARK: - Helpers

    @MainActor
    private func makeViewModel(
        mockPurchases: MockCustomerCenterPurchases,
        actionWrapper: CustomerCenterActionWrapper,
        onComplete: @escaping (PromotionalOfferViewAction) -> Void
    ) -> PromotionalOfferViewModel {
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
        return PromotionalOfferViewModel(
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
            onPromotionalOfferPurchaseFlowComplete: onComplete
        )
    }

    // MARK: - Tests

    @MainActor
    func testActionWrapperTriggersActionOnPurchaseSuccess() async {
        let mockPurchases = MockCustomerCenterPurchases()
        let actionWrapper = CustomerCenterActionWrapper()

        var capturedAction: PromotionalOfferViewAction?
        let mockTransaction = StoreTransaction(MockStoreTransaction())
        mockPurchases.purchaseResult = .success(
            (
                transaction: mockTransaction,
                customerInfo: CustomerInfoFixtures.customerInfoWithAppleSubscriptions,
                userCancelled: false
            )
        )

        let viewModel = makeViewModel(
            mockPurchases: mockPurchases,
            actionWrapper: actionWrapper,
            onComplete: { capturedAction = $0 }
        )

        var didReceivePromotionalOfferSuccess = false
        actionWrapper.promotionalOfferSuccess
            .sink { _ in
                didReceivePromotionalOfferSuccess = true
            }
            .store(in: &cancellables)

        var receivedOfferId: String?
        actionWrapper.promotionalOfferSucceeded
            .sink { _, _, offerId in
                receivedOfferId = offerId
            }
            .store(in: &cancellables)

        await viewModel.purchasePromo()

        expect(capturedAction!.isSuccess).to(beTrue())
        await expect(didReceivePromotionalOfferSuccess).toEventually(beTrue())
        expect(receivedOfferId).to(equal("id"))
    }

    @MainActor
    func testActionWrapperDoesNotTriggerPromotionalOfferSucceededWhenTransactionIsNil() async {
        let mockPurchases = MockCustomerCenterPurchases()
        let actionWrapper = CustomerCenterActionWrapper()

        var capturedAction: PromotionalOfferViewAction?
        mockPurchases.purchaseResult = .success(
            (
                transaction: nil,
                customerInfo: CustomerInfoFixtures.customerInfoWithAppleSubscriptions,
                userCancelled: false
            )
        )

        let viewModel = makeViewModel(
            mockPurchases: mockPurchases,
            actionWrapper: actionWrapper,
            onComplete: { capturedAction = $0 }
        )

        var didReceivePromotionalOfferSucceeded = false
        actionWrapper.promotionalOfferSucceeded
            .sink { _, _, _ in
                didReceivePromotionalOfferSucceeded = true
            }
            .store(in: &cancellables)

        var didReceiveDeprecatedSuccess = false
        actionWrapper.promotionalOfferSuccess
            .sink { _ in
                didReceiveDeprecatedSuccess = true
            }
            .store(in: &cancellables)

        await viewModel.purchasePromo()

        expect(capturedAction!.isSuccess).to(beTrue())
        expect(didReceivePromotionalOfferSucceeded).to(beFalse())
        // The deprecated handler must still fire even when transaction is nil,
        // preserving backward compat for existing integrators.
        await expect(didReceiveDeprecatedSuccess).toEventually(beTrue())
    }

    @MainActor
    func testOnPromotionalOfferPurchaseFlowCompleteGetsCalledOnPurchaseError() async {
        let mockPurchases = MockCustomerCenterPurchases()
        let actionWrapper = CustomerCenterActionWrapper()

        var capturedAction: PromotionalOfferViewAction?
        mockPurchases.purchaseResult = .failure(NSError(domain: "", code: 0))

        let viewModel = makeViewModel(
            mockPurchases: mockPurchases,
            actionWrapper: actionWrapper,
            onComplete: { capturedAction = $0 }
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
